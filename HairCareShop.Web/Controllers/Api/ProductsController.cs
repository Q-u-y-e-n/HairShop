using HairCareShop.Service.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace HairCareShop.Web.Controllers.Api
{
    [Route("api/[controller]")] // Đường dẫn sẽ là: domain/api/products
    [ApiController]
    public class ProductsController : ControllerBase
    {
        private readonly IProductService _productService;

        public ProductsController(IProductService productService)
        {
            _productService = productService;
        }

        // GET: api/products
        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            try
            {
                var data = await _productService.GetProductsForAppAsync();
                return Ok(data); // Trả về JSON 200 OK
            }
            catch (Exception ex)
            {
                return StatusCode(500, ex.Message);
            }
        }
    }
}