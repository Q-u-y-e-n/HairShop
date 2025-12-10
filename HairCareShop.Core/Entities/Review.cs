using System.ComponentModel.DataAnnotations.Schema;

namespace HairCareShop.Core.Entities
{
    public class Review
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public int ProductId { get; set; }
        public int OrderId { get; set; } // Liên kết để biết mua từ đơn nào
        public int Rating { get; set; } // 1 đến 5 sao
        public string Comment { get; set; } = string.Empty;
        public string? ImageUrl { get; set; } // Đường dẫn ảnh thực tế
        public DateTime CreatedAt { get; set; } = DateTime.Now;

        // Navigation properties
        [ForeignKey("UserId")]
        public User? User { get; set; }
        [ForeignKey("ProductId")]
        public Product? Product { get; set; }
        [ForeignKey("OrderId")]
        public Order? Order { get; set; }
    }
}