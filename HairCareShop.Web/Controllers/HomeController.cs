using HairCareShop.Core.Entities;
using HairCareShop.Data.EF;
using HairCareShop.Core.Enums;
using HairCareShop.Web.ViewModels; // Đảm bảo đã có file DashboardViewModel.cs trong thư mục ViewModels
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Globalization;

namespace HairCareShop.Web.Controllers
{
    public class HomeController : Controller
    {
        private readonly HairCareShopDbContext _context;

        public HomeController(HairCareShopDbContext context)
        {
            _context = context;
        }

        // Action duy nhất cho Dashboard (nhận tham số lọc tháng/năm)
        public async Task<IActionResult> Index(int? month, int? year)
        {
            // 1. Xác định thời gian lọc (Mặc định là tháng hiện tại nếu không chọn)
            int filterMonth = month ?? DateTime.Now.Month;
            int filterYear = year ?? DateTime.Now.Year;

            var startDate = new DateTime(filterYear, filterMonth, 1);
            var endDate = startDate.AddMonths(1).AddSeconds(-1); // Thời điểm cuối cùng của tháng

            // 2. Lấy danh sách đơn hàng trong khoảng thời gian này
            // (Chỉ lấy những cột cần thiết để tối ưu, hoặc lấy hết nếu cần)
            var monthOrders = await _context.Orders
                .Where(o => o.OrderDate >= startDate && o.OrderDate <= endDate)
                .ToListAsync();

            // ==========================================
            // 3. TÍNH TOÁN CÁC CON SỐ TỔNG QUAN (CARDS)
            // ==========================================

            // Tổng doanh thu (Chỉ tính đơn đã hoàn thành)
            var monthlyRevenue = monthOrders
                .Where(o => o.Status == OrderStatus.Completed)
                .Sum(o => o.TotalAmount);

            var totalOrders = monthOrders.Count;
            var successfulOrders = monthOrders.Count(o => o.Status == OrderStatus.Completed);
            var cancelledOrders = monthOrders.Count(o => o.Status == OrderStatus.Cancelled);

            // ==========================================
            // 4. DỮ LIỆU BIỂU ĐỒ (DOANH THU TỪNG NGÀY)
            // ==========================================
            var chartLabels = new List<string>();
            var chartData = new List<decimal>();

            int daysInMonth = DateTime.DaysInMonth(filterYear, filterMonth);

            // Chạy vòng lặp từ ngày 1 đến hết tháng
            for (int day = 1; day <= daysInMonth; day++)
            {
                var currentDay = new DateTime(filterYear, filterMonth, day);

                // Tính tổng tiền của ngày hôm đó (đơn Completed)
                var dailyRev = monthOrders
                    .Where(o => o.OrderDate.Date == currentDay.Date && o.Status == OrderStatus.Completed)
                    .Sum(o => o.TotalAmount);

                chartLabels.Add($"{day:00}/{filterMonth:00}"); // Label: 01/12
                chartData.Add(dailyRev);
            }

            // ==========================================
            // 5. BIỂU ĐỒ TRÒN (TỶ LỆ TRẠNG THÁI)
            // ==========================================
            var pendingCount = monthOrders.Count(o => o.Status == OrderStatus.Pending);
            var shippingCount = monthOrders.Count(o => o.Status == OrderStatus.Shipping);
            var completedCount = monthOrders.Count(o => o.Status == OrderStatus.Completed);
            var cancelledCount = monthOrders.Count(o => o.Status == OrderStatus.Cancelled);

            // ==========================================
            // 6. TOP 5 SẢN PHẨM BÁN CHẠY (TRONG THÁNG ĐÓ)
            // ==========================================
            // Cần query riêng vào bảng OrderDetail vì list monthOrders ở trên chưa include chi tiết
            var topProducts = await _context.OrderDetails
                .Include(od => od.Product)
                .Include(od => od.Order)
                .Where(od => od.Order.OrderDate >= startDate && od.Order.OrderDate <= endDate
                             && od.Order.Status == OrderStatus.Completed) // Chỉ tính đơn thành công
                .GroupBy(od => od.ProductId)
                .Select(g => new TopProductDto
                {
                    ProductName = g.First().Product.Name,
                    ImageUrl = g.First().Product.ImageUrl ?? "",
                    SoldQuantity = g.Sum(x => x.Quantity),
                    TotalRevenue = g.Sum(x => x.Quantity * x.UnitPrice)
                })
                .OrderByDescending(x => x.SoldQuantity)
                .Take(5)
                .ToListAsync();

            // ==========================================
            // 7. ĐÓNG GÓI VÀO VIEWMODEL
            // ==========================================
            var model = new DashboardViewModel
            {
                // Thông tin bộ lọc để hiển thị lại trên View
                SelectedMonth = filterMonth,
                SelectedYear = filterYear,

                // Số liệu tổng quan
                MonthlyRevenue = monthlyRevenue,
                TotalOrders = totalOrders,
                SuccessfulOrders = successfulOrders,
                CancelledOrders = cancelledOrders,

                // Dữ liệu biểu đồ
                ChartLabels = chartLabels,
                ChartData = chartData,

                // Dữ liệu trạng thái
                PendingCount = pendingCount,
                ShippingCount = shippingCount,
                CompletedCount = completedCount,
                CancelledCount = cancelledCount,

                // Top sản phẩm
                TopSellingProducts = topProducts
            };

            return View(model);
        }
    }
}