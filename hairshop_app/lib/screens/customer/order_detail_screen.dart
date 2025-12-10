import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import 'add_review_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  const OrderDetailScreen({required this.orderId});

  @override
  _OrderDetailScreenState createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Map<String, dynamic>? _order;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  void _loadDetail() async {
    try {
      var data = await ApiService().getOrderDetail(widget.orderId);
      setState(() {
        _order = data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return Scaffold(
        appBar: AppBar(title: Text("Chi tiết")),
        body: Center(child: CircularProgressIndicator()),
      );
    if (_order == null)
      return Scaffold(
        appBar: AppBar(title: Text("Lỗi")),
        body: Center(child: Text("Lỗi tải đơn hàng")),
      );

    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    String status = _order!['status'];
    bool isCompleted = status == "Completed";
    var items = _order!['items'] as List;

    String domain = ApiService.baseUrl.replaceAll("/api", "");

    return Scaffold(
      appBar: AppBar(
        title: Text("Thông tin đơn hàng"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      // --- SỬA 1: Bọc body trong SafeArea ---
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Trạng thái
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCompleted ? Icons.check_circle : Icons.local_shipping,
                      color: Colors.blue,
                    ),
                    SizedBox(width: 10),
                    Text(
                      "Trạng thái: $status",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              // 2. Địa chỉ
              Text(
                "Địa chỉ nhận hàng",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5),
              Text("${_order!['customerName']} - ${_order!['phone']}"),
              Text(
                _order!['address'] ?? "---",
                style: TextStyle(color: Colors.grey[700]),
              ),
              Divider(height: 30),

              // 3. Danh sách sản phẩm
              Text("Sản phẩm", style: TextStyle(fontWeight: FontWeight.bold)),
              ...items.map((item) {
                String imgUrl =
                    (item['imageUrl'] != null &&
                        item['imageUrl'].startsWith("http"))
                    ? item['imageUrl']
                    : domain + (item['imageUrl'] ?? "");

                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imgUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) =>
                                      Icon(Icons.image, color: Colors.grey),
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['productName'],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "x${item['quantity']}",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              currency.format(item['price']),
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),

                        // NÚT ĐÁNH GIÁ (Chỉ hiện khi đơn hàng Completed)
                        if (isCompleted)
                          Padding(
                            padding: EdgeInsets.only(top: 10),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                icon: Icon(
                                  Icons.star_rate,
                                  size: 18,
                                  color: Colors.orange,
                                ),
                                label: Text(
                                  "Đánh giá sản phẩm",
                                  style: TextStyle(color: Colors.orange),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.orange),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddReviewScreen(
                                        orderId: widget.orderId,
                                        productId: item['productId'],
                                        productName: item['productName'],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),

              Divider(height: 30, thickness: 1),

              // 4. Tổng tiền (ĐÃ SỬA: Làm to và rõ ràng hơn)
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Tổng thanh toán:",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[900],
                      ),
                    ),
                    Text(
                      currency.format(_order!['total']),
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // --- SỬA 2: Thêm khoảng trống lớn ở dưới đáy ---
              SizedBox(
                height: 50,
              ), // Đẩy nội dung lên 50px để tránh bị nút home che
            ],
          ),
        ),
      ),
    );
  }
}
