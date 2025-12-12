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
        // 1. TẠO ĐƠN HÀNG (CÓ TRỪ TỒN KHO)
        // ==========================================
        [HttpPost("create")]
        public async Task<IActionResult> CreateOrder([FromBody] CreateOrderRequest req)
        {
            if (req.Items == null || !req.Items.Any())
                return BadRequest(new { message = "Giỏ hàng trống" });

            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                // 1. Tạo đối tượng đơn hàng
                var order = new Order
                {
                    UserId = req.UserId,
                    OrderDate = DateTime.Now,
                    ShippingAddress = req.Address,
                    Phone = req.Phone,
                    PaymentMethod = req.PaymentMethod,
                    Status = OrderStatus.Pending,
                    TotalAmount = 0
                };

                _context.Orders.Add(order);
                await _context.SaveChangesAsync(); // Lưu để lấy ID đơn hàng

                decimal total = 0;

                // 2. Duyệt qua từng sản phẩm trong giỏ
                foreach (var item in req.Items)
                {
                    // --- LOGIC TRỪ KHO (MỚI) ---
                    var product = await _context.Products.FindAsync(item.ProductId);

                    if (product == null)
                        throw new Exception($"Sản phẩm ID {item.ProductId} không tồn tại");

                    // Kiểm tra đủ hàng không
                    if (product.StockQuantity < item.Quantity)
                        throw new Exception($"Sản phẩm '{product.Name}' không đủ hàng (Còn: {product.StockQuantity})");

                    // Trừ tồn kho
                    product.StockQuantity -= item.Quantity;
                    // ----------------------------------

                    // Tạo chi tiết đơn hàng
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
                await _context.SaveChangesAsync(); // Lưu cập nhật (Đơn hàng + Sản phẩm đã trừ kho)

                await transaction.CommitAsync();   // Xác nhận giao dịch thành công

                return Ok(new { success = true, message = "Thành công", orderId = order.Id });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync(); // Hoàn tác nếu có lỗi
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
        // 3. CHI TIẾT ĐƠN HÀNG
        // ==========================================
        [HttpGet("detail/{id}")]
        public async Task<IActionResult> GetOrderDetail(int id)
        {
            var order = await _context.Orders
                .Include(o => o.User)
                .Include(o => o.OrderDetails).ThenInclude(d => d.Product)
                .FirstOrDefaultAsync(o => o.Id == id);

            if (order == null) return NotFound(new { message = "Không tìm thấy đơn" });

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
                phone = displayPhone,
                items = order.OrderDetails.Select(d => new
                {
                    productId = d.ProductId,
                    productName = d.Product?.Name ?? "Sản phẩm đã xóa",
                    quantity = d.Quantity,
                    price = d.UnitPrice,
                    imageUrl = d.Product?.ImageUrl
                }).ToList()
            };

            return Ok(result);
        }

        // ==========================================
        // 4. DANH SÁCH CHO SHIPPER
        // ==========================================
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
        // 5. CẬP NHẬT TRẠNG THÁI (TRẢ KHO NẾU HỦY)
        // ==========================================
        [HttpPost("update-status")]
        public async Task<IActionResult> UpdateOrderStatus([FromBody] UpdateStatusRequest req)
        {
            // Phải Include OrderDetails để biết đơn đó mua gì mà trả lại kho
            var order = await _context.Orders
                .Include(o => o.OrderDetails)
                .FirstOrDefaultAsync(o => o.Id == req.OrderId);

            if (order == null) return NotFound(new { message = "Không tìm thấy đơn" });

            if (!Enum.TryParse<OrderStatus>(req.NewStatus, true, out var statusEnum))
                return BadRequest(new { message = "Trạng thái sai" });

            // Logic nhận đơn của Shipper
            if (order.Status == OrderStatus.Confirmed && statusEnum == OrderStatus.Shipping)
            {
                if (order.ShipperId != null && order.ShipperId != req.ShipperId)
                    return BadRequest(new { message = "Đơn này đã có người khác nhận!" });
                order.ShipperId = req.ShipperId;
            }

            // --- LOGIC HOÀN KHO KHI HỦY ĐƠN (MỚI) ---
            // Nếu chuyển sang trạng thái "Cancelled" (Hủy) VÀ trạng thái cũ chưa phải là Hủy
            if (statusEnum == OrderStatus.Cancelled && order.Status != OrderStatus.Cancelled)
            {
                foreach (var detail in order.OrderDetails)
                {
                    var product = await _context.Products.FindAsync(detail.ProductId);
                    if (product != null)
                    {
                        // Cộng lại số lượng vào kho
                        product.StockQuantity += detail.Quantity;
                    }
                }
            }
            // ----------------------------------------------

            order.Status = statusEnum;
            await _context.SaveChangesAsync();
            return Ok(new { success = true });
        }

        // ==========================================
        // 6. THỐNG KÊ HIỆU SUẤT SHIPPER
        // ==========================================
        [HttpGet("shipper-stats")]
        public async Task<IActionResult> GetShipperStats(int shipperId)
        {
            var orders = await _context.Orders
                .Where(o => o.ShipperId == shipperId &&
                           (o.Status == OrderStatus.Completed || o.Status == OrderStatus.Cancelled))
                .Select(o => new { o.OrderDate, o.Status })
                .ToListAsync();

            var stats = orders
                .GroupBy(o => new { o.OrderDate.Month, o.OrderDate.Year })
                .Select(g => new
                {
                    month = $"{g.Key.Month}/{g.Key.Year}",
                    successCount = g.Count(x => x.Status == OrderStatus.Completed),
                    failedCount = g.Count(x => x.Status == OrderStatus.Cancelled)
                })
                .OrderByDescending(x => x.month)
                .ToList();

            return Ok(stats);
        }
    }

    // --- DTO CLASSES ---
    public class CreateOrderRequest
    {
        public int UserId { get; set; }
        public string Address { get; set; } = string.Empty;
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