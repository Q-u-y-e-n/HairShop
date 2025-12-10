using HairCareShop.Core.Entities;
using HairCareShop.Data.EF;
using HairCareShop.Core.Enums; // <--- THÊM DÒNG NÀY
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace HairCareShop.Web.Controllers
{
    public class HomeController : Controller
    {
        private readonly HairCareShopDbContext _context;

        public HomeController(HairCareShopDbContext context)
        {
            _context = context;
        }

        public async Task<IActionResult> Index()
        {
            // --- SỬA LẠI ĐOẠN ĐẾM SỐ LƯỢNG NÀY ---
            ViewBag.NewOrders = await _context.Orders
                .CountAsync(o => o.Status == OrderStatus.Pending); // Thay "Pending" bằng OrderStatus.Pending

            ViewBag.ShippingOrders = await _context.Orders
                .CountAsync(o => o.Status == OrderStatus.Shipping); // Thay "Shipping" bằng OrderStatus.Shipping

            ViewBag.CompletedOrders = await _context.Orders
                .CountAsync(o => o.Status == OrderStatus.Completed);

            // Tính doanh thu (chỉ tính đơn hoàn thành)
            ViewBag.Revenue = await _context.Orders
                .Where(o => o.Status == OrderStatus.Completed)
                .SumAsync(o => o.TotalAmount);
            // --------------------------------------

            return View();
        }
    }
}