import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import 'shipper_order_detail_screen.dart';

class ShipperHomeScreen extends StatefulWidget {
  @override
  _ShipperHomeScreenState createState() => _ShipperHomeScreenState();
}

class _ShipperHomeScreenState extends State<ShipperHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // Hàm đăng xuất
  void _handleLogout() {
    Provider.of<AuthProvider>(context, listen: false).logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Kênh Shipper",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: _handleLogout,
            tooltip: "Đăng xuất",
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: "CẦN LẤY HÀNG"), // Tab 0: Confirmed (Chưa ai nhận)
            Tab(text: "ĐANG GIAO"), // Tab 1: Shipping (Của tôi)
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildOrderList("Confirmed"), _buildOrderList("Shipping")],
      ),
    );
  }

  // Widget hiển thị danh sách đơn hàng
  Widget _buildOrderList(String status) {
    // 1. Lấy thông tin Shipper đang đăng nhập
    final user = Provider.of<AuthProvider>(context, listen: false).user;

    // Nếu chưa đăng nhập hoặc lỗi user -> Báo lỗi
    if (user == null)
      return Center(child: Text("Lỗi: Không tìm thấy thông tin tài khoản"));

    return FutureBuilder<List<dynamic>>(
      // 2. Gọi API kèm theo ID của Shipper
      future: _api.getOrdersByStatus(status, user.id),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 40),
                SizedBox(height: 10),
                Text("Lỗi tải dữ liệu", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        final orders = snapshot.data ?? [];
        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  status == "Confirmed"
                      ? Icons.inventory_2_outlined
                      : Icons.local_shipping_outlined,
                  size: 60,
                  color: Colors.grey[300],
                ),
                SizedBox(height: 10),
                Text(
                  status == "Confirmed"
                      ? "Hiện không có đơn mới nào"
                      : "Bạn chưa nhận đơn nào",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

        return RefreshIndicator(
          onRefresh: () async => setState(() {}), // Kéo xuống để tải lại
          child: ListView.builder(
            padding: EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (ctx, i) {
              final order = orders[i];
              return Card(
                elevation: 3,
                margin: EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () async {
                    // Chuyển sang chi tiết
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShipperOrderDetailScreen(
                          orderId: order['id'],
                          currentStatus: status,
                        ),
                      ),
                    );
                    // Khi quay lại thì reload danh sách (để cập nhật đơn đã nhận/đã giao)
                    setState(() {});
                  },
                  child: Padding(
                    padding: EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Đơn #${order['id']}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: status == "Confirmed"
                                    ? Colors.blue.shade50
                                    : Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                status == "Confirmed" ? "Chờ lấy" : "Đang giao",
                                style: TextStyle(
                                  color: status == "Confirmed"
                                      ? Colors.blue
                                      : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Divider(),
                        Row(
                          children: [
                            Icon(Icons.person, size: 16, color: Colors.grey),
                            SizedBox(width: 5),
                            Text(
                              order['customerName'],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.red,
                            ),
                            SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                order['address'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Thu hộ: ${currency.format(order['totalAmount'])}",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
