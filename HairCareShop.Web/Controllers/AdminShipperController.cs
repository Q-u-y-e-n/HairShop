using HairCareShop.Core.Entities;
using HairCareShop.Core.Enums;
using HairCareShop.Data.EF;
using HairCareShop.Web.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace HairCareShop.Web.Controllers
{
    public class AdminShipperController : Controller
    {
        private readonly HairCareShopDbContext _context;

        public AdminShipperController(HairCareShopDbContext context)
        {
            _context = context;
        }

        // 1. DANH SÁCH SHIPPER
        // 1. DANH SÁCH SHIPPER
        public async Task<IActionResult> Index()
        {
            var shippers = await _context.Users
                .Where(u => u.Role == "Shipper")
                // --- SỬA LẠI DÒNG NÀY ---
                .Include(u => u.ShippedOrders) // Load danh sách đơn đã giao
                                               // ------------------------
                .OrderByDescending(u => u.CreatedAt)
                .ToListAsync();

            return View(shippers);
        }

        // 2. THÊM SHIPPER MỚI
        public IActionResult Create() => View();

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(User user)
        {
            if (await _context.Users.AnyAsync(u => u.Email == user.Email))
            {
                ModelState.AddModelError("Email", "Email này đã tồn tại.");
                return View(user);
            }

            // Thiết lập mặc định cho Shipper
            user.Role = "Shipper";
            user.CreatedAt = DateTime.Now;
            user.IsLocked = false;
            user.PasswordHash = "123456"; // Pass mặc định

            _context.Users.Add(user);
            await _context.SaveChangesAsync();
            return RedirectToAction(nameof(Index));
        }

        // 3. SỬA THÔNG TIN
        // GET: AdminShipper/Edit/5
        public async Task<IActionResult> Edit(int? id)
        {
            if (id == null) return NotFound();
            var user = await _context.Users.FindAsync(id);
            if (user == null) return NotFound();
            return View(user);
        }

        // POST: AdminShipper/Edit/5
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(int id, [Bind("Id,FullName,PhoneNumber,Address")] User user)
        {
            if (id != user.Id) return NotFound();

            if (ModelState.IsValid)
            {
                try
                {
                    // Lấy user cũ từ DB lên để chỉ update những trường cho phép
                    var existingUser = await _context.Users.FindAsync(id);
                    if (existingUser == null) return NotFound();

                    existingUser.FullName = user.FullName;
                    existingUser.PhoneNumber = user.PhoneNumber;
                    existingUser.Address = user.Address;

                    _context.Update(existingUser);
                    await _context.SaveChangesAsync();
                }
                catch (DbUpdateConcurrencyException)
                {
                    if (!_context.Users.Any(e => e.Id == user.Id)) return NotFound();
                    else throw;
                }
                return RedirectToAction(nameof(Index));
            }
            return View(user);
        }

        // 4. XEM CHI TIẾT & THỐNG KÊ (QUAN TRỌNG)
        public async Task<IActionResult> Details(int id, int? month, int? year)
        {
            var shipper = await _context.Users.FindAsync(id);
            if (shipper == null || shipper.Role != "Shipper") return NotFound();

            // Lấy tất cả đơn hàng ĐÃ GIAO THÀNH CÔNG của shipper này
            var query = _context.Orders
                 .Where(o => o.ShipperId == id && o.Status == OrderStatus.Completed);
            // Nếu có lọc theo tháng/năm
            if (month.HasValue) query = query.Where(o => o.OrderDate.Month == month.Value);
            if (year.HasValue) query = query.Where(o => o.OrderDate.Year == year.Value);

            var completedOrders = await query.ToListAsync();

            // Tính toán thống kê
            // A. Lấy toàn bộ lịch sử (không lọc) để tính tổng tháng hoạt động
            var allHistory = await _context.Orders
                .Where(o => o.ShipperId == id && o.Status == OrderStatus.Completed)
                .Select(o => o.OrderDate)
                .ToListAsync();

            // B. Group dữ liệu để hiển thị ra bảng
            var stats = completedOrders
                .GroupBy(o => new { o.OrderDate.Month, o.OrderDate.Year })
                .Select(g => new MonthlyShipperStat
                {
                    Month = g.Key.Month,
                    Year = g.Key.Year,
                    OrderCount = g.Count(),
                    TotalRevenueCollected = g.Sum(o => o.TotalAmount)
                })
                .OrderByDescending(s => s.Year).ThenByDescending(s => s.Month)
                .ToList();

            var viewModel = new ShipperDetailViewModel
            {
                Shipper = shipper,
                MonthlyStats = stats,
                TotalCompletedOrders = allHistory.Count,
                // Đếm số tháng distinct (Ví dụ: T1, T2, T3 => 3 tháng)
                TotalActiveMonths = allHistory.Select(d => new { d.Month, d.Year }).Distinct().Count(),
                FilterMonth = month,
                FilterYear = year
            };

            return View(viewModel);
        }

        // 5. KHÓA / XÓA
        [HttpPost]
        public async Task<IActionResult> ToggleLock(int id)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null) return Json(new { success = false });
            user.IsLocked = !user.IsLocked;
            await _context.SaveChangesAsync();
            return Json(new { success = true, isLocked = user.IsLocked });
        }
    }
}