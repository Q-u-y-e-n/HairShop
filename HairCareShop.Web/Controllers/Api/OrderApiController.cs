using HairCareShop.Core.Entities;
using HairCareShop.Core.Enums;
using HairCareShop.Data.EF;
using HairCareShop.Web.DTOs;
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

        // 1. TẠO ĐƠN HÀNG (Checkout)
        [HttpPost("create")]
        public async Task<IActionResult> CreateOrder([FromBody] CreateOrderRequest req)
        {
            if (req.Items == null || !req.Items.Any())
                return BadRequest(new { message = "Giỏ hàng trống" });

            // Dùng Transaction để đảm bảo toàn vẹn dữ liệu
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                // Tạo đơn hàng chính
                var order = new Order
                {
                    UserId = req.UserId,
                    OrderDate = DateTime.Now,
                    ShippingAddress = req.Address,
                    PaymentMethod = req.PaymentMethod,
                    Status = OrderStatus.Pending, // Mặc định là Chờ xác nhận
                    TotalAmount = 0 // Sẽ tính lại bên dưới
                };

                _context.Orders.Add(order);
                await _context.SaveChangesAsync(); // Lưu để lấy được OrderId

                decimal total = 0;

                // Tạo chi tiết đơn hàng
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

                    // Cộng dồn tổng tiền
                    total += (item.Quantity * item.Price);
                }

                // Cập nhật lại tổng tiền cho đơn hàng
                order.TotalAmount = total;
                await _context.SaveChangesAsync();

                await transaction.CommitAsync();

                return Ok(new { success = true, message = "Đặt hàng thành công", orderId = order.Id });
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                return BadRequest(new { message = "Lỗi đặt hàng: " + ex.Message });
            }
        }

        // 2. LẤY LỊCH SỬ ĐƠN HÀNG (Của 1 user)
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
                    status = o.Status.ToString(), // Chuyển Enum thành chữ (Pending, Completed...)
                    itemCount = o.OrderDetails.Sum(d => d.Quantity)
                })
                .ToListAsync();

            return Ok(orders);
        }

        // 3. XEM CHI TIẾT ĐƠN HÀNG
        [HttpGet("detail/{id}")]
        public async Task<IActionResult> GetOrderDetail(int id)
        {
            var order = await _context.Orders
                .Include(o => o.User)
                .Include(o => o.OrderDetails).ThenInclude(d => d.Product)
                .FirstOrDefaultAsync(o => o.Id == id);

            if (order == null) return NotFound(new { message = "Không tìm thấy đơn hàng" });

            // Trả về JSON cấu trúc đầy đủ
            var result = new
            {
                id = order.Id,
                date = order.OrderDate.ToString("dd/MM/yyyy HH:mm"),
                status = order.Status.ToString(),
                total = order.TotalAmount,
                address = order.ShippingAddress, // Địa chỉ giao hàng lúc đặt
                payment = order.PaymentMethod,
                customerName = order.User?.FullName ?? "Khách lẻ",
                phone = order.User?.PhoneNumber ?? "",
                // Danh sách sản phẩm trong đơn
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
    }
}