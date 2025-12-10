import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/api_service.dart';
import 'shipper/shipper_home_screen.dart'; // Import màn hình Shipper
import 'auth/login_screen.dart';
import 'customer/my_orders_screen.dart';

class AccountScreen extends StatefulWidget {
  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final ApiService _api = ApiService();

  // --- LOGIC 1: ĐĂNG KÝ SHIPPER ---
  void _showShipperDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Đăng ký làm Shipper"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Vui lòng bổ sung thông tin để chạy xe:",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            SizedBox(height: 15),
            TextField(
              controller: _phoneCtrl,
              decoration: InputDecoration(
                labelText: "Số điện thoại liên hệ",
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 10),
            TextField(
              controller: _addressCtrl,
              decoration: InputDecoration(
                labelText: "Khu vực hoạt động",
                prefixIcon: Icon(Icons.map),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleBecomeShipper();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text("Xác nhận"),
          ),
        ],
      ),
    );
  }

  void _handleBecomeShipper() async {
    final provider = Provider.of<AuthProvider>(context, listen: false);
    final user = provider.user;

    if (user == null) return;
    if (_phoneCtrl.text.isEmpty || _addressCtrl.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Vui lòng nhập đủ thông tin!")));
      return;
    }

    try {
      // Gọi API đổi role
      var newUserJson = await _api.becomeShipper(
        user.id,
        _phoneCtrl.text,
        _addressCtrl.text,
      );

      // Cập nhật lại Provider
      provider.setUser(newUserJson);

      // Chuyển hướng sang giao diện Shipper ngay lập tức
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => ShipperHomeScreen()),
        (Route<dynamic> route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Chúc mừng! Bạn đã trở thành Shipper.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  // --- LOGIC 2: ĐĂNG XUẤT ---
  void _handleLogout() {
    // 1. Xóa thông tin User
    Provider.of<AuthProvider>(context, listen: false).logout();

    // 2. Xóa giỏ hàng trên RAM
    Provider.of<CartProvider>(context, listen: false).clear();

    // 3. Quay về màn hình Login
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (ctx) => LoginScreen()),
      (route) => false,
    );
  }

  // --- GIAO DIỆN CHÍNH ---
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      backgroundColor: Colors.grey[100], // Nền xám nhẹ tạo khối
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. HEADER PROFILE
            Container(
              padding: EdgeInsets.fromLTRB(20, 60, 20, 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue.shade700, Colors.blue.shade400],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.blue.shade700,
                    ),
                    // Nếu có avatar thật: backgroundImage: NetworkImage(user?.avatar ?? ""),
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? "Khách hàng",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 5),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            user?.role ?? "Thành viên",
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. KHU VỰC "ĐƠN HÀNG CỦA TÔI"
            Container(
              margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Tiêu đề + Xem lịch sử
                  ListTile(
                    title: Text(
                      "Đơn hàng của tôi",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Xem lịch sử mua hàng",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                      ],
                    ),
                    onTap: () {
                      // Mở Tab Lịch sử (Index 1)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MyOrdersScreen(initialIndex: 1),
                        ),
                      );
                    },
                  ),
                  Divider(height: 1, indent: 15, endIndent: 15),

                  // Các nút trạng thái (Status Bar)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatusIcon(
                          Icons.inventory_2_outlined,
                          "Chờ xác nhận",
                          () {
                            // Mở Tab Đang xử lý (Index 0)
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MyOrdersScreen(initialIndex: 0),
                              ),
                            );
                          },
                        ),
                        _buildStatusIcon(
                          Icons.local_shipping_outlined,
                          "Đang giao",
                          () {
                            // Mở Tab Đang xử lý (Index 0)
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MyOrdersScreen(initialIndex: 0),
                              ),
                            );
                          },
                        ),
                        _buildStatusIcon(Icons.star_outline, "Đánh giá", () {
                          // Mở Tab Lịch sử/Đánh giá (Index 1)
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MyOrdersScreen(initialIndex: 1),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 3. CÁC TÙY CHỌN KHÁC
            Container(
              margin: EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Chỉ hiện nút này nếu là Customer
                  if (user?.role == "Customer")
                    ListTile(
                      leading: Icon(Icons.motorcycle, color: Colors.orange),
                      title: Text(
                        "Đăng ký làm Shipper",
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: _showShipperDialog,
                    ),
                  if (user?.role == "Customer") Divider(height: 1, indent: 60),

                  ListTile(
                    leading: Icon(
                      Icons.settings_outlined,
                      color: Colors.grey[700],
                    ),
                    title: Text("Thiết lập tài khoản"),
                    trailing: Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () {},
                  ),
                  Divider(height: 1, indent: 60),
                  ListTile(
                    leading: Icon(Icons.help_outline, color: Colors.grey[700]),
                    title: Text("Trung tâm trợ giúp"),
                    trailing: Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () {},
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            // 4. NÚT ĐĂNG XUẤT
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _handleLogout,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.all(15),
                    side: BorderSide(color: Colors.grey.shade300),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text("Đăng xuất", style: TextStyle(color: Colors.red)),
                ),
              ),
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Widget con: Icon trạng thái đơn hàng
  Widget _buildStatusIcon(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 28, color: Colors.black54),
          SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.black87)),
        ],
      ),
    );
  }
}
