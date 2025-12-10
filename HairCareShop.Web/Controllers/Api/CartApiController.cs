using HairCareShop.Core.Entities;
using HairCareShop.Data.EF;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace HairCareShop.Web.Controllers.Api
{
    [Route("api/[controller]")]
    [ApiController]
    public class CartApiController : ControllerBase
    {
        private readonly HairCareShopDbContext _context;

        public CartApiController(HairCareShopDbContext context)
        {
            _context = context;
        }

        // 1. LẤY GIỎ HÀNG
        [HttpGet("{userId}")]
        public async Task<IActionResult> GetCart(int userId)
        {
            // Tìm giỏ hàng của User
            var cart = await _context.Carts
                .Include(c => c.Items).ThenInclude(i => i.Product)
                .FirstOrDefaultAsync(c => c.UserId == userId);

            if (cart == null)
            {
                return Ok(new List<object>()); // Trả về rỗng nếu chưa có giỏ
            }

            // Map dữ liệu trả về
            var result = cart.Items.Select(i => new
            {
                productId = i.ProductId,
                productName = i.Product?.Name ?? "Sản phẩm lỗi",
                price = i.Product?.Price ?? 0,
                quantity = i.Quantity,
                imageUrl = i.Product?.ImageUrl
            }).ToList();

            return Ok(result);
        }

        // 2. THÊM VÀO GIỎ (FIX LỖI KHÔNG LƯU)
        [HttpPost("add")]
        public async Task<IActionResult> AddToCart([FromBody] AddCartRequest req)
        {
            try
            {
                // A. Tìm Giỏ hàng (Cart) của User
                var cart = await _context.Carts.Include(c => c.Items).FirstOrDefaultAsync(c => c.UserId == req.UserId);

                // B. Nếu chưa có Cart -> Tạo mới ngay lập tức
                if (cart == null)
                {
                    cart = new Cart { UserId = req.UserId };
                    _context.Carts.Add(cart);
                    await _context.SaveChangesAsync(); // <--- QUAN TRỌNG: Lưu để có CartId
                }

                // C. Kiểm tra sản phẩm trong giỏ
                var item = cart.Items.FirstOrDefault(i => i.ProductId == req.ProductId);
                if (item != null)
                {
                    item.Quantity += req.Quantity; // Đã có -> Cộng thêm
                    _context.CartItems.Update(item);
                }
                else
                {
                    var newItem = new CartItem
                    {
                        CartId = cart.Id,
                        ProductId = req.ProductId,
                        Quantity = req.Quantity
                    };
                    _context.CartItems.Add(newItem); // Chưa có -> Thêm mới
                }

                // D. LƯU THAY ĐỔI
                await _context.SaveChangesAsync();

                return Ok(new { success = true, message = "Đã lưu thành công vào SQL" });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = "Lỗi Server: " + ex.Message });
            }
        }

        // 3. CÁC HÀM KHÁC (GIẢM / XÓA)
        [HttpPost("decrease")]
        public async Task<IActionResult> DecreaseItem([FromBody] AddCartRequest req)
        {
            var cart = await _context.Carts.Include(c => c.Items).FirstOrDefaultAsync(c => c.UserId == req.UserId);
            if (cart != null)
            {
                var item = cart.Items.FirstOrDefault(i => i.ProductId == req.ProductId);
                if (item != null)
                {
                    if (item.Quantity > 1) item.Quantity--;
                    else _context.CartItems.Remove(item);
                    await _context.SaveChangesAsync();
                }
            }
            return Ok(new { success = true });
        }

        [HttpDelete("remove")]
        public async Task<IActionResult> RemoveItem(int userId, int productId)
        {
            var cart = await _context.Carts.Include(c => c.Items).FirstOrDefaultAsync(c => c.UserId == userId);
            if (cart != null)
            {
                var item = cart.Items.FirstOrDefault(i => i.ProductId == productId);
                if (item != null)
                {
                    _context.CartItems.Remove(item);
                    await _context.SaveChangesAsync();
                }
            }
            return Ok(new { success = true });
        }
    }

    public class AddCartRequest
    {
        public int UserId { get; set; }
        public int ProductId { get; set; }
        public int Quantity { get; set; }
    }
}