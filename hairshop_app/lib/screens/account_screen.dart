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

  // --- BIẾN ĐỂ LƯU SỐ LƯỢNG ĐƠN HÀNG ---
  int _pendingCount = 0; // Chờ xác nhận
  int _shippingCount = 0; // Đang giao
  int _reviewCount = 0; // Chờ đánh giá (Hoặc đã hoàn thành)

  @override
  void initState() {
    super.initState();
    _loadOrderCounts(); // Tải số lượng ngay khi vào màn hình
  }

  // Hàm tải và đếm đơn hàng
  void _loadOrderCounts() async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;

    try {
      // Gọi API lấy toàn bộ lịch sử
      var orders = await _api.getHistory(user.id);

      int pCount = 0;
      int sCount = 0;
      int rCount = 0;

      for (var o in orders) {
        String status = o['status'];
        // Logic đếm tương ứng với Logic phân loại bên MyOrdersScreen
        if (status == 'Pending' || status == 'Confirmed') {
          pCount++;
        } else if (status == 'Shipping') {
          sCount++;
        } else if (status == 'Completed') {
          // Bạn có thể lọc thêm điều kiện "chưa đánh giá" nếu API hỗ trợ
          // Tạm thời đếm các đơn đã hoàn thành
          rCount++;
        }
      }

      if (mounted) {
        setState(() {
          _pendingCount = pCount;
          _shippingCount = sCount;
          _reviewCount = rCount;
        });
      }
    } catch (e) {
      print("Lỗi đếm đơn hàng: $e");
    }
  }

  // --- CÁC HÀM CŨ (Đăng ký Shipper, Logout...) GIỮ NGUYÊN ---
  void _showShipperDialog() {
    /* ... Code cũ ... */
  }
  void _handleBecomeShipper() async {
    /* ... Code cũ ... */
  }

  void _handleLogout() {
    Provider.of<AuthProvider>(context, listen: false).logout();
    Provider.of<CartProvider>(context, listen: false).clear();
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
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. HEADER PROFILE (Giữ nguyên)
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

            // 2. KHU VỰC "ĐƠN HÀNG CỦA TÔI" (Cập nhật Badge)
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
                    onTap: () async {
                      // Dùng await để khi quay lại thì reload số lượng
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MyOrdersScreen(initialIndex: 1),
                        ),
                      );
                      _loadOrderCounts();
                    },
                  ),
                  Divider(height: 1, indent: 15, endIndent: 15),

                  // Các nút trạng thái (Status Bar)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildBadgeStatusIcon(
                          Icons.inventory_2_outlined,
                          "Chờ xác nhận",
                          _pendingCount, // Truyền số lượng
                          () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MyOrdersScreen(initialIndex: 0),
                              ),
                            );
                            _loadOrderCounts();
                          },
                        ),
                        _buildBadgeStatusIcon(
                          Icons.local_shipping_outlined,
                          "Đang giao",
                          _shippingCount, // Truyền số lượng
                          () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MyOrdersScreen(initialIndex: 0),
                              ),
                            );
                            _loadOrderCounts();
                          },
                        ),
                        _buildBadgeStatusIcon(
                          Icons.star_outline,
                          "Đánh giá",
                          _reviewCount, // Truyền số lượng
                          () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MyOrdersScreen(initialIndex: 1),
                              ),
                            );
                            _loadOrderCounts();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 3. CÁC TÙY CHỌN KHÁC (Giữ nguyên)
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

            // 4. NÚT ĐĂNG XUẤT (Giữ nguyên)
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

  // --- WIDGET ICON CÓ BADGE (SỐ LƯỢNG) ---
  Widget _buildBadgeStatusIcon(
    IconData icon,
    String label,
    int count,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none, // Để badge có thể trồi ra ngoài
        children: [
          // Icon chính
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Column(
              children: [
                Icon(icon, size: 28, color: Colors.black54),
                SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ],
            ),
          ),

          // Badge số lượng (Chỉ hiện khi count > 0)
          if (count > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 1.5,
                  ), // Viền trắng cho nổi
                ),
                constraints: BoxConstraints(minWidth: 18, minHeight: 18),
                child: Center(
                  child: Text(
                    count > 9 ? "9+" : "$count",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
