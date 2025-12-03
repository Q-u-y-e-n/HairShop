namespace HairCareShop.Core.Entities
{
    public class ProductBatch
    {
        public int Id { get; set; }
        public int ProductId { get; set; }
        public string BatchCode { get; set; } = string.Empty;

        public DateTime ManufacturingDate { get; set; } // <--- MỚI THÊM
        public DateTime ExpiryDate { get; set; }

        public int Quantity { get; set; }
        public Product? Product { get; set; }
    }
}