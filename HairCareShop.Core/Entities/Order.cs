using System.ComponentModel.DataAnnotations.Schema;
using HairCareShop.Core.Enums; // Nhớ using namespace chứa Enum

namespace HairCareShop.Core.Entities
{
    public class Order
    {
        public int Id { get; set; }

        // 1. LIÊN KẾT KHÁCH HÀNG (Người đặt)
        public int UserId { get; set; }

        [ForeignKey("UserId")]
        public User? User { get; set; } // Khách hàng

        // 2. LIÊN KẾT SHIPPER (Người giao - Có thể Null lúc đầu)
        public int? ShipperId { get; set; }

        [ForeignKey("ShipperId")]
        public User? Shipper { get; set; } // Shipper

        // 3. THÔNG TIN ĐƠN HÀNG
        public DateTime OrderDate { get; set; } = DateTime.Now;

        [Column(TypeName = "decimal(18,2)")] // Định dạng tiền tệ chuẩn SQL
        public decimal TotalAmount { get; set; }

        // --- QUAN TRỌNG: DÙNG ENUM THAY VÌ STRING ---
        public OrderStatus Status { get; set; } = OrderStatus.Pending;

        public string ShippingAddress { get; set; } = string.Empty;
        public string PaymentMethod { get; set; } = "COD";

        // 4. CHI TIẾT SẢN PHẨM
        public ICollection<OrderDetail> OrderDetails { get; set; } = new List<OrderDetail>();
    }
}