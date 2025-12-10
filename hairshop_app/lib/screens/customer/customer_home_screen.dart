// customer_home_screen.dart
import 'package:flutter/material.dart';
import 'customer_product_tab.dart'; // Tách phần Grid sản phẩm ra file riêng cho gọn
import 'cart_screen.dart'; // Màn hình giỏ hàng
import '../account_screen.dart'; // Màn hình tài khoản vừa tạo

class CustomerHomeScreen extends StatefulWidget {
  @override
  _CustomerHomeScreenState createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _selectedIndex = 0;

  // Danh sách các màn hình tương ứng với Tab
  final List<Widget> _screens = [
    CustomerProductTab(), // Tab 0: Trang chủ
    CartScreen(), // Tab 1: Giỏ hàng (Bạn tự tạo nhé)
    AccountScreen(), // Tab 2: Tài khoản & ĐK Shipper
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("HairCare Shop"),
        backgroundColor: Colors.blue,
      ),
      body: _screens[_selectedIndex], // Hiển thị màn hình theo index
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Sản phẩm"),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: "Giỏ hàng",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Tài khoản"),
        ],
      ),
    );
  }
}
