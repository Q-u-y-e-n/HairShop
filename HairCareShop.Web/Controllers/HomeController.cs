using HairCareShop.Data.EF;
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
            // Lấy số liệu thống kê đơn giản
            ViewBag.TotalOrders = await _context.Orders.CountAsync();
            ViewBag.TotalProducts = await _context.Products.CountAsync();
            ViewBag.TotalUsers = await _context.Users.CountAsync(u => u.Role == "Customer");
            ViewBag.PendingOrders = await _context.Orders.CountAsync(o => o.Status == "Pending");

            return View();
        }
    }
}