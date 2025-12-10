using HairCareShop.Core.Entities;
using HairCareShop.Data.EF;
using HairCareShop.Web.DTOs;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;


namespace HairCareShop.Web.Controllers.Api
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthApiController : ControllerBase
    {
        private readonly HairCareShopDbContext _context;
        public AuthApiController(HairCareShopDbContext context) => _context = context;

        // 1. ĐĂNG NHẬP (Giữ nguyên)
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == request.Email && u.PasswordHash == request.Password);
            if (user == null) return Unauthorized(new { message = "Sai tài khoản hoặc mật khẩu" });
            if (user.IsLocked) return BadRequest(new { message = "Tài khoản bị khóa" });

            return Ok(new
            {
                id = user.Id,
                fullName = user.FullName,
                role = user.Role,
                phone = user.PhoneNumber,
                address = user.Address // Trả thêm thông tin để hiển thị
            });
        }

        // 2. ĐĂNG KÝ KHÁCH HÀNG (Mặc định Role = Customer)
        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterRequest request)
        {
            if (await _context.Users.AnyAsync(u => u.Email == request.Email))
                return BadRequest(new { message = "Email đã tồn tại" });

            var newUser = new User
            {
                FullName = request.FullName,
                Email = request.Email,
                PasswordHash = request.Password,
                Role = "Customer", // Mặc định
                CreatedAt = DateTime.Now
            };
            _context.Users.Add(newUser);
            await _context.SaveChangesAsync();
            return Ok(new { message = "Đăng ký thành công" });
        }

        // 3. NÂNG CẤP LÊN SHIPPER (Đổi Role)
        [HttpPost("become-shipper")]
        public async Task<IActionResult> BecomeShipper([FromBody] UpdateShipperRequest req)
        {
            var user = await _context.Users.FindAsync(req.UserId);
            if (user == null) return NotFound();

            // Cập nhật thông tin bổ sung và đổi Role
            user.PhoneNumber = req.Phone;
            user.Address = req.Address; // Khu vực hoạt động
            user.Role = "Shipper"; // <--- QUAN TRỌNG

            await _context.SaveChangesAsync();

            // Trả về user mới để App cập nhật lại
            return Ok(new
            {
                id = user.Id,
                fullName = user.FullName,
                role = user.Role,
                phone = user.PhoneNumber,
                address = user.Address
            });
        }
    }

    // DTO Mới
    public class UpdateShipperRequest
    {
        public int UserId { get; set; }
        public string Phone { get; set; }
        public string Address { get; set; }
    }
}