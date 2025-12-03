namespace HairCareShop.Web.Models
{
    public class ImportNoteViewModel
    {
        public int SupplierId { get; set; }
        public string? Note { get; set; }
        public List<ImportNoteDetailViewModel> Details { get; set; } = new List<ImportNoteDetailViewModel>();
    }

    public class ImportNoteDetailViewModel
    {
        public int ProductId { get; set; }
        public string BatchCode { get; set; } = string.Empty;
        public DateTime ManufacturingDate { get; set; }
        public DateTime ExpiryDate { get; set; }
        public int BoxQuantity { get; set; }
        public int UnitsPerBox { get; set; }
        public decimal ImportPrice { get; set; }
    }
}