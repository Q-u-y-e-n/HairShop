import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart'; // Đảm bảo bạn có file model này
import '../../services/api_service.dart';
import '../../providers/cart_provider.dart';
import 'cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product; // Nhận dữ liệu sản phẩm từ màn hình trước

  const ProductDetailScreen({required this.product});

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ApiService _api = ApiService();
  late Future<List<dynamic>> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    // Gọi API lấy đánh giá ngay khi mở màn hình
    _reviewsFuture = _api.getProductReviews(widget.product.id);
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    // Xử lý ảnh sản phẩm (Nối domain nếu cần)
    String domain = ApiService.baseUrl.replaceAll("/api", "");
    String mainImgUrl =
        (widget.product.imageUrl != null &&
            widget.product.imageUrl!.startsWith("http"))
        ? widget.product.imageUrl!
        : domain + (widget.product.imageUrl ?? "");

    return Scaffold(
      appBar: AppBar(
        title: Text("Chi tiết sản phẩm"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          // Nút giỏ hàng trên góc phải
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CartScreen()),
                ),
              ),
              Positioned(
                right: 5,
                top: 5,
                child: Consumer<CartProvider>(
                  builder: (ctx, cart, ch) => cart.itemCount > 0
                      ? CircleAvatar(
                          radius: 8,
                          backgroundColor: Colors.red,
                          child: Text(
                            "${cart.itemCount}",
                            style: TextStyle(fontSize: 10, color: Colors.white),
                          ),
                        )
                      : Container(),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. ẢNH SẢN PHẨM LỚN
                  Container(
                    height: 300,
                    width: double.infinity,
                    color: Colors.white,
                    child: Image.network(
                      mainImgUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) => Icon(
                        Icons.image_not_supported,
                        size: 100,
                        color: Colors.grey,
                      ),
                    ),
                  ),

                  // 2. THÔNG TIN CƠ BẢN
                  Container(
                    padding: EdgeInsets.all(15),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.brand?.toUpperCase() ?? "KHÁC",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        SizedBox(height: 5),
                        Text(
                          widget.product.name,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          currency.format(widget.product.price),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        SizedBox(height: 15),
                        Text(
                          "Mô tả sản phẩm:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          // Hiển thị mô tả từ API, nếu null hoặc rỗng thì hiện thông báo mặc định
                          (widget.product.description != null &&
                                  widget.product.description!.isNotEmpty)
                              ? widget.product.description!
                              : "Hiện chưa có mô tả chi tiết cho sản phẩm này.",
                          style: TextStyle(
                            color: Colors.grey[800],
                            height: 1.5,
                            fontSize: 15,
                          ),
                          textAlign:
                              TextAlign.justify, // Canh đều 2 bên cho đẹp
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),

                  // 3. DANH SÁCH ĐÁNH GIÁ (REVIEW)
                  Container(
                    color: Colors.white,
                    padding: EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Đánh giá từ khách hàng",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Divider(),
                        FutureBuilder<List<dynamic>>(
                          future: _reviewsFuture,
                          builder: (ctx, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting)
                              return Center(child: CircularProgressIndicator());
                            if (snapshot.hasError)
                              return Text("Lỗi tải đánh giá");

                            final reviews = snapshot.data ?? [];
                            if (reviews.isEmpty)
                              return Padding(
                                padding: EdgeInsets.all(20),
                                child: Center(
                                  child: Text("Chưa có đánh giá nào."),
                                ),
                              );

                            return Column(
                              children: reviews.map((r) {
                                // Xử lý ảnh review
                                String? reviewImg = r['image'];
                                if (reviewImg != null &&
                                    !reviewImg.startsWith("http"))
                                  reviewImg = domain + reviewImg;

                                return Container(
                                  margin: EdgeInsets.only(bottom: 15),
                                  padding: EdgeInsets.only(bottom: 15),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        child: Text(r['userName'][0]),
                                        backgroundColor: Colors.blue.shade100,
                                        radius: 20,
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  r['userName'],
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  r['date'],
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            // Số sao
                                            Row(
                                              children: List.generate(
                                                5,
                                                (index) => Icon(
                                                  index < r['rating']
                                                      ? Icons.star
                                                      : Icons.star_border,
                                                  size: 14,
                                                  color: Colors.orange,
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: 5),
                                            Text(r['comment']),

                                            // Ảnh thực tế (nếu có)
                                            if (reviewImg != null)
                                              Padding(
                                                padding: EdgeInsets.only(
                                                  top: 8,
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: Image.network(
                                                    reviewImg,
                                                    width: 80,
                                                    height: 80,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // 4. THANH MUA HÀNG (STICKY BOTTOM)
          Container(
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.add_shopping_cart, color: Colors.white),
                  label: Text(
                    "THÊM VÀO GIỎ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Provider.of<CartProvider>(context, listen: false).addItem(
                      widget.product.id,
                      widget.product.price,
                      widget.product.name,
                      widget.product.imageUrl,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Đã thêm vào giỏ!"),
                        duration: Duration(milliseconds: 500),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
