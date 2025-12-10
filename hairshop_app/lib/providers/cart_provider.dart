import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../services/api_service.dart';

class CartProvider with ChangeNotifier {
  Map<String, CartItem> _items = {};
  final ApiService _api = ApiService();
  int? _userId;

  // Getter lấy danh sách items
  Map<String, CartItem> get items => {..._items};

  // Đếm số lượng
  int get itemCount => _items.length;

  // Tính tổng tiền
  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, item) => total += item.price * item.quantity);
    return total;
  }

  // --- HÀM TẢI GIỎ HÀNG ---
  Future<void> fetchCart(int userId) async {
    _userId = userId;
    try {
      var list = await _api.getCart(userId);
      _items = {};
      for (var i in list) {
        _items.putIfAbsent(
          i['productId'].toString(),
          () => CartItem(
            id: i['productId'].toString(),
            title: i['productName'] ?? "Sản phẩm",
            price: (i['price'] as num).toDouble(),
            quantity: i['quantity'],
            imageUrl: i['imageUrl'],
          ),
        );
      }
      notifyListeners();
    } catch (e) {
      print("Lỗi tải giỏ: $e");
    }
  }

  // --- HÀM THÊM VÀO GIỎ ---
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
      await _api.addToCart(_userId!, productId, 1);
    }
  }

  // --- HÀM GIẢM SỐ LƯỢNG ---
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
    if (_userId != null)
      await _api.decreaseCartItem(_userId!, int.parse(productId));
  }

  // --- HÀM XÓA HẲN 1 MÓN ---
  Future<void> removeItem(String productId) async {
    _items.remove(productId);
    notifyListeners();
    if (_userId != null)
      await _api.removeCartItem(_userId!, int.parse(productId));
  }

  // --- HÀM DỌN SẠCH GIỎ (Logout) ---
  void clear() {
    _items = {};
    _userId = null;
    notifyListeners();
  }

  // ====================================================
  // HÀM THANH TOÁN (QUAN TRỌNG: NHẬN THÊM PHONE)
  // ====================================================
  Future<bool> clearAndCreateOrder(
    int userId,
    String address,
    String phone,
    String paymentMethod,
  ) async {
    // 1. Gọi API tạo đơn (truyền cả Phone)
    bool success = await _api.createOrder(
      userId,
      address,
      phone, // <--- Truyền SĐT xuống API Service
      paymentMethod,
      _items.values.toList(),
    );

    if (success) {
      // 2. Nếu thành công -> Xóa sạch giỏ hàng trên App
      _items = {};
      notifyListeners();

      // (Tùy chọn) Gọi API xóa giỏ hàng trên Server nếu cần
      // await _api.clearCart(userId);

      return true;
    }
    return false;
  }
}
