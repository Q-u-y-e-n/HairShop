import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import 'shipper_order_detail_screen.dart';

class ShipperOrdersScreen extends StatefulWidget {
  @override
  _ShipperOrdersScreenState createState() => _ShipperOrdersScreenState();
}

class _ShipperOrdersScreenState extends State<ShipperOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // Hàm reload (để màn hình cha gọi khi cần)
  void refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Đơn hàng", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Tắt nút back mặc định
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: TextStyle(fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: "CẦN LẤY"),
            Tab(text: "ĐANG GIAO"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildOrderList("Confirmed"), _buildOrderList("Shipping")],
      ),
    );
  }

  Widget _buildOrderList(String status) {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return Center(child: Text("Lỗi user"));

    return FutureBuilder<List<dynamic>>(
      future: _api.getOrdersByStatus(status, user.id),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return Center(child: CircularProgressIndicator());

        final orders = snapshot.data ?? [];
        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 60, color: Colors.grey[300]),
                Text("Không có đơn hàng", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        final currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            padding: EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (ctx, i) {
              final order = orders[i];
              return Card(
                elevation: 3,
                margin: EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShipperOrderDetailScreen(
                          orderId: order['id'],
                          currentStatus: status,
                        ),
                      ),
                    );
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
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              currency.format(order['totalAmount']),
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Divider(),
                        Text(
                          "📍 ${order['address']}",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
