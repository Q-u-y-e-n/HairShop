import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'order_detail_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  final int initialIndex; // 0: Đang xử lý, 1: Lịch sử
  const MyOrdersScreen({this.initialIndex = 0});

  @override
  _MyOrdersScreenState createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();
  List<dynamic> _allOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Khởi tạo TabController với index được truyền vào
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
    _loadOrders();
  }

  void _loadOrders() async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      try {
        var list = await _api.getHistory(user.id);
        setState(() {
          _allOrders = list;
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- PHÂN LOẠI ĐƠN HÀNG ---
    // Tab 1: Đơn hàng của tôi (Chưa thành công)
    final activeOrders = _allOrders
        .where(
          (o) =>
              o['status'] == 'Pending' ||
              o['status'] == 'Confirmed' ||
              o['status'] == 'Shipping',
        )
        .toList();

    // Tab 2: Lịch sử mua hàng (Chỉ đơn thành công hoặc đã hủy)
    final historyOrders = _allOrders
        .where((o) => o['status'] == 'Completed' || o['status'] == 'Cancelled')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("Đơn hàng của tôi"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: [
            Tab(text: "Đang xử lý (${activeOrders.length})"),
            Tab(text: "Lịch sử mua (${historyOrders.length})"),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(activeOrders, isHistory: false),
                _buildOrderList(historyOrders, isHistory: true),
              ],
            ),
    );
  }

  Widget _buildOrderList(List<dynamic> orders, {required bool isHistory}) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 60, color: Colors.grey[300]),
            SizedBox(height: 10),
            Text(
              isHistory
                  ? "Chưa có lịch sử mua hàng"
                  : "Không có đơn hàng nào đang chạy",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(12),
      itemCount: orders.length,
      itemBuilder: (ctx, i) {
        final order = orders[i];
        final currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

        // Màu trạng thái
        Color statusColor = Colors.grey;
        String statusText = "";
        IconData statusIcon = Icons.info;

        switch (order['status']) {
          case 'Pending':
            statusColor = Colors.orange;
            statusText = "Chờ xác nhận";
            statusIcon = Icons.hourglass_empty;
            break;
          case 'Confirmed':
            statusColor = Colors.blue;
            statusText = "Đã xác nhận";
            statusIcon = Icons.thumb_up;
            break;
          case 'Shipping':
            statusColor = Colors.blue;
            statusText = "Đang giao hàng";
            statusIcon = Icons.local_shipping;
            break;
          case 'Completed':
            statusColor = Colors.green;
            statusText = "Giao thành công";
            statusIcon = Icons.check_circle;
            break;
          case 'Cancelled':
            statusColor = Colors.red;
            statusText = "Đã hủy";
            statusIcon = Icons.cancel;
            break;
        }

        return Card(
          elevation: 2,
          margin: EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderDetailScreen(orderId: order['id']),
              ),
            ),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: EdgeInsets.all(15),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(statusIcon, size: 18, color: statusColor),
                      SizedBox(width: 8),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                      Text(
                        "Mã: #${order['id']}",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${order['itemCount']} sản phẩm",
                        style: TextStyle(color: Colors.black54),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "Thành tiền",
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                          Text(
                            currency.format(order['totalAmount']),
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
