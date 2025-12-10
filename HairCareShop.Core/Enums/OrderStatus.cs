namespace HairCareShop.Core.Enums
{
    public enum OrderStatus
    {
        Pending = 0,    // Chờ xác nhận (Khách mới đặt)
        Confirmed = 1,  // Đã xác nhận (Admin đã duyệt & có thể đã gán Shipper)
        Shipping = 2,   // Đang giao (Shipper đã lấy hàng đi giao)
        Completed = 3,  // Giao thành công
        Cancelled = 4   // Đã hủy
    }
}