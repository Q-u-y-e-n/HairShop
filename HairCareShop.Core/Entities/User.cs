using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema; // Cần thêm dòng này

namespace HairCareShop.Core.Entities
{
    public class User
    {
        public int Id { get; set; }

        [Required]
        public string FullName { get; set; } = string.Empty;

        [Required]
        public string Email { get; set; } = string.Empty;

        public string PasswordHash { get; set; } = string.Empty;
        public string? PhoneNumber { get; set; }
        public string? Address { get; set; }

        public string Role { get; set; } = "Customer";
        public string? AvatarUrl { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.Now;

        // --- CÁC TRƯỜNG CẦN THÊM ---
        public bool IsLocked { get; set; } = false; // Để khóa tài khoản

        // --- SỬA LỖI SHIPPER Ở ĐÂY ---
        // InverseProperty("User"): Chỉ định rõ list này map với thuộc tính 'User' bên bảng Order
        [InverseProperty("User")]
        public ICollection<Order> Orders { get; set; } = new List<Order>();

        [InverseProperty("Shipper")]
        public ICollection<Order> ShippedOrders { get; set; } = new List<Order>();
    }
}