using HairCareShop.Core.Entities;
using HairCareShop.Data.EF;
using HairCareShop.Web.Models; // Sử dụng ViewModel
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;

namespace HairCareShop.Web.Controllers
{
    public class AdminImportController : Controller
    {
        private readonly HairCareShopDbContext _context;

        public AdminImportController(HairCareShopDbContext context)
        {
            _context = context;
        }

        // ==========================================
        // 1. DANH SÁCH LỊCH SỬ NHẬP (INDEX)
        // ==========================================
        // 1. DANH SÁCH LỊCH SỬ (INDEX)
        public async Task<IActionResult> Index()
        {
            var list = await _context.ImportNotes
                .Include(i => i.Supplier) // Lấy kèm tên Nhà cung cấp
                .OrderByDescending(i => i.ImportDate) // Sắp xếp mới nhất lên đầu
                .ToListAsync();

            return View(list);
        }

        // ==========================================
        // 2. CHI TIẾT PHIẾU NHẬP (DETAILS)
        // ==========================================
        // 2. XEM CHI TIẾT PHIẾU (DETAILS)
        public async Task<IActionResult> Details(int id)
        {
            var note = await _context.ImportNotes
                .Include(i => i.Supplier)
                .Include(i => i.Details).ThenInclude(d => d.Product) // Lấy chi tiết sp
                .FirstOrDefaultAsync(m => m.Id == id);

            if (note == null) return NotFound();

            return View(note);
        }

        // ==========================================
        // 3. GIAO DIỆN TẠO MỚI (GET)
        // ==========================================
        [HttpGet]
        public async Task<IActionResult> Create()
        {
            await PrepareViewBags();
            return View();
        }

        // ==========================================
        // 4. XỬ LÝ LƯU PHIẾU NHẬP (POST) - QUAN TRỌNG
        // ==========================================
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(ImportNoteViewModel model)
        {
            // 1. Validate dữ liệu
            if (model.SupplierId == 0) ModelState.AddModelError("SupplierId", "Vui lòng chọn Nhà cung cấp.");
            if (model.Details == null || !model.Details.Any()) ModelState.AddModelError("", "Vui lòng nhập ít nhất 1 sản phẩm.");

            if (!ModelState.IsValid)
            {
                await PrepareViewBags();
                return View(model);
            }

            // 2. Bắt đầu Transaction (Giao dịch)
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                // A. Tạo Header Phiếu Nhập
                var note = new ImportNote
                {
                    SupplierId = model.SupplierId,
                    ImportDate = DateTime.Now,
                    Note = model.Note,
                    TotalAmount = 0
                };

                _context.ImportNotes.Add(note);
                await _context.SaveChangesAsync(); // LƯU ĐỂ LẤY ID (note.Id)

                decimal totalAmount = 0;

                // B. Duyệt qua từng dòng chi tiết
                foreach (var item in model.Details)
                {
                    // Tính toán quy đổi: Tổng lẻ = Số thùng * Quy cách
                    int finalQty = item.BoxQuantity * item.UnitsPerBox;
                    decimal lineTotal = finalQty * item.ImportPrice;

                    // C. Tạo Chi tiết phiếu nhập
                    var detail = new ImportNoteDetail
                    {
                        ImportNoteId = note.Id, // <--- QUAN TRỌNG: Gán ID của phiếu vừa tạo
                        ProductId = item.ProductId,
                        BatchCode = item.BatchCode,
                        ManufacturingDate = item.ManufacturingDate,
                        ExpiryDate = item.ExpiryDate,
                        BoxQuantity = item.BoxQuantity,
                        UnitsPerBox = item.UnitsPerBox,
                        TotalQuantity = finalQty,
                        ImportPrice = item.ImportPrice
                    };
                    _context.ImportNoteDetails.Add(detail);

                    // D. Cập nhật Kho Tổng (Product)
                    var product = await _context.Products.FindAsync(item.ProductId);
                    if (product != null)
                    {
                        product.StockQuantity += finalQty; // Cộng dồn tồn kho
                        // Có thể cập nhật giá nhập mới nhất vào giá gốc sản phẩm nếu muốn
                        // product.OriginalPrice = item.ImportPrice; 
                    }

                    // E. Cập nhật/Tạo Lô Hàng (ProductBatch)
                    var existingBatch = await _context.ProductBatches
                        .FirstOrDefaultAsync(b => b.ProductId == item.ProductId && b.BatchCode == item.BatchCode);

                    if (existingBatch != null)
                    {
                        existingBatch.Quantity += finalQty; // Lô đã có -> Cộng thêm
                    }
                    else
                    {
                        // Lô chưa có -> Tạo mới
                        _context.ProductBatches.Add(new ProductBatch
                        {
                            ProductId = item.ProductId,
                            BatchCode = item.BatchCode,
                            ManufacturingDate = item.ManufacturingDate,
                            ExpiryDate = item.ExpiryDate,
                            Quantity = finalQty
                        });
                    }

                    totalAmount += lineTotal;
                }

                // F. Cập nhật Tổng tiền và Commit
                note.TotalAmount = totalAmount;
                await _context.SaveChangesAsync();

                await transaction.CommitAsync(); // Xác nhận mọi thay đổi thành công

                // G. Chuyển hướng về trang Danh sách
                // Chuyển hướng sang Controller khác: (Tên Action, Tên Controller - bỏ chữ Controller)
                return RedirectToAction("Index", "AdminProduct");
            }
            catch (Exception ex)
            {
                await transaction.RollbackAsync(); // Gặp lỗi thì hoàn tác
                ViewBag.Error = "Lỗi hệ thống: " + ex.Message; // Hiển thị lỗi ra View
                if (ex.InnerException != null) ViewBag.Error += " (" + ex.InnerException.Message + ")";

                await PrepareViewBags();
                return View(model);
            }
        }

        // ==========================================
        // 5. API TẠO NHANH SẢN PHẨM (AJAX)
        // ==========================================
        [HttpPost]
        public async Task<IActionResult> QuickCreateProduct(string Name, int CategoryId, decimal Price, string UnitName, int UnitsPerBox)
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
                    StockQuantity = 0, // Tồn kho = 0 (Sẽ tăng khi nhập phiếu)
                    Brand = "Mới",
                    Description = "Tạo nhanh từ màn hình nhập kho"
                };

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

        // HELPER: Load dữ liệu cho Dropdown
        private async Task PrepareViewBags()
        {
            ViewBag.Suppliers = new SelectList(await _context.Suppliers.ToListAsync(), "Id", "Name");
            ViewBag.Categories = new SelectList(await _context.Categories.ToListAsync(), "Id", "Name");

            // Lấy dữ liệu sản phẩm để JS xử lý
            var products = await _context.Products.Select(p => new
            {
                p.Id,
                p.Name,
                p.UnitsPerBox,
                p.UnitName,
                p.Price
            }).ToListAsync();

            ViewBag.ProductsData = products;
        }
    }
}