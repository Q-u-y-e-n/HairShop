using System.ComponentModel.DataAnnotations.Schema;

namespace HairCareShop.Core.Entities
{
    [Table("Categories")]
    public class Category
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }

        // Quan hệ 1-Nhiều với Product
        public ICollection<Product> Products { get; set; } = new List<Product>();
    }
}