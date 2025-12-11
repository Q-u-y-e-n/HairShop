using HairCareShop.Core.Entities;
using HairCareShop.Core.Enums;
using HairCareShop.Data.EF;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace HairCareShop.Web.Controllers.Api
{
    [Route("api/[controller]")]
    [ApiController]
    public class OrderApiController : ControllerBase
    {
        private readonly HairCareShopDbContext _context;

        public OrderApiController(HairCareShopDbContext context)
        {
            _context = context;
        }

        // ==========================================
        // 1. TẠO ĐƠN HÀNG (Lưu cả SĐT khách nhập)
        // ==========================================
        // 1. TẠO ĐƠN HÀNG (Lưu SĐT khách điền)
        [HttpPost("create")]
        public async Task<IActionResult> CreateOrder([FromBody] CreateOrderRequest req)
        {
            if (req.Items == null || !req.Items.Any())
                return BadRequest(new { message = "Giỏ hàng trống" });

            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var order = new Order
                {
                    UserId = req.UserId,
                    OrderDate = DateTime.Now,
                    ShippingAddress = req.Address,

                    // --- QUAN TRỌNG: Lưu SĐT từ Form ---
                    Phone = req.Phone,
                    // ----------------------------------

                    PaymentMethod = req.PaymentMethod,
                    Status = OrderStatus.Pending,
                    TotalAmount = 0
                };

                _context.Orders.Add(order);
                await _context.SaveChangesAsync();

                decimal total = 0;
                foreach (var item in req.Items)
                {
                    var detail = new OrderDetail
                    {
                        OrderId = order.Id,
                        ProductId = item.ProductId,
                        Quantity = item.Quantity,
                        UnitPrice = item.Price
                    };
                    _context.OrderDetails.Add(detail);
                    total += (item.Quantity * item.Price);
                }

                order.TotalAmount = total;
                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                return Ok(new { success = true, orderId = order.Id });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return BadRequest(new { message = "Lỗi: " + ex.Message });
            }
        }

        // ==========================================
        // 2. LẤY LỊCH SỬ ĐƠN HÀNG
        // ==========================================
        [HttpGet("history/{userId}")]
        public async Task<IActionResult> GetHistory(int userId)
        {
            var orders = await _context.Orders
                .Where(o => o.UserId == userId)
                .OrderByDescending(o => o.OrderDate)
                .Select(o => new
                {
                    id = o.Id,
                    orderDate = o.OrderDate.ToString("dd/MM/yyyy HH:mm"),
                    totalAmount = o.TotalAmount,
                    status = o.Status.ToString(),
                    itemCount = o.OrderDetails.Sum(d => d.Quantity)
                }).ToListAsync();

            return Ok(orders);
        }

        // ==========================================
        // 3. CHI TIẾT ĐƠN HÀNG (Hiện đúng SĐT cho Shipper xem)
        // ==========================================
        // 2. CHI TIẾT ĐƠN HÀNG (Lấy SĐT chuẩn & Ảnh sản phẩm)
        [HttpGet("detail/{id}")]
        public async Task<IActionResult> GetOrderDetail(int id)
        {
            var order = await _context.Orders
                .Include(o => o.User)
                .Include(o => o.OrderDetails).ThenInclude(d => d.Product) // Include Product để lấy ảnh
                .FirstOrDefaultAsync(o => o.Id == id);

            if (order == null) return NotFound(new { message = "Không tìm thấy đơn" });

            // LOGIC SĐT: Ưu tiên lấy trong đơn hàng (khách điền form), nếu không có mới lấy User
            string displayPhone = !string.IsNullOrEmpty(order.Phone)
                                  ? order.Phone
                                  : (order.User?.PhoneNumber ?? "Không có SĐT");

            var result = new
            {
                id = order.Id,
                date = order.OrderDate.ToString("dd/MM/yyyy HH:mm"),
                status = order.Status.ToString(),
                total = order.TotalAmount,
                address = order.ShippingAddress,
                payment = order.PaymentMethod,
                customerName = order.User?.FullName ?? "Khách lẻ",

                phone = displayPhone, // <--- SĐT CHUẨN

                items = order.OrderDetails.Select(d => new
                {
                    productId = d.ProductId,
                    productName = d.Product?.Name ?? "Sản phẩm đã xóa",
                    quantity = d.Quantity,
                    price = d.UnitPrice,

                    // --- QUAN TRỌNG: Trả về ảnh sản phẩm ---
                    imageUrl = d.Product?.ImageUrl
                    // ---------------------------------------
                }).ToList()
            };

            return Ok(result);
        }

        // ==========================================
        // 4. DANH SÁCH CHO SHIPPER (Đã Fix Logic ẩn đơn)
        // ==========================================
        // 3. DANH SÁCH SHIPPER (Cũng phải hiện đúng SĐT)
        [HttpGet("list")]
        public async Task<IActionResult> GetOrdersByStatus(string status, int? shipperId)
        {
            if (!Enum.TryParse<OrderStatus>(status, true, out var statusEnum))
                return BadRequest("Trạng thái sai");

            var query = _context.Orders.Include(o => o.User).AsQueryable();

            if (statusEnum == OrderStatus.Confirmed)
            {
                query = query.Where(o => o.Status == statusEnum && (o.ShipperId == null || o.ShipperId == shipperId));
            }
            else
            {
                if (shipperId == null) return BadRequest("Thiếu Shipper ID");
                query = query.Where(o => o.Status == statusEnum && o.ShipperId == shipperId);
            }

            var orders = await query
                .OrderByDescending(o => o.OrderDate)
                .Select(o => new
                {
                    id = o.Id,
                    customerName = o.User.FullName ?? "Khách lẻ",

                    // Logic SĐT chuẩn
                    phone = !string.IsNullOrEmpty(o.Phone) ? o.Phone : (o.User.PhoneNumber ?? "Không có SĐT"),

                    address = o.ShippingAddress,
                    totalAmount = o.TotalAmount,
                    date = o.OrderDate.ToString("dd/MM/yyyy HH:mm"),
                    paymentMethod = o.PaymentMethod
                })
                .ToListAsync();

            return Ok(orders);
        }

        // ==========================================
        // 5. SHIPPER NHẬN ĐƠN & CẬP NHẬT TRẠNG THÁI
        // ==========================================
        [HttpPost("update-status")]
        public async Task<IActionResult> UpdateOrderStatus([FromBody] UpdateStatusRequest req)
        {
            var order = await _context.Orders.FindAsync(req.OrderId);
            if (order == null) return NotFound(new { message = "Không tìm thấy đơn" });
            if (!Enum.TryParse<OrderStatus>(req.NewStatus, true, out var statusEnum)) return BadRequest(new { message = "Trạng thái sai" });
            if (order.Status == OrderStatus.Confirmed && statusEnum == OrderStatus.Shipping)
            {
                if (order.ShipperId != null && order.ShipperId != req.ShipperId) return BadRequest(new { message = "Đơn này đã có người khác nhận!" });
                order.ShipperId = req.ShipperId;
            }
            order.Status = statusEnum;
            await _context.SaveChangesAsync();
            return Ok(new { success = true });
        }
        // 6. [SHIPPER] THỐNG KÊ HIỆU SUẤT GIAO HÀNG
        [HttpGet("shipper-stats")]
        public async Task<IActionResult> GetShipperStats(int shipperId)
        {
            // Lấy tất cả đơn hàng đã kết thúc của Shipper này
            var orders = await _context.Orders
                .Where(o => o.ShipperId == shipperId &&
                           (o.Status == OrderStatus.Completed || o.Status == OrderStatus.Cancelled))
                .Select(o => new { o.OrderDate, o.Status })
                .ToListAsync();

            // Group theo Tháng/Năm (Xử lý trên Ram để tránh lỗi SQL version cũ)
            var stats = orders
                .GroupBy(o => new { o.OrderDate.Month, o.OrderDate.Year })
                .Select(g => new
                {
                    month = $"{g.Key.Month}/{g.Key.Year}",
                    successCount = g.Count(x => x.Status == OrderStatus.Completed),
                    failedCount = g.Count(x => x.Status == OrderStatus.Cancelled)
                })
                .OrderByDescending(x => x.month) // Tháng mới nhất lên đầu
                .ToList();

            return Ok(stats);
        }
    }

    // --- CÁC CLASS DTO (Dữ liệu truyền lên) ---
    public class CreateOrderRequest
    {
        public int UserId { get; set; }
        public string Address { get; set; } = string.Empty;

        // Cần trường này để nhận SĐT từ App
        public string Phone { get; set; } = string.Empty;

        public string PaymentMethod { get; set; } = "COD";
        public List<CartItemDTO> Items { get; set; } = new();
    }

    public class CartItemDTO
    {
        public int ProductId { get; set; }
        public int Quantity { get; set; }
        public decimal Price { get; set; }
    }

    public class UpdateStatusRequest
    {
        public int OrderId { get; set; }
        public string NewStatus { get; set; } = string.Empty;
        public int ShipperId { get; set; }
    }
}