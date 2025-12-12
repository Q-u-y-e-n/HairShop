import 'package:flutter/material.dart';
import '../models/user_model.dart'; // Đảm bảo import đúng file Model User của bạn
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  final ApiService _apiService = ApiService();

  User? get user => _user;

  // 1. SET USER (Khi đăng nhập)
  void setUser(Map<String, dynamic> data) {
    _user = User.fromJson(data);
    notifyListeners();
  }

  // 2. ĐĂNG XUẤT
  void logout() {
    _user = null;
    notifyListeners();
  }

  // 3. CẬP NHẬT THÔNG TIN (Logic quan trọng đã sửa)
  Future<bool> updateUserInfo(
    String fullName,
    String phone,
    String address,
  ) async {
    if (_user == null) return false;

    // A. Gọi API cập nhật xuống Server
    bool success = await _apiService.updateProfile(
      _user!.id,
      fullName,
      phone,
      address,
    );

    if (success) {
      // B. CẬP NHẬT NGAY LẬP TỨC VÀO BỘ NHỚ (RAM)
      // Tạo một User mới copy từ User cũ nhưng thay đổi thông tin mới
      _user = User(
        id: _user!.id,
        email: _user!.email,
        role: _user!.role,
        avatarUrl: _user!.avatarUrl, // Giữ nguyên avatar

        fullName: fullName, // Mới
        phone: phone, // Mới
        address: address, // Mới (Với Shipper là khu vực hoạt động)
      );

      // C. Báo cho giao diện vẽ lại
      notifyListeners();
      return true;
    }

    return false;
  }

  // 4. CẬP NHẬT AVATAR
  Future<bool> updateAvatar(String filePath) async {
    if (_user == null) return false;

    // Gọi API upload
    String? newUrl = await _apiService.uploadAvatar(_user!.id, filePath);

    if (newUrl != null) {
      // Cập nhật URL ảnh mới vào bộ nhớ
      _user = User(
        id: _user!.id,
        email: _user!.email,
        fullName: _user!.fullName,
        role: _user!.role,
        phone: _user!.phone,
        address: _user!.address,
        avatarUrl: newUrl, // <-- URL Mới từ Server
      );
      notifyListeners();
      return true;
    }
    return false;
  }
}
