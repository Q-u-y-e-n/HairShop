import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../providers/cart_provider.dart';
import '../../models/product_model.dart';

class CustomerProductTab extends StatefulWidget {
  @override
  _CustomerProductTabState createState() => _CustomerProductTabState();
}

class _CustomerProductTabState extends State<CustomerProductTab> {
  final ApiService _api = ApiService();
  List<Product> _products = [];
  bool _isLoading = true;

  final _searchCtrl = TextEditingController();
  int _selectedCategoryId = 0;

  // Danh mục cứng (Hoặc gọi API lấy về)
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

  void _loadData() async {
    setState(() => _isLoading = true);
    try {
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
      print("Lỗi load data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // HEADER TÌM KIẾM
        Container(
          padding: EdgeInsets.fromLTRB(15, 10, 15, 15),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: "Tìm kiếm sản phẩm...",
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: Icon(Icons.search),
                onPressed: _loadData,
              ),
            ),
            onSubmitted: (_) => _loadData(),
          ),
        ),

        // CATEGORY CHIPS
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
                  selected: isSelected,
                  selectedColor: Colors.blue.shade100,
                  onSelected: (val) {
                    if (val) {
                      setState(() => _selectedCategoryId = cat['id']);
                      _loadData();
                    }
                  },
                ),
              );
            },
          ),
        ),

        // PRODUCT GRID
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : _products.isEmpty
              ? Center(child: Text("Không có sản phẩm nào"))
              : RefreshIndicator(
                  onRefresh: () async => _loadData(),
                  child: GridView.builder(
                    padding: EdgeInsets.all(10),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
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

  Widget _buildProductCard(Product p) {
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    // Xử lý link ảnh (Nối domain nếu cần)
    String domain = ApiService.baseUrl.replaceAll("/api", "");
    String imgUrl = (p.imageUrl != null && p.imageUrl!.startsWith("http"))
        ? p.imageUrl!
        : domain + (p.imageUrl ?? "");

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.network(
                imgUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (c, e, s) => Container(
                  color: Colors.grey[200],
                  child: Icon(Icons.image_not_supported),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (p.brand ?? "").toUpperCase(),
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
                Text(
                  p.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      currency.format(p.price),
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        // --- TRUYỀN ẢNH VÀO PROVIDER ---
                        Provider.of<CartProvider>(
                          context,
                          listen: false,
                        ).addItem(p.id, p.price, p.name, p.imageUrl);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Đã thêm vào giỏ"),
                            duration: Duration(milliseconds: 500),
                          ),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.add, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
