import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'screens/auth/login_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        // 1. Provider quản lý Đăng nhập
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // 2. Provider quản lý Giỏ hàng
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MyApp(), // Gọi class MyApp ở đây
    ),
  );
}

// --- BẠN ĐANG THIẾU ĐOẠN CODE NÀY ---
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HairCare App',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      // Màn hình đầu tiên khi mở App là màn hình Đăng nhập
      home: LoginScreen(),
    );
  }
}
