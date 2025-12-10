class User {
  final int id;
  final String email;
  final String fullName;
  final String role;

  // --- BỔ SUNG 2 TRƯỜNG NÀY ---
  final String? phone;
  final String? address;
  // ----------------------------

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.phone,
    this.address,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'] ?? "", // Tránh lỗi null
      fullName: json['fullName'] ?? "Người dùng",
      role: json['role'] ?? "Customer",

      // --- MAP DỮ LIỆU TỪ API ---
      // Nếu API trả về 'phoneNumber' thì sửa dòng dưới thành json['phoneNumber']
      phone: json['phone'],
      address: json['address'],
      // --------------------------
    );
  }

  // Hàm chuyển đổi sang Map (nếu cần lưu xuống local storage)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'role': role,
      'phone': phone,
      'address': address,
    };
  }
}
