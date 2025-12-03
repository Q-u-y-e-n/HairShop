using HairCareShop.Core.Entities;
using HairCareShop.Core.Interfaces;
using HairCareShop.Data.EF;
using Microsoft.EntityFrameworkCore;

namespace HairCareShop.Data.Repositories
{
    public class ProductRepository : IProductRepository
    {
        private readonly HairCareShopDbContext _context;

        public ProductRepository(HairCareShopDbContext context)
        {
            _context = context;
        }

        public async Task<IEnumerable<Product>> GetAllProductsAsync()
        {
            // Include để lấy luôn tên Category đi kèm sản phẩm
            return await _context.Products
                                 .Include(p => p.Category)
                                 .ToListAsync();
        }

        public async Task<Product?> GetProductByIdAsync(int id)
        {
            return await _context.Products
                                 .Include(p => p.Category)
                                 .FirstOrDefaultAsync(p => p.Id == id);
        }
        public async Task AddAsync(Product product)
        {
            await _context.Products.AddAsync(product);
        }

        public async Task SaveChangesAsync()
        {
            await _context.SaveChangesAsync();
        }
    }
}