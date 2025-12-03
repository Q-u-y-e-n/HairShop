using HairCareShop.Core.Entities;
using HairCareShop.Data.EF;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;

namespace HairCareShop.Web.Controllers
{
    public class AdminProductController : Controller
    {
        private readonly HairCareShopDbContext _context;
        private readonly IWebHostEnvironment _webHostEnvironment;

        public AdminProductController(HairCareShopDbContext context, IWebHostEnvironment webHostEnvironment)
        {
            _context = context;
            _webHostEnvironment = webHostEnvironment;
        }

        // ==========================================
        // 1. DANH SÁCH SẢN PHẨM (INDEX)
        // ==========================================
        public async Task<IActionResult> Index(string searchString)
        {
            // Eager Loading: Lấy kèm Category và ProductBatches để hiển thị hạn sử dụng/lô
            var query = _context.Products
                .Include(p => p.Category)
                .Include(p => p.ProductBatches)
                .AsQueryable();

            // Logic tìm kiếm
            if (!string.IsNullOrEmpty(searchString))
            {
                query = query.Where(p => p.Name.Contains(searchString) || p.Brand.Contains(searchString));
            }

            // Sắp xếp: Mới nhất lên đầu
            var products = await query.OrderByDescending(p => p.Id).ToListAsync();

            ViewData["CurrentFilter"] = searchString;

            return View(products);
        }

        // ==========================================
        // 2. TẠO MỚI SẢN PHẨM (CREATE)
        // ==========================================

        // GET: Hiển thị form
        public IActionResult Create()
        {
            ViewBag.Categories = new SelectList(_context.Categories, "Id", "Name");
            return View();
        }

        // POST: Xử lý dữ liệu gửi lên
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(Product product, IFormFile? imageFile,
            // Các tham số cho việc nhập kho lần đầu
            DateTime? ManufacturingDate, DateTime? ExpiryDate, int InitialStock, string? BatchCode)
        {
            if (ModelState.IsValid)
            {
                // A. Xử lý Upload ảnh
                if (imageFile != null)
                {
                    product.ImageUrl = await SaveImage(imageFile);
                }

                // --- B. TÍNH TOÁN TỒN KHO ---
                // Logic: Tồn kho thực tế (đơn vị lẻ) = Số thùng nhập * Quy cách đóng thùng
                int unitPerBox = product.UnitsPerBox > 0 ? product.UnitsPerBox : 1;
                int finalQuantity = 0;

                if (InitialStock > 0)
                {
                    finalQuantity = InitialStock * unitPerBox;
                    product.StockQuantity = finalQuantity; // Cập nhật tổng tồn kho vào sản phẩm
                }

                // C. Lưu Sản phẩm vào Database (để sinh ra Product ID)
                _context.Add(product);
                await _context.SaveChangesAsync();

                // D. Tự động tạo Lô hàng (ProductBatch) đầu tiên
                if (InitialStock > 0)
                {
                    var mDate = ManufacturingDate ?? DateTime.Now;
                    var eDate = ExpiryDate ?? DateTime.Now.AddYears(1);

                    var firstBatch = new ProductBatch
                    {
                        ProductId = product.Id, // ID vừa sinh ra ở bước C
                        BatchCode = !string.IsNullOrEmpty(BatchCode) ? BatchCode : $"L-{DateTime.Now:yyyyMMdd}",
                        ManufacturingDate = mDate,
                        ExpiryDate = eDate,
                        Quantity = finalQuantity // Lưu số lượng đã quy đổi (Ví dụ: 30 chai)
                    };

                    _context.ProductBatches.Add(firstBatch);
                    await _context.SaveChangesAsync();
                }

                return RedirectToAction(nameof(Index));
            }

            // Nếu lỗi validate, load lại danh mục và trả về View
            ViewBag.Categories = new SelectList(_context.Categories, "Id", "Name", product.CategoryId);
            return View(product);
        }

        // ==========================================
        // 3. CHỈNH SỬA SẢN PHẨM (EDIT)
        // ==========================================

