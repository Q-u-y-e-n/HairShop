using HairCareShop.Core.Enums;
using HairCareShop.Data.EF;
using HairCareShop.Web.DTOs;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace HairCareShop.Web.Controllers.Api
{
    [Route("api/[controller]")]
    [ApiController]
    public class ShipperApiController : ControllerBase
    {
        private readonly HairCareShopDbContext _context;

        public ShipperApiController(HairCareShopDbContext context)
        {
            _context = context;
        }

        // 1. API: Lấy danh sách đơn hàng được giao cho Shipper này
        // GET: api/ShipperApi/my-orders?shipperId=5
        [HttpGet("my-orders")]
        public async Task<IActionResult> GetMyOrders(int shipperId)
        {
            var orders = await _context.Orders
                .Where(o => o.ShipperId == shipperId)
                .Include(o => o.User) // Lấy thông tin khách
                .Include(o => o.OrderDetails).ThenInclude(d => d.Product) // Lấy chi tiết hàng
                .OrderByDescending(o => o.OrderDate)
                .ToListAsync();

            // Chuyển đổi sang DTO để trả về JSON gọn nhẹ cho App
            var result = orders.Select(o => new ShipperOrderDto
            {
                Id = o.Id,
                CustomerName = o.User?.FullName ?? "Khách lẻ",
                Phone = o.User?.PhoneNumber ?? "Không có SĐT",
                Address = !string.IsNullOrEmpty(o.ShippingAddress) ? o.ShippingAddress : (o.User?.Address ?? "Chưa cập nhật"),
                OrderDate = o.OrderDate.ToString("dd/MM/yyyy HH:mm"),
                TotalAmount = o.TotalAmount,
                PaymentMethod = o.PaymentMethod,
                StatusId = (int)o.Status,
                StatusName = o.Status.ToString(),
                Items = o.OrderDetails.Select(d => $"{d.Product?.Name} (x{d.Quantity})").ToList()
            });

            return Ok(result);
        }

        // 2. API: Cập nhật trạng thái (Bắt đầu giao / Thành công / Thất bại)
        // POST: api/ShipperApi/update-status
        [HttpPost("update-status")]
        public async Task<IActionResult> UpdateStatus([FromBody] UpdateStatusRequest request)
        {
            var order = await _context.Orders.FindAsync(request.OrderId);

            if (order == null)
                return NotFound(new { message = "Không tìm thấy đơn hàng" });

            if (order.ShipperId != request.ShipperId)
                return BadRequest(new { message = "Đơn hàng này không thuộc quyền quản lý của bạn" });

            // Kiểm tra logic trạng thái
            if (order.Status == OrderStatus.Completed || order.Status == OrderStatus.Cancelled)
                return BadRequest(new { message = "Đơn hàng đã kết thúc, không thể cập nhật nữa." });

            // Cập nhật trạng thái
            order.Status = (OrderStatus)request.NewStatus;

            await _context.SaveChangesAsync();

            return Ok(new { success = true, message = "Cập nhật trạng thái thành công", newStatus = order.Status.ToString() });
        }

        // 3. API: Xem chi tiết một đơn hàng cụ thể (Nếu App cần màn hình chi tiết riêng)
        [HttpGet("detail/{orderId}")]
        public async Task<IActionResult> GetOrderDetail(int orderId)
        {
            var o = await _context.Orders
                .Include(o => o.User)
                .Include(o => o.OrderDetails).ThenInclude(d => d.Product)
                .FirstOrDefaultAsync(x => x.Id == orderId);

            if (o == null) return NotFound();

            var dto = new ShipperOrderDto
            {
                Id = o.Id,
                CustomerName = o.User?.FullName ?? "Khách lẻ",
                Phone = o.User?.PhoneNumber ?? "",
                Address = !string.IsNullOrEmpty(o.ShippingAddress) ? o.ShippingAddress : (o.User?.Address ?? ""),
                OrderDate = o.OrderDate.ToString("dd/MM/yyyy HH:mm"),
                TotalAmount = o.TotalAmount,
                PaymentMethod = o.PaymentMethod,
                StatusId = (int)o.Status,
                StatusName = o.Status.ToString(),
                Items = o.OrderDetails.Select(d => $"{d.Product?.Name} - {d.UnitPrice:N0}đ (x{d.Quantity})").ToList()
            };

            return Ok(dto);
        }
    }
}