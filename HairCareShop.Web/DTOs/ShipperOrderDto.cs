namespace HairCareShop.Web.DTOs
{
    // Dữ liệu đơn hàng gửi xuống App cho Shipper xem
    public class ShipperOrderDto
    {
        public int Id { get; set; }
        public string CustomerName { get; set; } = string.Empty;
        public string Phone { get; set; } = string.Empty;
        public string Address { get; set; } = string.Empty;
        public string OrderDate { get; set; } = string.Empty;
        public decimal TotalAmount { get; set; }
        public string PaymentMethod { get; set; } = string.Empty;
        public int StatusId { get; set; }
        public string StatusName { get; set; } = string.Empty;

        // Danh sách món hàng (để shipper kiểm hàng)
        public List<string> Items { get; set; } = new List<string>();
    }

    // Dữ liệu App gửi lên để cập nhật trạng thái
    public class UpdateStatusRequest
    {
        public int OrderId { get; set; }
        public int NewStatus { get; set; } // 2: Shipping, 3: Completed, 4: Cancelled
        public int ShipperId { get; set; } // Để xác thực đúng shipper đó đang cập nhật
    }
}