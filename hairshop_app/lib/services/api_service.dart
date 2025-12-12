import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // ⚠️ LƯU Ý: Thay đổi IP này theo máy tính của bạn (dùng ipconfig để kiểm tra)
  static const String baseUrl = "http://10.217.149.80:5194/api";

  // ========================================================================
  // 1. NHÓM AUTHENTICATION (Đăng nhập, Đăng ký, Profile)
  // ========================================================================

  // Đăng nhập
  Future<Map<String, dynamic>> login(String email, String password) async {
    print("--- LOGIN: $email ---");
    final url = '$baseUrl/AuthApi/login';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      print("Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Lỗi đăng nhập: ${response.body}');
      }
    } catch (e) {
      print("Lỗi kết nối Login: $e");
      throw e;
    }
  }

  // Đăng ký
  Future<bool> register(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/AuthApi/register'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "fullName": name,
          "email": email,
          "password": password,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Lỗi đăng ký: $e");
      return false;
    }
  }

  // CẬP NHẬT THÔNG TIN (Dùng chung cho cả Khách hàng và Shipper)
  // - Đối với Shipper: biến 'address' sẽ đóng vai trò là "Khu vực hoạt động"
  Future<bool> updateProfile(
    int userId,
    String fullName,
    String phone,
    String address,
  ) async {
    final url = Uri.parse('$baseUrl/AuthApi/update-profile');

    // Body JSON này phải khớp với UpdateProfileRequest trong C#
    final body = jsonEncode({
      "userId": userId,
      "fullName": fullName,
      "phone": phone,
      "address": address,
    });

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print("Lỗi update: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Exception updateProfile: $e");
      return false;
    }
  }

  // Upload Avatar
  Future<String?> uploadAvatar(int userId, String filePath) async {
    var uri = Uri.parse('$baseUrl/AuthApi/upload-avatar?userId=$userId');
    var request = http.MultipartRequest('POST', uri);

    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        return json['avatarUrl']; // Trả về link ảnh mới
      }
    } catch (e) {
      print("Lỗi upload avatar: $e");
    }
    return null;
  }

  // Nâng cấp lên Shipper
  Future<Map<String, dynamic>> becomeShipper(
    int userId,
    String phone,
    String address,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/AuthApi/become-shipper'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"userId": userId, "phone": phone, "address": address}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Lỗi nâng cấp tài khoản');
    }
  }

  // ========================================================================
  // 2. NHÓM SẢN PHẨM (PRODUCT)
  // ========================================================================

  Future<List<dynamic>> getProducts({String? search, int? categoryId}) async {
    String queryString = "";
    if (search != null && search.isNotEmpty) queryString += "search=$search&";
    if (categoryId != null && categoryId != 0)
      queryString += "categoryId=$categoryId";

    final url = '$baseUrl/ProductApi?$queryString';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print("Lỗi tải sản phẩm: $e");
      return [];
    }
  }

  // ========================================================================
  // 3. NHÓM GIỎ HÀNG (CART)
  // ========================================================================

  Future<List<dynamic>> getCart(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/CartApi/$userId'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  Future<void> addToCart(int userId, int productId, int quantity) async {
    await http.post(
      Uri.parse('$baseUrl/CartApi/add'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": userId,
        "productId": productId,
        "quantity": quantity,
      }),
    );
  }

  Future<void> decreaseCartItem(int userId, int productId) async {
    await http.post(
      Uri.parse('$baseUrl/CartApi/decrease'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": userId,
        "productId": productId,
        "quantity": 1,
      }),
    );
  }

  Future<void> removeCartItem(int userId, int productId) async {
    await http.delete(
      Uri.parse('$baseUrl/CartApi/remove?userId=$userId&productId=$productId'),
    );
  }

  // ========================================================================
  // 4. NHÓM ĐƠN HÀNG (ORDER - CUSTOMER)
  // ========================================================================

  // Tạo đơn hàng (Checkout)
  Future<bool> createOrder(
    int userId,
    String address,
    String phone,
    String paymentMethod,
    List<dynamic> items,
  ) async {
    final url = Uri.parse('$baseUrl/OrderApi/create');
    final body = jsonEncode({
      "userId": userId,
      "address": address,
      "phone": phone, // Quan trọng: Gửi SĐT khách nhập
      "paymentMethod": paymentMethod,
      "items": items
          .map(
            (i) => {
              "productId": int.parse(i.id),
              "quantity": i.quantity,
              "price": i.price,
            },
          )
          .toList(),
    });

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Lấy lịch sử mua hàng
  Future<List<dynamic>> getHistory(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/OrderApi/history/$userId'),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  // Lấy chi tiết đơn hàng
  Future<Map<String, dynamic>> getOrderDetail(int orderId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/OrderApi/detail/$orderId'),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Lỗi tải chi tiết đơn');
  }

  // ========================================================================
  // 5. NHÓM SHIPPER (Giao hàng)
  // ========================================================================

  // Lấy danh sách đơn theo trạng thái (Cần lấy / Đang giao)
  Future<List<dynamic>> getOrdersByStatus(String status, int shipperId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/OrderApi/list?status=$status&shipperId=$shipperId'),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  // Cập nhật trạng thái (Nhận đơn / Giao thành công / Hủy)
  Future<bool> updateOrderStatus(
    int orderId,
    String newStatus,
    int shipperId,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/OrderApi/update-status'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "orderId": orderId,
        "newStatus": newStatus,
        "shipperId": shipperId,
      }),
    );
    return response.statusCode == 200;
  }

  // Thống kê hiệu suất Shipper
  Future<List<dynamic>> getShipperStats(int shipperId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/OrderApi/shipper-stats?shipperId=$shipperId'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  // ========================================================================
  // 6. NHÓM ĐÁNH GIÁ (REVIEW)
  // ========================================================================

  Future<List<dynamic>> getProductReviews(int productId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/ReviewApi/product/$productId'),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  Future<bool> submitReview(
    int userId,
    int productId,
    int orderId,
    int rating,
    String comment,
    String? imagePath,
  ) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/ReviewApi/add'),
    );
    request.fields['UserId'] = userId.toString();
    request.fields['ProductId'] = productId.toString();
    request.fields['OrderId'] = orderId.toString();
    request.fields['Rating'] = rating.toString();
    request.fields['Comment'] = comment;

    if (imagePath != null) {
      request.files.add(
        await http.MultipartFile.fromPath('ImageFile', imagePath),
      );
    }

    var response = await request.send();
    return response.statusCode == 200;
  }
}
