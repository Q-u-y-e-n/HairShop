using HairCareShop.Core.Interfaces;
using HairCareShop.Service.DTOs;
using HairCareShop.Service.Interfaces;

namespace HairCareShop.Service.Services
{
    public class ProductService : IProductService
    {
        private readonly IProductRepository _repo;

        public ProductService(IProductRepository repo)
        {
            _repo = repo;
        }

        public async Task<IEnumerable<ProductDto>> GetProductsForAppAsync()
        {
            var products = await _repo.GetAllProductsAsync();

            // Chuyển đổi thủ công từ Entity -> DTO (Sau này có thể dùng AutoMapper)
            return products.Select(p => new ProductDto
            {
                Id = p.Id,
                Name = p.Name,
                Price = p.Price,
                ImageUrl = p.ImageUrl,
                Brand = p.Brand,
                CategoryName = p.Category?.Name ?? "Unknown"
            }).ToList();
        }

    }
}