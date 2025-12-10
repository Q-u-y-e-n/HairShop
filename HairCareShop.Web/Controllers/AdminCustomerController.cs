using HairCareShop.Core.Entities;
using HairCareShop.Data.EF;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace HairCareShop.Web.Controllers
{
    public class AdminCustomerController : Controller
    {
        private readonly HairCareShopDbContext _context;

        public AdminCustomerController(HairCareShopDbContext context)
        {
            _context = context;
        }

        // 1. DANH SÁCH KHÁCH HÀNG (INDEX)
        public async Task<IActionResult> Index(string searchString)
        {
            var query = _context.Users
                .Where(u => u.Role == "Customer")
                .Include(u => u.Orders)
                .AsQueryable();

            if (!string.IsNullOrEmpty(searchString))
            {
                searchString = searchString.ToLower();
                query = query.Where(u => u.FullName.ToLower().Contains(searchString)
                                      || u.Email.ToLower().Contains(searchString)
                                      || u.PhoneNumber.Contains(searchString));
            }

            var customers = await query.OrderByDescending(u => u.CreatedAt).ToListAsync();
            ViewData["CurrentFilter"] = searchString;
            return View(customers);
        }

        // 2. XEM CHI TIẾT & LỊCH SỬ (DETAILS)
        public async Task<IActionResult> Details(int id)
        {
            var user = await _context.Users
                .Include(u => u.Orders).ThenInclude(o => o.OrderDetails).ThenInclude(od => od.Product)
                .FirstOrDefaultAsync(u => u.Id == id);

            if (user == null) return NotFound();
            return View(user);
        }

        // 3. THÊM KHÁCH HÀNG MỚI (CREATE)
        [HttpGet]
        public IActionResult Create()
        {
            return View();
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(User user)
        {
            // Kiểm tra Email đã tồn tại chưa
            if (await _context.Users.AnyAsync(u => u.Email == user.Email))
            {
                ModelState.AddModelError("Email", "Email này đã được sử dụng.");
            }

            if (ModelState.IsValid)
            {
                user.Role = "Customer";
                user.CreatedAt = DateTime.Now;
                user.IsLocked = false;

                // Mật khẩu mặc định là 123456 (Trong thực tế nên mã hóa MD5/BCrypt ở đây)
                user.PasswordHash = "123456";

                _context.Users.Add(user);
                await _context.SaveChangesAsync();
                return RedirectToAction(nameof(Index));
            }
            return View(user);
        }

        // 4. SỬA THÔNG TIN (EDIT)
        [HttpGet]
        public async Task<IActionResult> Edit(int id)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null) return NotFound();
            return View(user);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(int id, User user)
        {
            if (id != user.Id) return NotFound();

            if (ModelState.IsValid)
            {
                try
                {
                    var existingUser = await _context.Users.FindAsync(id);
                    if (existingUser == null) return NotFound();

                    // Chỉ cập nhật các trường cho phép
                    existingUser.FullName = user.FullName;
                    existingUser.PhoneNumber = user.PhoneNumber;
                    existingUser.Address = user.Address;
                    // Không cập nhật Email, Password, Role tại đây để bảo mật

                    await _context.SaveChangesAsync();
                }
                catch (DbUpdateConcurrencyException)
                {
                    if (!_context.Users.Any(e => e.Id == id)) return NotFound();
                    else throw;
                }
                return RedirectToAction(nameof(Index));
            }
            return View(user);
        }

        // 5. XÓA KHÁCH HÀNG (DELETE)
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Delete(int id)
        {
            var user = await _context.Users
                .Include(u => u.Orders) // Load đơn hàng để kiểm tra
                .FirstOrDefaultAsync(u => u.Id == id);

            if (user == null) return NotFound();

            // Nếu khách đã có đơn hàng -> KHÔNG ĐƯỢC XÓA (để bảo toàn lịch sử kinh doanh)
            if (user.Orders != null && user.Orders.Any())
            {
                TempData["Error"] = "Không thể xóa khách hàng này vì đã có lịch sử mua hàng. Vui lòng sử dụng chức năng KHÓA tài khoản.";
                return RedirectToAction(nameof(Index));
            }

            _context.Users.Remove(user);
            await _context.SaveChangesAsync();

            TempData["Success"] = "Đã xóa khách hàng thành công.";
            return RedirectToAction(nameof(Index));
        }

        // 6. KHÓA TÀI KHOẢN (TOGGLE LOCK)
        [HttpPost]
        public async Task<IActionResult> ToggleStatus(int id)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null) return Json(new { success = false, message = "Lỗi" });

            user.IsLocked = !user.IsLocked;
            await _context.SaveChangesAsync();
            return Json(new { success = true, isLocked = user.IsLocked });
        }
    }
}