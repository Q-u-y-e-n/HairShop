namespace HairCareShop.Web.ViewModels
{
    public class DashboardViewModel
    {
        // --- THÔNG TIN BỘ LỌC ---
        public int SelectedMonth { get; set; }
        public int SelectedYear { get; set; }

        // --- CÁC CON SỐ TỔNG QUAN (CỦA THÁNG ĐANG CHỌN) ---
        public decimal MonthlyRevenue { get; set; }  // Tổng thu tháng này
        public int TotalOrders { get; set; }         // Tổng đơn tháng này
        public int SuccessfulOrders { get; set; }    // Đơn thành công tháng này
        public int CancelledOrders { get; set; }     // Đơn hủy tháng này

        // --- DỮ LIỆU BIỂU ĐỒ (THEO NGÀY TRONG THÁNG) ---
        // Labels sẽ là: "01/12", "02/12", "03/12"...
        public List<string> ChartLabels { get; set; } = new List<string>();
        public List<decimal> ChartData { get; set; } = new List<decimal>();

        // --- BIỂU ĐỒ TRÒN (TỶ LỆ TRẠNG THÁI) ---
        public int PendingCount { get; set; }
        public int ShippingCount { get; set; }
        public int CompletedCount { get; set; }
        public int CancelledCount { get; set; }

        // --- TOP SẢN PHẨM ---
        public List<TopProductDto> TopSellingProducts { get; set; } = new List<TopProductDto>();
    }

    public class TopProductDto
    {
        public string ProductName { get; set; } = string.Empty;
        public int SoldQuantity { get; set; }
        public decimal TotalRevenue { get; set; }
        public string ImageUrl { get; set; } = string.Empty;
    }
}