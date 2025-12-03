using HairCareShop.Core.Entities;

namespace HairCareShop.Core.Interfaces
{
    public interface IProductRepository
    {
        Task<IEnumerable<Product>> GetAllProductsAsync();
        Task<Product?> GetProductByIdAsync(int id);
        Task AddAsync(Product product); // Thêm dòng này
        Task SaveChangesAsync(); // Thêm dòng này để lưu xuống DB
    }
}