namespace HairCareShop.Web.ViewModels
{
    public class DashboardViewModel
    {
        // 1. Các con số tổng quan (Card)
        public decimal DailyRevenue { get; set; }    // Doanh thu hôm nay
        public decimal MonthlyRevenue { get; set; }  // Doanh thu tháng này
        public int NewOrdersToday { get; set; }      // Đơn mới hôm nay
        public int TotalProducts { get; set; }       // Tổng sản phẩm đang bán

        // 2. Dữ liệu cho Biểu đồ Doanh thu (12 tháng)
        public List<decimal> RevenueLast12Months { get; set; } = new List<decimal>();
        public List<string> MonthLabels { get; set; } = new List<string>();

        // 3. Dữ liệu cho Biểu đồ Trạng thái đơn hàng (Pie Chart)
        public int PendingCount { get; set; }   // Chờ xác nhận
        public int ShippingCount { get; set; }  // Đang giao
        public int CompletedCount { get; set; } // Thành công
        public int CancelledCount { get; set; } // Đã hủy

        // 4. Top sản phẩm bán chạy
        public List<TopProductDto> TopSellingProducts { get; set; } = new List<TopProductDto>();
    }

    public class TopProductDto
    {
        public string ProductName { get; set; } = string.Empty;
        public int SoldQuantity { get; set; }
        public decimal TotalRevenue { get; set; }
        public string ImageUrl { get; set; }
    }
}