using HairCareShop.Service.DTOs;

namespace HairCareShop.Service.Interfaces
{
    public interface IProductService
    {
        Task<IEnumerable<ProductDto>> GetProductsForAppAsync();
    }
}