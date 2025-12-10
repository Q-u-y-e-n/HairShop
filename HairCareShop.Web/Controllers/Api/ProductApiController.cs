using HairCareShop.Data.EF;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace HairCareShop.Web.Controllers.Api
{
    [Route("api/[controller]")]
    [ApiController]
    public class ProductApiController : ControllerBase
    {
        private readonly HairCareShopDbContext _context;

        public ProductApiController(HairCareShopDbContext context)
        {
            _context = context;
        }

        // GET: api/ProductApi
        [HttpGet]
        public async Task<IActionResult> GetProducts(string? search, int? categoryId)
        {
            var query = _context.Products.AsQueryable();

            if (!string.IsNullOrEmpty(search))
            {
                query = query.Where(p => p.Name.Contains(search) || p.Brand.Contains(search));
            }

            if (categoryId.HasValue && categoryId.Value > 0)
            {
                query = query.Where(p => p.CategoryId == categoryId);
            }

            var products = await query
                .Select(p => new
                {
                    id = p.Id,
                    name = p.Name,
                    price = p.Price,
                    imageUrl = p.ImageUrl,
                    brand = p.Brand,
                    categoryName = p.Category.Name
                })
                .ToListAsync();

            return Ok(products);
        }
    }
}