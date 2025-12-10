import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../services/api_service.dart';

class CartProvider with ChangeNotifier {
  Map<String, CartItem> _items = {};
  final ApiService _api = ApiService();
  int? _userId;

  Map<String, CartItem> get items => {..._items};
  int get itemCount => _items.length;

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, item) => total += item.price * item.quantity);
    return total;
  }

  // --- HÀM TẢI GIỎ HÀNG (QUAN TRỌNG NHẤT) ---
  Future<void> fetchCart(int userId) async {
    _userId = userId;
    print("🚀 [CartProvider] Bắt đầu tải giỏ hàng cho User ID: $userId");

    try {
      var list = await _api.getCart(userId);
      print("✅ [CartProvider] API trả về: $list"); // Xem API trả về gì ở đây

      _items = {};
      for (var i in list) {
        // Kiểm tra kỹ tên trường dữ liệu từ API
        // Nếu API trả về 'productName' mà bạn gọi i['name'] là lỗi ngay
        _items.putIfAbsent(
          i['productId'].toString(),
          () => CartItem(
            id: i['productId'].toString(),
            title: i['productName'] ?? "Không tên", // Fallback nếu null
            price: (i['price'] as num).toDouble(),
            quantity: i['quantity'],
            imageUrl: i['imageUrl'],
          ),
        );
      }
      print("📦 [CartProvider] Đã nạp ${_items.length} sản phẩm vào RAM.");
      notifyListeners();
    } catch (e) {
      print("❌ [CartProvider] LỖI TẢI GIỎ: $e");
    }
  }

  // --- CÁC HÀM KHÁC GIỮ NGUYÊN NHƯ CŨ ---
  Future<void> addItem(
    int productId,
    double price,
    String title,
    String? imgUrl,
  ) async {
    if (_items.containsKey(productId.toString())) {
      _items.update(
        productId.toString(),
        (existing) => CartItem(
          id: existing.id,
          title: existing.title,
          price: existing.price,
          quantity: existing.quantity + 1,
          imageUrl: existing.imageUrl,
        ),
      );
    } else {
      _items.putIfAbsent(
        productId.toString(),
        () => CartItem(
          id: productId.toString(),
          title: title,
          price: price,
          quantity: 1,
          imageUrl: imgUrl,
        ),
      );
    }
    notifyListeners();

    if (_userId != null) {
      try {
        print(
          "----> Đang gửi yêu cầu lưu Server: User $_userId, Product $productId",
        );
        await _api.addToCart(_userId!, productId, 1);
        print("----> Đã gửi xong!");
      } catch (e) {
        print("LỖI LƯU GIỎ HÀNG: $e");
      }
    } else {
      print("CHƯA CÓ USER ID - KHÔNG LƯU ĐƯỢC");
    }
  }

  Future<void> removeSingleItem(String productId) async {
    if (!_items.containsKey(productId)) return;
    if (_items[productId]!.quantity > 1) {
      _items.update(
        productId,
        (existing) => CartItem(
          id: existing.id,
          title: existing.title,
          price: existing.price,
          quantity: existing.quantity - 1,
          imageUrl: existing.imageUrl,
        ),
      );
    } else {
      _items.remove(productId);
    }
    notifyListeners();
    if (_userId != null) {
      await _api.decreaseCartItem(_userId!, int.parse(productId));
    }
  }

  Future<void> removeItem(String productId) async {
    _items.remove(productId);
    notifyListeners();
    if (_userId != null) {
      await _api.removeCartItem(_userId!, int.parse(productId));
    }
  }

  void clear() {
    _items = {};
    _userId = null;
    notifyListeners();
  }
}
