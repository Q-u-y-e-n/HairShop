import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class CheckoutScreen extends StatefulWidget {
  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String _paymentMethod = "COD"; // Mặc định tiền mặt
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Tự động điền thông tin user nếu có
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user != null) {
      _nameCtrl.text = user.fullName;
    }
  }

  void _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final cart = Provider.of<CartProvider>(context, listen: false);
    final user = Provider.of<AuthProvider>(context, listen: false).user;

    setState(() => _isLoading = true);

    // Chuẩn bị dữ liệu
    var orderData = {
      "userId": user!.id,
      "fullName": _nameCtrl.text,
      "phone": _phoneCtrl.text,
      "address": _addressCtrl.text,
      "paymentMethod": _paymentMethod,
      "items": cart.items.values
          .map(
            (item) => {
              "productId": int.parse(item.id),
              "quantity": item.quantity,
              "price": item.price,
            },
          )
          .toList(),
    };

    try {
      bool success = await ApiService().createOrder(orderData);
      if (success) {
        cart.clear(); // Xóa giỏ hàng
        if (!mounted) return;

        // Hiện thông báo và quay về trang chủ
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Icon(Icons.check_circle, color: Colors.green, size: 50),
            content: Text("Đặt hàng thành công! Mã đơn hàng đã được tạo."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx); // Tắt dialog
                  Navigator.pop(ctx); // Tắt màn checkout
                },
                child: Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      appBar: AppBar(title: Text("Thanh Toán")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(15),
          children: [
            // 1. Thông tin giao hàng
            Text(
              "📍 Thông tin nhận hàng",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: "Họ tên người nhận",
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? "Không được để trống" : null,
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: _phoneCtrl,
              decoration: InputDecoration(
                labelText: "Số điện thoại",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (v) => v!.length < 9 ? "SĐT không hợp lệ" : null,
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: _addressCtrl,
              decoration: InputDecoration(
                labelText: "Địa chỉ giao hàng",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (v) => v!.isEmpty ? "Vui lòng nhập địa chỉ" : null,
            ),

            SizedBox(height: 20),
            // 2. Phương thức thanh toán
            Text(
              "💳 Phương thức thanh toán",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            RadioListTile(
              title: Text("Thanh toán khi nhận hàng (COD)"),
              value: "COD",
              groupValue: _paymentMethod,
              onChanged: (val) =>
                  setState(() => _paymentMethod = val.toString()),
            ),
            RadioListTile(
              title: Text("Chuyển khoản ngân hàng"),
              value: "Banking",
              groupValue: _paymentMethod,
              onChanged: (val) =>
                  setState(() => _paymentMethod = val.toString()),
            ),

            SizedBox(height: 20),
            // 3. Tóm tắt
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Tổng thanh toán:", style: TextStyle(fontSize: 16)),
                Text(
                  currency.format(cart.totalAmount),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Nút Đặt hàng
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitOrder,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text("ĐẶT HÀNG NGAY"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