        // GET: Hiển thị form edit
        public async Task<IActionResult> Edit(int? id)
        {
            if (id == null) return NotFound();

            var product = await _context.Products.FindAsync(id);
            if (product == null) return NotFound();

            ViewBag.Categories = new SelectList(_context.Categories, "Id", "Name", product.CategoryId);
            return View(product);
        }

        // POST: Lưu thay đổi
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(int id, Product product, IFormFile? imageFile)
        {
            if (id != product.Id) return NotFound();

            if (ModelState.IsValid)
            {
                try
                {
                    // A. Xử lý ảnh
                    if (imageFile != null)
                    {
                        // Nếu user chọn ảnh mới -> Lưu ảnh mới
                        product.ImageUrl = await SaveImage(imageFile);
                    }
                    else
                    {
                        // Nếu user KHÔNG chọn ảnh mới -> Giữ nguyên ảnh cũ
                        // Cần query lại DB để lấy đường dẫn cũ (vì form không gửi file lên thì model.ImageUrl sẽ null)
                        var oldProduct = await _context.Products.AsNoTracking().FirstOrDefaultAsync(p => p.Id == id);
                        if (oldProduct != null)
                        {
                            product.ImageUrl = oldProduct.ImageUrl;
                        }
                    }

                    // Lưu ý: Không cập nhật StockQuantity ở đây để tránh sai lệch với Lô hàng.
                    // Nếu muốn sửa StockQuantity thủ công, cần cẩn trọng hoặc chặn ở View.

                    _context.Update(product);
                    await _context.SaveChangesAsync();
                }
                catch (DbUpdateConcurrencyException)
                {
                    if (!_context.Products.Any(e => e.Id == product.Id)) return NotFound();
                    else throw;
                }
                return RedirectToAction(nameof(Index));
            }

            ViewBag.Categories = new SelectList(_context.Categories, "Id", "Name", product.CategoryId);
            return View(product);
        }

        // ==========================================
        // 4. XÓA SẢN PHẨM (DELETE)
        // ==========================================
        public async Task<IActionResult> Delete(int id)
        {
            var product = await _context.Products.FindAsync(id);
            if (product != null)
            {
                // 1. Xóa các lô hàng liên quan trước
                var batches = _context.ProductBatches.Where(b => b.ProductId == id);
                _context.ProductBatches.RemoveRange(batches);

                // 2. Xóa lịch sử nhập kho chi tiết
                var importDetails = _context.ImportNoteDetails.Where(d => d.ProductId == id);
                _context.ImportNoteDetails.RemoveRange(importDetails);

                // 3. Xóa chi tiết đơn hàng (Cẩn thận: Sẽ làm mất dữ liệu đơn hàng cũ!)
                var orderDetails = _context.OrderDetails.Where(d => d.ProductId == id);
                _context.OrderDetails.RemoveRange(orderDetails);

                // 4. Cuối cùng mới xóa sản phẩm
                _context.Products.Remove(product);

                await _context.SaveChangesAsync();
            }
            return RedirectToAction(nameof(Index));
        }

        // ==========================================
        // 5. HELPER: HÀM LƯU ẢNH
        // ==========================================
        private async Task<string> SaveImage(IFormFile imageFile)
        {
            // Thư mục lưu: wwwroot/products/images/
            string folder = "products/images/";
            string uniqueFileName = Guid.NewGuid().ToString() + "_" + imageFile.FileName;
            string serverFolder = Path.Combine(_webHostEnvironment.WebRootPath, folder);

            if (!Directory.Exists(serverFolder)) Directory.CreateDirectory(serverFolder);

            string filePath = Path.Combine(serverFolder, uniqueFileName);
            using (var fileStream = new FileStream(filePath, FileMode.Create))
            {
                await imageFile.CopyToAsync(fileStream);
            }

            // Trả về đường dẫn tương đối
            return "/" + folder + uniqueFileName;
        }
    }
}