import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import các service và provider
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart'; // Quan trọng: Để tải giỏ hàng

// Import các màn hình điều hướng
import '../shipper/shipper_main_screen.dart';
import '../customer/customer_home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controller để lấy dữ liệu nhập vào
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  // Key để kiểm tra form (Validate)
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false; // Trạng thái đang tải
  bool _obscureText = true; // Trạng thái ẩn hiện mật khẩu
  final ApiService _api = ApiService();

  // --- HÀM XỬ LÝ ĐĂNG NHẬP ---
  void _handleLogin() async {
    // 1. Kiểm tra form có hợp lệ không (Email đúng định dạng, pass không rỗng)
    if (!_formKey.currentState!.validate()) return;

    // Bật vòng xoay loading
    setState(() => _isLoading = true);

    try {
      // 2. Gọi API Đăng nhập
      print("Đang đăng nhập: ${_emailController.text}");
      var data = await _api.login(_emailController.text, _passController.text);

      if (!mounted) return;

      // 3. Lưu thông tin User vào AuthProvider (RAM)
      Provider.of<AuthProvider>(context, listen: false).setUser(data);

      // 4. --- QUAN TRỌNG: Tải giỏ hàng cũ về ngay lập tức ---
      print(
        "Đăng nhập thành công! Đang tải giỏ hàng cho User ID: ${data['id']}...",
      );
      await Provider.of<CartProvider>(
        context,
        listen: false,
      ).fetchCart(data['id']);
      // -----------------------------------------------------

      // 5. Kiểm tra Role để chuyển hướng
      String role = data['role'];
      if (role == "Shipper") {
        // Chuyển sang giao diện Shipper
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ShipperMainScreen()),
        );
      } else {
        // Chuyển sang giao diện Khách hàng
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => CustomerHomeScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      // Hiển thị lỗi (ví dụ: Sai mật khẩu, Lỗi kết nối...)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Đăng nhập thất bại: ${e.toString().replaceAll('Exception:', '')}",
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      // Tắt loading dù thành công hay thất bại
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- GIAO DIỆN ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(25),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. Logo ứng dụng
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.spa, size: 80, color: Colors.blue),
                ),
                SizedBox(height: 20),
                Text(
                  "HairCare Shop",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                Text(
                  "Chăm sóc mái tóc của bạn",
                  style: TextStyle(color: Colors.grey),
                ),

                SizedBox(height: 40),

                // 2. Input Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Email",
                    hintText: "vidu@gmail.com",
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 20,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return "Vui lòng nhập Email";
                    if (!value.contains("@")) return "Email không hợp lệ";
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // 3. Input Mật khẩu
                TextFormField(
                  controller: _passController,
                  obscureText: _obscureText, // Ẩn/Hiện pass
                  decoration: InputDecoration(
                    labelText: "Mật khẩu",
                    prefixIcon: Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _obscureText = !_obscureText);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 20,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return "Vui lòng nhập mật khẩu";
                    if (value.length < 6) return "Mật khẩu phải từ 6 ký tự";
                    return null;
                  },
                ),

                SizedBox(height: 10),

                // Quên mật khẩu (Optional)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: Text(
                      "Quên mật khẩu?",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // 4. Nút Đăng nhập
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            "ĐĂNG NHẬP",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                SizedBox(height: 30),

                // 5. Chuyển sang Đăng ký
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Chưa có tài khoản? ",
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => RegisterScreen()),
                        );
                      },
                      child: Text(
                        "Đăng ký ngay",
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20),
                // Footer version
                Text(
                  "Phiên bản 1.0.0",
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
