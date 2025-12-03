using System.ComponentModel.DataAnnotations.Schema;

namespace HairCareShop.Core.Entities
{
    public class ImportNoteDetail
    {
        public int Id { get; set; }

        // --- ĐÂY LÀ DÒNG BẠN ĐANG THIẾU ---
        public int ImportNoteId { get; set; }
        // ----------------------------------

        public int ProductId { get; set; }
        public string BatchCode { get; set; } = string.Empty;
        public DateTime ManufacturingDate { get; set; }
        public DateTime ExpiryDate { get; set; }
        public int BoxQuantity { get; set; }
        public int UnitsPerBox { get; set; }
        public int TotalQuantity { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal ImportPrice { get; set; }

        // Navigation properties (Liên kết)
        public Product? Product { get; set; }
        [ForeignKey("ImportNoteId")]
        public ImportNote? ImportNote { get; set; }
    }
}