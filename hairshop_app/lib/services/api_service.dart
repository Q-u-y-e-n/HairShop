import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Đổi port 5194 thành port thực tế của bạn
  static const String baseUrl = "http://localhost:5194/api";

  // 1. Đăng nhập
  Future<Map<String, dynamic>> login(String email, String password) async {
    print("---------------------------------");
    print("Đang gọi API login...");
    final url = '$baseUrl/AuthApi/login';
    print("URL: $url");
    print("Data: $email / $password");

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      print("STATUS CODE: ${response.statusCode}"); // <--- Quan trọng
      print("RESPONSE BODY: ${response.body}"); // <--- Quan trọng

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Ném ra lỗi cụ thể để UI hiển thị
        throw Exception('Lỗi ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print("LỖI KẾT NỐI LOGIN: $e");
      throw e;
    }
  }

  // 2. Lấy đơn hàng của Shipper
  Future<List<dynamic>> getShipperOrders(int shipperId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/ShipperApi/my-orders?shipperId=$shipperId'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Lỗi tải đơn hàng');
  }

  // 3. Cập nhật trạng thái đơn (Shipper)
  Future<bool> updateOrderStatus(int orderId, int status, int shipperId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ShipperApi/update-status'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "orderId": orderId,
        "newStatus": status,
        "shipperId": shipperId,
      }),
    );
    return response.statusCode == 200;
  }

  // Trong class ApiService
  // Đăng ký khách hàng
  // Đăng ký
  Future<bool> register(String name, String email, String password) async {
    print("Đang gọi API Đăng ký..."); // <--- Thêm dòng này để debug
    print("URL: $baseUrl/AuthApi/register"); // <--- Kiểm tra URL

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/AuthApi/register'), // <--- Phải là /register
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "fullName": name,
          "email": email,
          "password": password,
        }),
      );

      print("Status Code: ${response.statusCode}"); // <--- Xem server trả về gì
      print("Body: ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      print("LỖI KẾT NỐI ĐĂNG KÝ: $e"); // <--- Xem lỗi cụ thể
      throw e;
    }
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
      return jsonDecode(response.body); // Trả về User mới với Role Shipper
    } else {
      throw Exception('Lỗi nâng cấp tài khoản');
    }
  }

  // 5. Lấy lịch sử mua hàng (Dành cho Customer)
  Future<List<dynamic>> getHistory(int userId) async {
    // Gọi API: GET /api/OrderApi/history/{userId}
    final response = await http.get(
      Uri.parse('$baseUrl/OrderApi/history/$userId'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Lỗi tải lịch sử đơn hàng: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> getProducts({String? search, int? categoryId}) async {
    String queryString = "";
    if (search != null && search.isNotEmpty) queryString += "search=$search&";
    if (categoryId != null && categoryId != 0)
      queryString += "categoryId=$categoryId";

    final url = '$baseUrl/ProductApi?$queryString';

    // --- THÊM LOG ĐỂ DEBUG ---
    print("--------------------------");
    print("Đang gọi API: $url");

    try {
      final response = await http.get(Uri.parse(url));

      print("Status Code: ${response.statusCode}"); // <--- Quan trọng
      print("Body: ${response.body}"); // <--- Quan trọng

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Lỗi Server (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      print("LỖI KẾT NỐI SP: $e");
      throw Exception('Lỗi kết nối: $e');
    }
  }
  // Thêm vào class ApiService

  // 1. Gửi đơn hàng (Checkout)
  Future<bool> createOrder(Map<String, dynamic> orderData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/OrderApi/create'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(orderData),
    );
    return response.statusCode == 200;
  }

  // 2. Lấy chi tiết đơn hàng
  Future<Map<String, dynamic>> getOrderDetail(int orderId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/OrderApi/detail/$orderId'),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Lỗi tải chi tiết đơn hàng');
  }

  // 3. Gửi đánh giá (Multipart File)
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

  // Trong class ApiService
  // Lấy giỏ hàng từ Server
  Future<List<dynamic>> getCart(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/CartApi/$userId'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  // Đồng bộ thêm vào giỏ
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

  // Giảm số lượng
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

  // Xóa khỏi giỏ
  Future<void> removeCartItem(int userId, int productId) async {
    await http.delete(
      Uri.parse('$baseUrl/CartApi/remove?userId=$userId&productId=$productId'),
    );
  }
}
