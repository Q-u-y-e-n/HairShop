using System.ComponentModel.DataAnnotations.Schema;

namespace HairCareShop.Core.Entities
{
    public class Product
    {
        public int Id { get; set; }
        public int CategoryId { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal Price { get; set; }

        public int StockQuantity { get; set; }
        public string? ImageUrl { get; set; }
        public string? Brand { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.Now;

        // --- CÁC TRƯỜNG MỚI BẮT BUỘC ---
        public int UnitsPerBox { get; set; } = 1;
        public string UnitName { get; set; } = "Chai";

        public Category? Category { get; set; }
        // Sửa lỗi ProductBatches
        public ICollection<ProductBatch> ProductBatches { get; set; } = new List<ProductBatch>();
    }
}