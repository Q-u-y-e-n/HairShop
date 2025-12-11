import 'package:flutter/material.dart';
import '../models/user_model.dart'; // Đảm bảo đúng tên file model của bạn (user.dart hoặc user_model.dart)
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  final ApiService _apiService =
      ApiService(); // Khởi tạo ApiService để gọi mạng

  User? get user => _user;

  // 1. SET USER (Dùng khi Login thành công)
  void setUser(Map<String, dynamic> data) {
    _user = User.fromJson(data);
    notifyListeners();
  }

  // 2. ĐĂNG XUẤT
  void logout() {
    _user = null;
    notifyListeners();
  }

  // 3. CẬP NHẬT THÔNG TIN (Vừa gọi API, vừa cập nhật RAM)
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
      // B. Nếu thành công -> Cập nhật lại User trong bộ nhớ App
      // Vì các field là final, ta tạo object mới đè lên object cũ
      _user = User(
        id: _user!.id,
        email: _user!.email,
        role: _user!.role,
        fullName: fullName, // Dữ liệu mới
        phone: phone, // Dữ liệu mới
        address: address, // Dữ liệu mới
      );

      notifyListeners(); // Báo cho UI vẽ lại
      return true;
    }

    return false;
  }

  // HÀM GỌI TỪ UI ĐỂ UPLOAD
  Future<bool> updateAvatar(String filePath) async {
    if (_user == null) return false;

    // 1. Gọi API upload
    String? newUrl = await _apiService.uploadAvatar(_user!.id, filePath);

    if (newUrl != null) {
      // 2. Cập nhật User trong bộ nhớ
      _user = User(
        id: _user!.id,
        email: _user!.email,
        fullName: _user!.fullName,
        role: _user!.role,
        phone: _user!.phone,
        address: _user!.address,
        avatarUrl: newUrl, // <--- CẬP NHẬT URL MỚI
      );
      notifyListeners();
      return true;
    }
    return false;
  }
}
