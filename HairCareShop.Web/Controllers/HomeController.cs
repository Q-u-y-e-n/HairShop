using HairCareShop.Core.Entities;
using HairCareShop.Data.EF;
using HairCareShop.Core.Enums;
using HairCareShop.Web.ViewModels; // Đảm bảo bạn đã tạo file ViewModel ở bước trước
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
            var today = DateTime.Today;
            var startOfMonth = new DateTime(today.Year, today.Month, 1);

            // ==========================================
            // 1. TÍNH CÁC CON SỐ TỔNG QUAN (CARDS)
            // ==========================================

            // Doanh thu hôm nay (Chỉ tính đơn đã hoàn thành)
            var dailyRevenue = await _context.Orders
                .Where(o => o.OrderDate.Date == today && o.Status == OrderStatus.Completed)
                .SumAsync(o => o.TotalAmount);

            // Doanh thu tháng này
            var monthlyRevenue = await _context.Orders
                .Where(o => o.OrderDate >= startOfMonth && o.Status == OrderStatus.Completed)
                .SumAsync(o => o.TotalAmount);

            // Số đơn hàng mới hôm nay (Tất cả trạng thái)
            var newOrders = await _context.Orders
                .CountAsync(o => o.OrderDate.Date == today);

            // Tổng số sản phẩm đang có
            var totalProducts = await _context.Products.CountAsync();


            // ==========================================
            // 2. DỮ LIỆU BIỂU ĐỒ DOANH THU (6 THÁNG GẦN NHẤT)
            // ==========================================
            var revenueData = new List<decimal>();
            var monthLabels = new List<string>();

            for (int i = 5; i >= 0; i--)
            {
                var date = today.AddMonths(-i);
                var start = new DateTime(date.Year, date.Month, 1);
                var end = start.AddMonths(1).AddSeconds(-1);

                var rev = await _context.Orders
                    .Where(o => o.OrderDate >= start && o.OrderDate <= end && o.Status == OrderStatus.Completed)
                    .SumAsync(o => o.TotalAmount);

                revenueData.Add(rev);
                monthLabels.Add($"T{date.Month}/{date.Year}");
            }


            // ==========================================
            // 3. DỮ LIỆU BIỂU ĐỒ TRÒN (TRẠNG THÁI ĐƠN)
            // ==========================================
            var statusCounts = await _context.Orders
                .GroupBy(o => o.Status)
                .Select(g => new { Status = g.Key, Count = g.Count() })
                .ToListAsync();


            // ==========================================
            // 4. TOP 5 SẢN PHẨM BÁN CHẠY NHẤT
            // ==========================================
            var topProducts = await _context.OrderDetails
                .Include(od => od.Product)
                .GroupBy(od => od.ProductId)
                .Select(g => new TopProductDto
                {
                    ProductName = g.First().Product.Name,
                    // Nếu ảnh null thì để trống, View sẽ xử lý ảnh mặc định
                    ImageUrl = g.First().Product.ImageUrl ?? "",
                    SoldQuantity = g.Sum(x => x.Quantity),
                    TotalRevenue = g.Sum(x => x.Quantity * x.UnitPrice)
                })
                .OrderByDescending(x => x.SoldQuantity)
                .Take(5)
                .ToListAsync();


            // ==========================================
            // 5. ĐÓNG GÓI DỮ LIỆU VÀO VIEWMODEL
            // ==========================================
            var model = new DashboardViewModel
            {
                DailyRevenue = dailyRevenue,
                MonthlyRevenue = monthlyRevenue,
                NewOrdersToday = newOrders,
                TotalProducts = totalProducts,

                RevenueLast12Months = revenueData,
                MonthLabels = monthLabels,

                // Lấy số lượng từng trạng thái (nếu không có thì trả về 0)
                PendingCount = statusCounts.FirstOrDefault(x => x.Status == OrderStatus.Pending)?.Count ?? 0,
                ShippingCount = statusCounts.FirstOrDefault(x => x.Status == OrderStatus.Shipping)?.Count ?? 0,
                CompletedCount = statusCounts.FirstOrDefault(x => x.Status == OrderStatus.Completed)?.Count ?? 0,
                CancelledCount = statusCounts.FirstOrDefault(x => x.Status == OrderStatus.Cancelled)?.Count ?? 0,

                TopSellingProducts = topProducts
            };

            // Trả về View cùng với Model dữ liệu
            return View(model);
        }
    }
}