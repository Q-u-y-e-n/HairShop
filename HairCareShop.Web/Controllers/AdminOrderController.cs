using HairCareShop.Data.EF;
using Microsoft.AspNetCore.Mvc;
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

        // 1. Danh sách đơn hàng
        public async Task<IActionResult> Index()
        {
            var orders = await _context.Orders
                .Include(o => o.User)     // Lấy thông tin người mua
                .Include(o => o.Shipper)  // Lấy thông tin shipper (nếu có)
                .OrderByDescending(o => o.OrderDate)
                .ToListAsync();
            return View(orders);
        }

        // 2. Xem chi tiết đơn hàng
        public async Task<IActionResult> Details(int id)
        {
            var order = await _context.Orders
                .Include(o => o.User)
                .Include(o => o.Shipper)
                .Include(o => o.OrderDetails)
                    .ThenInclude(od => od.Product) // Lấy thông tin sản phẩm trong chi tiết
                .FirstOrDefaultAsync(m => m.Id == id);

            if (order == null) return NotFound();

            // Lấy danh sách Shipper để hiển thị dropdown chọn shipper
            ViewBag.Shippers = await _context.Users
                .Where(u => u.Role == "Shipper")
                .ToListAsync();

            return View(order);
        }

        // 3. Cập nhật trạng thái / Gán Shipper
        [HttpPost]
        public async Task<IActionResult> UpdateStatus(int id, string status, int? shipperId)
        {
            var order = await _context.Orders.FindAsync(id);
            if (order != null)
            {
                order.Status = status;
                if (shipperId.HasValue)
                {
                    order.ShipperId = shipperId;
                }
                await _context.SaveChangesAsync();
            }
            return RedirectToAction(nameof(Details), new { id = id });
        }
    }
}