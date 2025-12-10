import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';

class OrderHistoryScreen extends StatefulWidget {
  @override
  _OrderHistoryScreenState createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      try {
        var list = await _api.getHistory(
          user.id,
        ); // Cần đảm bảo hàm này có trong ApiService
        setState(() {
          _orders = list;
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
        print(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lịch sử đơn hàng"),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _orders.isEmpty
          ? Center(child: Text("Bạn chưa có đơn hàng nào."))
          : ListView.builder(
              itemCount: _orders.length,
              itemBuilder: (ctx, i) {
                final o = _orders[i];
                return Card(
                  margin: EdgeInsets.all(10),
                  child: ListTile(
                    leading: Icon(Icons.shopping_bag, color: Colors.blue),
                    title: Text("Đơn #${o['id']} - ${o['orderDate']}"),
                    subtitle: Text(
                      "${o['status']}",
                      style: TextStyle(
                        color: o['status'] == 'Pending'
                            ? Colors.orange
                            : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: Text(
                      "${o['totalAmount']} đ",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
