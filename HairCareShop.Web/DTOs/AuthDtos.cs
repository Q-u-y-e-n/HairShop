namespace HairCareShop.Web.DTOs
{
    // Dữ liệu gửi lên khi Đăng nhập
    public class LoginRequest
    {
        public string Email { get; set; }
        public string Password { get; set; }
    }

    // Dữ liệu gửi lên khi Đăng ký
    public class RegisterRequest
    {
        public string FullName { get; set; }
        public string Email { get; set; }
        public string Password { get; set; }
    }

    // Dữ liệu gửi lên khi Đăng ký làm Shipper
    public class UpdateShipperRequest
    {
        public int UserId { get; set; }
        public string Phone { get; set; }
        public string Address { get; set; }
    }
}