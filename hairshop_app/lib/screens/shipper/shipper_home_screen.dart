import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';

class ShipperHomeScreen extends StatefulWidget {
  @override
  _ShipperHomeScreenState createState() => _ShipperHomeScreenState();
}

class _ShipperHomeScreenState extends State<ShipperHomeScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      var list = await _api.getShipperOrders(user.id);
      setState(() => _orders = list);
    }
  }

  void _updateStatus(int orderId, int newStatus) async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    bool success = await _api.updateOrderStatus(orderId, newStatus, user!.id);
    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Cập nhật thành công!")));
      _loadOrders(); // Tải lại danh sách
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Đơn cần giao"),
        backgroundColor: Colors.orange,
      ),
      body: ListView.builder(
        itemCount: _orders.length,
        itemBuilder: (ctx, i) {
          final order = _orders[i];
          return Card(
            margin: EdgeInsets.all(10),
            child: Padding(
              padding: EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Đơn #${order['id']} - ${order['statusName']}",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 5),
                  Text("Khách: ${order['customerName']} - ${order['phone']}"),
                  Text(
                    "Đia chỉ: ${order['address']}",
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  Text(
                    "Tổng tiền: ${order['totalAmount']} đ",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (order['statusId'] == 1) // Confirmed -> Start Ship
                        ElevatedButton.icon(
                          icon: Icon(Icons.motorcycle),
                          label: Text("Giao hàng"),
                          onPressed: () =>
                              _updateStatus(order['id'], 2), // 2 = Shipping
                        ),
                      if (order['statusId'] == 2) // Shipping -> Complete
                        Row(
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              onPressed: () => _updateStatus(
                                order['id'],
                                3,
                              ), // 3 = Completed
                              child: Text("Thành công"),
                            ),
                            SizedBox(width: 10),
                            OutlinedButton(
                              onPressed: () => _updateStatus(
                                order['id'],
                                4,
                              ), // 4 = Cancelled
                              child: Text("Thất bại"),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
