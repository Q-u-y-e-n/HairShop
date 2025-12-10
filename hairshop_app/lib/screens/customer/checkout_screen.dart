import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import 'my_orders_screen.dart'; // Màn hình lịch sử đơn hàng

class CheckoutScreen extends StatefulWidget {
  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController(); // Controller cho SĐT
  String _paymentMethod = "COD";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Tự động điền thông tin có sẵn của User
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _addressController.text = user.address ?? "";
      _phoneController.text = user.phone ?? "";
    }
  }

  void _handleCheckout() async {
    if (_addressController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Vui lòng nhập địa chỉ và số điện thoại")),
      );
      return;
    }

    setState(() => _isLoading = true);
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final cart = Provider.of<CartProvider>(context, listen: false);

    // GỌI HÀM THANH TOÁN (KÈM SĐT)
    bool success = await cart.clearAndCreateOrder(
      user!.id,
      _addressController.text,
      _phoneController.text, // <--- Lấy text từ ô nhập liệu
      _paymentMethod,
    );

    setState(() => _isLoading = false);

    if (success) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text("Thành công!"),
          content: Text("Đơn hàng của bạn đã được đặt."),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(ctx).pop(); // Đóng dialog
                Navigator.of(context).pop(); // Đóng checkout
                // Chuyển sang màn hình đơn hàng
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => MyOrdersScreen()));
              },
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đặt hàng thất bại. Vui lòng thử lại.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      appBar: AppBar(
        title: Text("Thanh toán"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Ô NHẬP SỐ ĐIỆN THOẠI
            Text(
              "Số điện thoại nhận hàng",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Nhập số điện thoại...",
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            SizedBox(height: 15),

            // 2. Ô NHẬP ĐỊA CHỈ
            Text(
              "Địa chỉ giao hàng",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            TextField(
              controller: _addressController,
              maxLines: 2,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Số nhà, đường, phường, quận...",
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            SizedBox(height: 20),

            // 3. TÓM TẮT ĐƠN HÀNG
            Text(
              "Tóm tắt đơn hàng",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Divider(),
            ...cart.items.values
                .map(
                  (item) => ListTile(
                    title: Text(item.title),
                    subtitle: Text("x${item.quantity}"),
                    trailing: Text(currency.format(item.price * item.quantity)),
                  ),
                )
                .toList(),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Tổng cộng:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  currency.format(cart.totalAmount),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            SizedBox(height: 30),

            // 4. NÚT ĐẶT HÀNG
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleCheckout,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "XÁC NHẬN ĐẶT HÀNG",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
