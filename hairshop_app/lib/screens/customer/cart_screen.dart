import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/cart_provider.dart';
import '../../services/api_service.dart';
import 'checkout_screen.dart';
import 'customer_home_screen.dart';

class CartScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Lắng nghe thay đổi từ CartProvider
    final cart = Provider.of<CartProvider>(context);
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    // Chuyển Map thành List và sắp xếp theo tên
    final cartItems = cart.items.values.toList();
    cartItems.sort((a, b) => a.title.compareTo(b.title));

    return Scaffold(
      backgroundColor: Colors.grey[50], // Nền sáng sạch sẽ
      appBar: AppBar(
        title: Text(
          "Giỏ hàng (${cart.itemCount})",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // 1. DANH SÁCH SẢN PHẨM
          Expanded(
            child: cartItems.isEmpty
                ? _buildEmptyState(context)
                : ListView.separated(
                    padding: EdgeInsets.all(15),
                    itemCount: cartItems.length,
                    separatorBuilder: (ctx, i) => SizedBox(height: 15),
                    itemBuilder: (ctx, i) =>
                        _buildCartItem(context, cartItems[i], currency),
                  ),
          ),

          // 2. THANH THANH TOÁN (Chỉ hiện khi có hàng)
          if (cartItems.isNotEmpty)
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Tổng thanh toán:",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          currency.format(cart.totalAmount),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => CheckoutScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          "TIẾN HÀNH ĐẶT HÀNG",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Widget hiển thị khi giỏ trống
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.orange,
            ),
          ),
          SizedBox(height: 20),
          Text(
            "Giỏ hàng của bạn đang trống",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            "Hãy thêm sản phẩm yêu thích vào đây nhé!",
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => CustomerHomeScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            ),
            child: Text(
              "TIẾP TỤC MUA SẮM",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Widget hiển thị từng món hàng
  Widget _buildCartItem(BuildContext context, var item, NumberFormat currency) {
    // Xử lý đường dẫn ảnh (Quan trọng)
    String domain = ApiService.baseUrl.replaceAll("/api", "");
    String imgUrl = (item.imageUrl != null && item.imageUrl!.startsWith("http"))
        ? item.imageUrl!
        : domain + (item.imageUrl ?? "");

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        padding: EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red[100],
          borderRadius: BorderRadius.circular(15),
        ),
        alignment: Alignment.centerRight,
        child: Icon(Icons.delete_outline, color: Colors.red, size: 30),
      ),
      onDismissed: (_) {
        Provider.of<CartProvider>(context, listen: false).removeItem(item.id);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(10),
        child: Row(
          children: [
            // ẢNH SẢN PHẨM
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  imgUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) =>
                      Icon(Icons.image, color: Colors.grey[300]),
                ),
              ),
            ),
            SizedBox(width: 15),

            // THÔNG TIN
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 5),
                  Text(
                    currency.format(item.price),
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),

                  // BỘ ĐIỀU KHIỂN SỐ LƯỢNG
                  Row(
                    children: [
                      _qtyBtn(Icons.remove, () {
                        Provider.of<CartProvider>(
                          context,
                          listen: false,
                        ).removeSingleItem(item.id);
                      }),
                      Container(
                        constraints: BoxConstraints(minWidth: 35),
                        alignment: Alignment.center,
                        child: Text(
                          "${item.quantity}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      _qtyBtn(Icons.add, () {
                        Provider.of<CartProvider>(
                          context,
                          listen: false,
                        ).addItem(
                          int.parse(item.id),
                          item.price,
                          item.title,
                          item.imageUrl,
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        padding: EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(icon, size: 16, color: Colors.grey[800]),
      ),
    );
  }
}
