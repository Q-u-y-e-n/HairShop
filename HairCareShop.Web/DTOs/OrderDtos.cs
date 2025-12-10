namespace HairCareShop.Web.DTOs
{
    // Dữ liệu gửi lên khi Đặt hàng
    public class CreateOrderRequest
    {
        public int UserId { get; set; }
        public string FullName { get; set; } // Tên người nhận
        public string Phone { get; set; }    // SĐT người nhận
        public string Address { get; set; }  // Địa chỉ giao
        public string PaymentMethod { get; set; } = "COD"; // COD hoặc Banking
        public List<CartItemDto> Items { get; set; } = new List<CartItemDto>();
    }

    public class CartItemDto
    {
        public int ProductId { get; set; }
        public int Quantity { get; set; }
        public decimal Price { get; set; } // Giá tại thời điểm mua
    }

    // Dữ liệu gửi lên khi Đánh giá (Dùng Form vì có file ảnh)
    public class ReviewDto
    {
        public int UserId { get; set; }
        public int ProductId { get; set; }
        public int OrderId { get; set; }
        public int Rating { get; set; }
        public string Comment { get; set; } = string.Empty;
        public IFormFile? ImageFile { get; set; } // File ảnh từ Flutter
    }
}