using HairCareShop.Core.Entities;
using HairCareShop.Data.EF;
using HairCareShop.Web.DTOs; // Nếu bạn dùng DTO ở file riêng thì giữ, không thì xóa dòng này
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace HairCareShop.Web.Controllers.Api
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthApiController : ControllerBase
    {
        private readonly HairCareShopDbContext _context;

        public AuthApiController(HairCareShopDbContext context)
        {
            _context = context;
        }

        // ==========================================
        // 1. ĐĂNG NHẬP
        // ==========================================
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            // Tìm user theo Email và Password (MD5/Hash nếu có)
            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.Email == request.Email && u.PasswordHash == request.Password);

            if (user == null) return Unauthorized(new { message = "Sai tài khoản hoặc mật khẩu" });
            if (user.IsLocked) return BadRequest(new { message = "Tài khoản đã bị khóa" });

            // Trả về đầy đủ thông tin để App lưu vào bộ nhớ
            return Ok(new
            {
                id = user.Id,
                email = user.Email,
                fullName = user.FullName,
                role = user.Role,
                phone = user.PhoneNumber,
                address = user.Address,
                avatarUrl = user.AvatarUrl
            });
        }

        // ==========================================
        // 2. ĐĂNG KÝ (KHÁCH HÀNG)
        // ==========================================
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
                PhoneNumber = request.Phone,
                Address = request.Address,
                Role = "Customer", // Mặc định là khách hàng
                CreatedAt = DateTime.Now,
                IsLocked = false
            };

            _context.Users.Add(newUser);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Đăng ký thành công" });
        }

        // ==========================================
        // 3. CẬP NHẬT THÔNG TIN (DÙNG CHUNG CHO CẢ SHIPPER & CUSTOMER)
        // ==========================================
        [HttpPost("update-profile")]
        public async Task<IActionResult> UpdateProfile([FromBody] UpdateProfileRequest req)
        {
            var user = await _context.Users.FindAsync(req.UserId);
            if (user == null) return NotFound(new { message = "Không tìm thấy người dùng" });

            // Cập nhật các trường thông tin
            // Lưu ý: Nếu Shipper sửa "Khu vực hoạt động", nó sẽ lưu vào Address
            user.FullName = req.FullName;
            user.PhoneNumber = req.Phone;
            user.Address = req.Address;

            await _context.SaveChangesAsync();

            // Trả về success để App biết mà cập nhật lại State
            return Ok(new { success = true, message = "Cập nhật thành công" });
        }

        // ==========================================
        // 4. ĐĂNG KÝ LÀM SHIPPER (NÂNG CẤP TÀI KHOẢN)
        // ==========================================
        [HttpPost("become-shipper")]
        public async Task<IActionResult> BecomeShipper([FromBody] UpdateShipperRequest req)
        {
            var user = await _context.Users.FindAsync(req.UserId);
            if (user == null) return NotFound(new { message = "User not found" });

            // Cập nhật thông tin bổ sung
            user.PhoneNumber = req.Phone;
            user.Address = req.Address; // Khu vực hoạt động của Shipper
            user.Role = "Shipper";      // Đổi quyền thành Shipper

            await _context.SaveChangesAsync();

            // Trả về User mới để App cập nhật lại giao diện ngay lập tức
            return Ok(new
            {
                id = user.Id,
                email = user.Email,
                fullName = user.FullName,
                role = user.Role,
                phone = user.PhoneNumber,
                address = user.Address,
                avatarUrl = user.AvatarUrl
            });
        }

        // ==========================================
        // 5. UPLOAD ẢNH ĐẠI DIỆN
        // ==========================================
        [HttpPost("upload-avatar")]
        public async Task<IActionResult> UploadAvatar(int userId, IFormFile file)
        {
            if (file == null || file.Length == 0)
                return BadRequest("Vui lòng chọn ảnh");

            var user = await _context.Users.FindAsync(userId);
            if (user == null) return NotFound("User không tồn tại");

            try
            {
                // 1. Tạo tên file duy nhất
                var fileName = $"{Guid.NewGuid()}_{file.FileName}";

                // 2. Đường dẫn lưu trữ (wwwroot/uploads/avatars)
                var folderPath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "uploads", "avatars");
                if (!Directory.Exists(folderPath)) Directory.CreateDirectory(folderPath);

                var filePath = Path.Combine(folderPath, fileName);

                // 3. Lưu file
                using (var stream = new FileStream(filePath, FileMode.Create))
                {
                    await file.CopyToAsync(stream);
                }

                // 4. Lưu đường dẫn vào DB
                var relativePath = $"/uploads/avatars/{fileName}";
                user.AvatarUrl = relativePath;

                await _context.SaveChangesAsync();

                return Ok(new { success = true, avatarUrl = relativePath });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = "Lỗi upload: " + ex.Message });
            }
        }
    }

    // ==========================================
    // CÁC CLASS DTO (DATA TRANSFER OBJECTS)
    // ==========================================

    public class LoginRequest
    {
        public string Email { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
    }

    public class RegisterRequest
    {
        public string FullName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public string? Phone { get; set; }
        public string? Address { get; set; }
    }

    public class UpdateProfileRequest
    {
        public int UserId { get; set; }
        public string FullName { get; set; } = string.Empty;
        public string Phone { get; set; } = string.Empty;
        public string Address { get; set; } = string.Empty;
    }

    public class UpdateShipperRequest
    {
        public int UserId { get; set; }
        public string Phone { get; set; } = string.Empty;
        public string Address { get; set; } = string.Empty;
    }
}