namespace HairCareShop.Service.DTOs
{
    public class ProductDto
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public decimal Price { get; set; }
        public string PriceFormatted => $"{Price:N0} đ"; // Format sẵn tiền tệ
        public string? ImageUrl { get; set; }
        public string? CategoryName { get; set; }
        public string? Brand { get; set; }
    }
}