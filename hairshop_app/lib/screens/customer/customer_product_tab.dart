import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// Import các file cần thiết
import '../../services/api_service.dart';
import '../../providers/cart_provider.dart';
import '../../models/product_model.dart';
import 'product_detail_screen.dart'; // Import màn hình chi tiết mới tạo

class CustomerProductTab extends StatefulWidget {
  @override
  _CustomerProductTabState createState() => _CustomerProductTabState();
}

class _CustomerProductTabState extends State<CustomerProductTab> {
  final ApiService _api = ApiService();

  // Danh sách sản phẩm và trạng thái tải
  List<Product> _products = [];
  bool _isLoading = true;

  // Controller tìm kiếm
  final _searchCtrl = TextEditingController();

  // ID danh mục đang chọn (0 = Tất cả)
  int _selectedCategoryId = 0;

  // Danh mục cứng (Hoặc bạn có thể gọi API lấy danh mục về nếu muốn)
  final List<Map<String, dynamic>> _categories = [
    {'id': 0, 'name': 'Tất cả'},
    {'id': 1, 'name': 'Dầu gội'},
    {'id': 2, 'name': 'Dầu xả'},
    {'id': 3, 'name': 'Tạo kiểu'},
    {'id': 4, 'name': 'Dưỡng tóc'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Hàm gọi API lấy sản phẩm
  void _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Gọi API kèm từ khóa tìm kiếm và ID danh mục
      var listJson = await _api.getProducts(
        search: _searchCtrl.text,
        categoryId: _selectedCategoryId,
      );

      setState(() {
        _products = listJson.map((json) => Product.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print("Lỗi tải sản phẩm: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. HEADER TÌM KIẾM
        Container(
          padding: EdgeInsets.fromLTRB(15, 10, 15, 15),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Tìm kiếm sản phẩm",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              SizedBox(height: 5),
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: "Nhập tên sản phẩm...",
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search, color: Colors.blue),
                    onPressed: _loadData, // Bấm kính lúp để tìm
                  ),
                ),
                onSubmitted: (_) =>
                    _loadData(), // Bấm Enter trên bàn phím để tìm
              ),
            ],
          ),
        ),

        // 2. THANH DANH MỤC (Trượt ngang)
        Container(
          height: 50,
          margin: EdgeInsets.symmetric(vertical: 10),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 10),
            itemCount: _categories.length,
            itemBuilder: (ctx, i) {
              final cat = _categories[i];
              bool isSelected = cat['id'] == _selectedCategoryId;
              return Padding(
                padding: EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat['name']),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  selected: isSelected,
                  selectedColor: Colors.blue,
                  backgroundColor: Colors.grey[200],
                  onSelected: (bool selected) {
                    if (selected) {
                      setState(() => _selectedCategoryId = cat['id']);
                      _loadData(); // Tải lại dữ liệu khi chọn danh mục
                    }
                  },
                ),
              );
            },
          ),
        ),

        // 3. LƯỚI SẢN PHẨM
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : _products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 50, color: Colors.grey),
                      Text("Không tìm thấy sản phẩm nào"),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => _loadData(), // Kéo xuống để reload
                  child: GridView.builder(
                    padding: EdgeInsets.all(10),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // 2 cột
                      childAspectRatio: 0.7, // Tỷ lệ khung hình (Cao > Rộng)
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _products.length,
                    itemBuilder: (ctx, i) => _buildProductCard(_products[i]),
                  ),
                ),
        ),
      ],
    );
  }

  // Widget hiển thị từng thẻ sản phẩm
  Widget _buildProductCard(Product p) {
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    // Xử lý link ảnh (Nối domain nếu link là tương đối)
    String domain = ApiService.baseUrl.replaceAll("/api", "");
    String imgUrl = (p.imageUrl != null && p.imageUrl!.startsWith("http"))
        ? p.imageUrl!
        : domain + (p.imageUrl ?? "");

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        // --- SỰ KIỆN: CHUYỂN SANG TRANG CHI TIẾT ---
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p)),
          );
        },
        // -------------------------------------------
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh sản phẩm
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                child: Image.network(
                  imgUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (c, e, s) => Container(
                    color: Colors.grey[200],
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Thông tin chi tiết
            Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (p.brand ?? "Khác").toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    p.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  SizedBox(height: 5),

                  // Giá và Nút thêm nhanh
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        currency.format(p.price),
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          // Thêm vào giỏ hàng (Gọi Provider)
                          Provider.of<CartProvider>(
                            context,
                            listen: false,
                          ).addItem(p.id, p.price, p.name, p.imageUrl);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Đã thêm vào giỏ"),
                              duration: Duration(milliseconds: 500),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.add_shopping_cart,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
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
}
