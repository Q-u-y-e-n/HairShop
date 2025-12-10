using HairCareShop.Core.Entities;

namespace HairCareShop.Web.Models
{
    public class ShipperDetailViewModel
    {
        public User Shipper { get; set; } = new User();

        // Thống kê tổng quan
        public int TotalCompletedOrders { get; set; } // Tổng đơn đã giao trọn đời
        public int TotalActiveMonths { get; set; }    // Tổng số tháng có chạy đơn

        // Dữ liệu lọc
        public int? FilterMonth { get; set; }
        public int? FilterYear { get; set; }

        // Danh sách lịch sử hoạt động (Group theo tháng)
        public List<MonthlyShipperStat> MonthlyStats { get; set; } = new List<MonthlyShipperStat>();
    }

    public class MonthlyShipperStat
    {
        public int Month { get; set; }
        public int Year { get; set; }
        public int OrderCount { get; set; } // Số chuyến trong tháng
        public decimal TotalRevenueCollected { get; set; } // Tổng tiền thu hộ (COD)
    }
}