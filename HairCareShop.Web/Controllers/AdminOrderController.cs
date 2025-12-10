using HairCareShop.Core.Entities;
using HairCareShop.Core.Enums; // Nhớ using Enum
using HairCareShop.Data.EF;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;

namespace HairCareShop.Web.Controllers
{
    public class AdminOrderController : Controller
    {
        private readonly HairCareShopDbContext _context;

        public AdminOrderController(HairCareShopDbContext context)
        {
            _context = context;
        }

        // 1. DANH SÁCH ĐƠN HÀNG
        public async Task<IActionResult> Index(int? status)
        {
            var query = _context.Orders
                .Include(o => o.User)    // Khách hàng
                .Include(o => o.Shipper) // Shipper được gán
                .OrderByDescending(o => o.OrderDate)
                .AsQueryable();

            // Lọc theo trạng thái nếu có
            if (status.HasValue)
            {
                query = query.Where(o => (int)o.Status == status.Value);
            }

            // Lấy danh sách Shipper để hiển thị trong Modal phân công
            ViewBag.Shippers = await _context.Users
                .Where(u => u.Role == "Shipper" && !u.IsLocked)
                .ToListAsync();

            return View(await query.ToListAsync());
        }

        // 2. CHI TIẾT ĐƠN HÀNG
        public async Task<IActionResult> Details(int id)
        {
            var order = await _context.Orders
                .Include(o => o.User)
                .Include(o => o.Shipper)
                .Include(o => o.OrderDetails).ThenInclude(d => d.Product)
                .FirstOrDefaultAsync(m => m.Id == id);

            if (order == null) return NotFound();

            return View(order);
        }

        // 3. XÁC NHẬN ĐƠN HÀNG (Pending -> Confirmed)
        [HttpPost]
        public async Task<IActionResult> ConfirmOrder(int id)
        {
            var order = await _context.Orders.FindAsync(id);
            if (order != null && order.Status == OrderStatus.Pending)
            {
                order.Status = OrderStatus.Confirmed; // Chuyển sang đã xác nhận
                await _context.SaveChangesAsync();
                return Json(new { success = true, message = "Đã xác nhận đơn hàng." });
            }
            return Json(new { success = false, message = "Không thể xác nhận đơn này." });
        }

        // 4. PHÂN CÔNG SHIPPER (Chỉ gán người, trạng thái vẫn là Confirmed)
        [HttpPost]
        public async Task<IActionResult> AssignShipper(int orderId, int shipperId)
        {
            var order = await _context.Orders.FindAsync(orderId);
            if (order == null) return Json(new { success = false, message = "Đơn hàng không tồn tại." });

            // Chỉ được phân công khi đơn đã xác nhận hoặc đang chờ
            if (order.Status == OrderStatus.Pending || order.Status == OrderStatus.Confirmed)
            {
                order.ShipperId = shipperId;
                order.Status = OrderStatus.Confirmed; // Đảm bảo đơn đã được xác nhận để Shipper thấy
                await _context.SaveChangesAsync();

                var shipper = await _context.Users.FindAsync(shipperId);
                return Json(new { success = true, shipperName = shipper?.FullName });
            }

            return Json(new { success = false, message = "Trạng thái đơn hàng không cho phép phân công." });
        }
    }
}