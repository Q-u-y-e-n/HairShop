using HairCareShop.Core.Entities;
using HairCareShop.Data.EF;
using HairCareShop.Web.DTOs;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace HairCareShop.Web.Controllers.Api
{
    [Route("api/[controller]")]
    [ApiController]
    public class ReviewApiController : ControllerBase
    {
        private readonly HairCareShopDbContext _context;
        private readonly IWebHostEnvironment _env; // Để lấy đường dẫn lưu ảnh

        public ReviewApiController(HairCareShopDbContext context, IWebHostEnvironment env)
        {
            _context = context;
            _env = env;
        }

        // POST: api/ReviewApi/add
        [HttpPost("add")]
        public async Task<IActionResult> AddReview([FromForm] ReviewDto model)
        {
            // 1. Kiểm tra xem User này có mua đơn hàng này không (Bảo mật)
            var orderExists = await _context.Orders.AnyAsync(o => o.Id == model.OrderId && o.UserId == model.UserId);
            if (!orderExists)
                return BadRequest(new { message = "Đơn hàng không hợp lệ." });

            // 2. Xử lý lưu ảnh (Nếu có)
            string imagePath = null;
            if (model.ImageFile != null && model.ImageFile.Length > 0)
            {
                // Tạo tên file ngẫu nhiên để tránh trùng
                string fileName = Guid.NewGuid().ToString() + Path.GetExtension(model.ImageFile.FileName);

                // Đường dẫn thư mục: wwwroot/reviews
                string folderPath = Path.Combine(_env.WebRootPath, "reviews");
                if (!Directory.Exists(folderPath)) Directory.CreateDirectory(folderPath);

                // Lưu file vật lý
                string filePath = Path.Combine(folderPath, fileName);
                using (var stream = new FileStream(filePath, FileMode.Create))
                {
                    await model.ImageFile.CopyToAsync(stream);
                }

                // Đường dẫn lưu vào DB (dùng để hiển thị web/app)
                imagePath = "/reviews/" + fileName;
            }

            // 3. Lưu đánh giá vào Database
            var review = new Review
            {
                UserId = model.UserId,
                ProductId = model.ProductId,
                OrderId = model.OrderId,
                Rating = model.Rating,
                Comment = model.Comment,
                ImageUrl = imagePath, // Lưu đường dẫn ảnh
                CreatedAt = DateTime.Now
            };

            _context.Reviews.Add(review);
            await _context.SaveChangesAsync();

            return Ok(new { success = true, message = "Đánh giá thành công!" });
        }

        // (Tùy chọn) Lấy danh sách đánh giá của 1 sản phẩm
        [HttpGet("product/{productId}")]
        public async Task<IActionResult> GetProductReviews(int productId)
        {
            var reviews = await _context.Reviews
                .Where(r => r.ProductId == productId)
                .Include(r => r.User)
                .OrderByDescending(r => r.CreatedAt)
                .Select(r => new
                {
                    userName = r.User.FullName,
                    avatar = r.User.AvatarUrl,
                    rating = r.Rating,
                    comment = r.Comment,
                    image = r.ImageUrl,
                    date = r.CreatedAt.ToString("dd/MM/yyyy")
                })
                .ToListAsync();

            return Ok(reviews);
        }
    }
}