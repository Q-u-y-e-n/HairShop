using System.ComponentModel.DataAnnotations.Schema;

namespace HairCareShop.Core.Entities
{
    public class Cart
    {
        public int Id { get; set; }
        public int UserId { get; set; }

        // Navigation
        [ForeignKey("UserId")]
        public User? User { get; set; }
        public ICollection<CartItem> Items { get; set; } = new List<CartItem>();
    }

    public class CartItem
    {
        public int Id { get; set; }
        public int CartId { get; set; }
        public int ProductId { get; set; }
        public int Quantity { get; set; }

        [ForeignKey("CartId")]
        public Cart? Cart { get; set; }
        [ForeignKey("ProductId")]
        public Product? Product { get; set; }
    }
}