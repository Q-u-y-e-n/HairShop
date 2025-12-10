class User {
  final int id;
  final String fullName;
  final String role;
  final String? avatar;

  User({
    required this.id,
    required this.fullName,
    required this.role,
    this.avatar,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      fullName: json['fullName'],
      role: json['role'], // "Shipper" hoặc "Customer"
      avatar: json['avatar'],
    );
  }
}
