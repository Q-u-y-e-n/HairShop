class User {
  final int id;
  final String email;
  final String fullName;
  final String role;

  // --- QUAN TRỌNG: Phải có 2 biến này ---
  final String? phone;
  final String? address;
  final String? avatarUrl;
  // --------------------------------------

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.phone,
    this.address,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'] ?? "",
      fullName: json['fullName'] ?? "Người dùng",
      role: json['role'] ?? "Customer",

      // --- LỖI Ở ĐÂY: Bạn có thể đang thiếu 2 dòng này ---
      // Kiểm tra kỹ tên trường trả về từ API (thường là chữ thường)
      phone: json['phone'],
      address: json['address'],
      avatarUrl: json['avatarUrl'],
      // --------------------------------------------------
    );
  }
}
