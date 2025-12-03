namespace HairCareShop.Core.Entities
{
    public class ImportNote
    {
        public int Id { get; set; }
        public int SupplierId { get; set; }
        public DateTime ImportDate { get; set; } = DateTime.Now;
        public decimal TotalAmount { get; set; }
        public string? Note { get; set; } // <--- BẮT BUỘC CÓ

        public Supplier? Supplier { get; set; }
        public ICollection<ImportNoteDetail> Details { get; set; } = new List<ImportNoteDetail>();
    }
}