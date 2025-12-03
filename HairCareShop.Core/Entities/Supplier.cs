using System.ComponentModel.DataAnnotations; // Thêm dòng này để dùng [EmailAddress]

namespace HairCareShop.Core.Entities
{
    public class Supplier
    {
        public int Id { get; set; }

        [Required(ErrorMessage = "Tên không được để trống")]
        public string Name { get; set; } = string.Empty;

        public string? PhoneNumber { get; set; }

        [EmailAddress(ErrorMessage = "Email không hợp lệ")]
        public string? Email { get; set; } // <--- MỚI THÊM

        public string? Address { get; set; }
    }
}