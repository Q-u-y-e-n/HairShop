using HairCareShop.Core.Entities;
using HairCareShop.Data.EF;
using HairCareShop.Web.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;

namespace HairCareShop.Web.Controllers
{
    public class AdminImportController : Controller
    {
        private readonly HairCareShopDbContext _context;

        // 1. KHAI BÁO BIẾN MÔI TRƯỜNG (Để sửa lỗi _webHostEnvironment)
        private readonly IWebHostEnvironment _webHostEnvironment;

        // 2. INJECT VÀO CONSTRUCTOR
        public AdminImportController(HairCareShopDbContext context, IWebHostEnvironment webHostEnvironment)
        {
            _context = context;
            _webHostEnvironment = webHostEnvironment;
        }

        // ... (Các hàm Index, Details, Create GET giữ nguyên) ...
        public async Task<IActionResult> Index()
        {
            var list = await _context.ImportNotes.Include(i => i.Supplier).OrderByDescending(i => i.ImportDate).ToListAsync();
            return View(list);
        }

        public async Task<IActionResult> Details(int id)
        {
            var note = await _context.ImportNotes.Include(i => i.Supplier).Include(i => i.Details).ThenInclude(d => d.Product).FirstOrDefaultAsync(m => m.Id == id);
            if (note == null) return NotFound();
            return View(note);
        }

        [HttpGet]
        public async Task<IActionResult> Create()
        {
            await PrepareViewBags();
            return View();
        }

        // ... (Hàm Create POST giữ nguyên logic của bạn) ...
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(ImportNoteViewModel model)
        {
            if (model.SupplierId == 0) ModelState.AddModelError("SupplierId", "Vui lòng chọn Nhà cung cấp.");
            if (model.Details == null || !model.Details.Any()) ModelState.AddModelError("", "Vui lòng nhập ít nhất 1 sản phẩm.");

            if (!ModelState.IsValid) { await PrepareViewBags(); return View(model); }

            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var note = new ImportNote { SupplierId = model.SupplierId, ImportDate = DateTime.Now, Note = model.Note, TotalAmount = 0 };
                _context.ImportNotes.Add(note);
                await _context.SaveChangesAsync();

                decimal total = 0;
                foreach (var item in model.Details)
                {
                    int qty = item.BoxQuantity * item.UnitsPerBox;
                    decimal lineTotal = qty * item.ImportPrice;

                    _context.ImportNoteDetails.Add(new ImportNoteDetail
                    {
                        ImportNoteId = note.Id, // Đã có trường này nhờ Bước 1
                        ProductId = item.ProductId,
                        BatchCode = item.BatchCode,
                        ManufacturingDate = item.ManufacturingDate,
                        ExpiryDate = item.ExpiryDate,
                        BoxQuantity = item.BoxQuantity,
                        UnitsPerBox = item.UnitsPerBox,
                        TotalQuantity = qty,
                        ImportPrice = item.ImportPrice
                    });

                    var product = await _context.Products.FindAsync(item.ProductId);
                    if (product != null) product.StockQuantity += qty;

                    var batch = await _context.ProductBatches.FirstOrDefaultAsync(b => b.ProductId == item.ProductId && b.BatchCode == item.BatchCode);
                    if (batch != null) batch.Quantity += qty;
                    else _context.ProductBatches.Add(new ProductBatch { ProductId = item.ProductId, BatchCode = item.BatchCode, ManufacturingDate = item.ManufacturingDate, ExpiryDate = item.ExpiryDate, Quantity = qty });

                    total += lineTotal;
                }

                note.TotalAmount = total;
                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                return RedirectToAction("Index", "AdminProduct");
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync();
                ViewBag.Error = ex.Message;
                await PrepareViewBags();
                return View(model);
            }
        }

        // ==========================================
        // 3. SỬA HÀM QUICK CREATE (LƯU ẢNH CHUẨN)
        // ==========================================
        [HttpPost]
        public async Task<IActionResult> QuickCreateProduct(string Name, int CategoryId, decimal Price, string UnitName, int UnitsPerBox, IFormFile? ImageFile)
        {
            try
            {
                var newProduct = new Product
                {
                    Name = Name,
                    CategoryId = CategoryId,
                    Price = Price,
                    UnitName = UnitName,
                    UnitsPerBox = UnitsPerBox,
                    StockQuantity = 0,
                    Brand = "Mới",
                    Description = "Tạo nhanh từ màn hình nhập kho"
                };

                // --- LOGIC LƯU ẢNH ---
                if (ImageFile != null && ImageFile.Length > 0)
                {
                    // Tạo tên file ngẫu nhiên
                    string fileName = Guid.NewGuid().ToString() + Path.GetExtension(ImageFile.FileName);

                    // Lấy đường dẫn thư mục wwwroot/products/images
                    string uploadFolder = Path.Combine(_webHostEnvironment.WebRootPath, "products", "images");

                    // Tạo thư mục nếu chưa có
                    if (!Directory.Exists(uploadFolder)) Directory.CreateDirectory(uploadFolder);

                    // Lưu file vật lý
                    string filePath = Path.Combine(uploadFolder, fileName);
                    using (var stream = new FileStream(filePath, FileMode.Create))
                    {
                        await ImageFile.CopyToAsync(stream);
                    }

                    // Lưu đường dẫn vào DB (Có dấu / ở đầu)
                    newProduct.ImageUrl = "/products/images/" + fileName;
                }
                // ---------------------

                _context.Products.Add(newProduct);
                await _context.SaveChangesAsync();

                return Json(new
                {
                    success = true,
                    data = new
                    {
                        id = newProduct.Id,
                        name = newProduct.Name,
                        unitsPerBox = newProduct.UnitsPerBox,
                        unitName = newProduct.UnitName
                    }
                });
            }
            catch (Exception ex)
            {
                return Json(new { success = false, message = ex.Message });
            }
        }

        private async Task PrepareViewBags()
        {
            ViewBag.Suppliers = new SelectList(await _context.Suppliers.ToListAsync(), "Id", "Name");
            ViewBag.Categories = new SelectList(await _context.Categories.ToListAsync(), "Id", "Name");
            ViewBag.ProductsData = await _context.Products.Select(p => new { p.Id, p.Name, p.UnitsPerBox, p.UnitName, p.Price }).ToListAsync();
        }
    }
}