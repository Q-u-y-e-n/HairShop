import 'package:flutter/material.dart';
import 'shipper_orders_screen.dart';
import 'shipper_account_screen.dart';

class ShipperMainScreen extends StatefulWidget {
  @override
  _ShipperMainScreenState createState() => _ShipperMainScreenState();
}

class _ShipperMainScreenState extends State<ShipperMainScreen> {
  int _currentIndex = 0;

  // Danh sách các màn hình con
  final List<Widget> _screens = [
    ShipperOrdersScreen(), // Tab 0: Đơn hàng
    ShipperAccountScreen(), // Tab 1: Tài khoản
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Hiển thị màn hình tương ứng với index đang chọn
      body: _screens[_currentIndex],

      // Thanh điều hướng dưới đáy
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          selectedItemColor: Colors.orange,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.local_shipping_outlined),
              activeIcon: Icon(Icons.local_shipping),
              label: "Đơn hàng",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: "Tài khoản",
            ),
          ],
        ),
      ),
    );
  }
}
