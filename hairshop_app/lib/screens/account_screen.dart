import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/api_service.dart';
import 'shipper/shipper_main_screen.dart'; // Import màn hình Shipper
import 'auth/login_screen.dart';
import 'customer/my_orders_screen.dart';
import 'package:image_picker/image_picker.dart';

class AccountScreen extends StatefulWidget {
  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final ApiService _api = ApiService();

  // Biến đếm số lượng đơn hàng
  int _pendingCount = 0;
  int _shippingCount = 0;
  int _reviewCount = 0;

  @override
  void initState() {
    super.initState();
    _loadOrderCounts();
  }

  // 1. Tải số lượng đơn hàng
  void _loadOrderCounts() async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;

    try {
      var orders = await _api.getHistory(user.id);
      int pCount = 0;
      int sCount = 0;
      int rCount = 0;

      for (var o in orders) {
        String status = o['status'];
        if (status == 'Pending' || status == 'Confirmed') {
          pCount++;
        } else if (status == 'Shipping') {
          sCount++;
        } else if (status == 'Completed') {
          rCount++;
        }
      }

      if (mounted) {
        setState(() {
          _pendingCount = pCount;
          _shippingCount = sCount;
          _reviewCount = rCount;
        });
      }
    } catch (e) {
      print("Lỗi tải đơn hàng: $e");
    }
  }

  // 2. Xử lý Đăng xuất
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Đăng xuất"),
        content: Text("Bạn có chắc muốn đăng xuất không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Hủy")),
          TextButton(
            child: Text("Đồng ý", style: TextStyle(color: Colors.red)),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Provider.of<CartProvider>(context, listen: false).clear();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (ctx) => LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  // 3. Xử lý Chọn ảnh đại diện (MỚI)
  void _pickImage() async {
    final ImagePicker picker = ImagePicker();
    // Mở thư viện ảnh
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Đang tải ảnh lên...")));

      // Gọi Provider upload (Bạn cần đảm bảo AuthProvider đã có hàm updateAvatar)
      bool success = await Provider.of<AuthProvider>(
        context,
        listen: false,
      ).updateAvatar(image.path);

      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Đã đổi ảnh đại diện!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi tải ảnh."), backgroundColor: Colors.red),
        );
      }
    }
  }

  // 4. Dialog sửa thông tin cá nhân
  void _showEditProfileDialog() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) return;

    final nameCtrl = TextEditingController(text: user.fullName);
    final phoneCtrl = TextEditingController(text: user.phone ?? "");
    final addressCtrl = TextEditingController(text: user.address ?? "");
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text("Cập nhật hồ sơ"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: "Họ và tên",
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  SizedBox(height: 15),
                  TextField(
                    controller: phoneCtrl,
                    decoration: InputDecoration(
                      labelText: "Số điện thoại",
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 15),
                  TextField(
                    controller: addressCtrl,
                    decoration: InputDecoration(
                      labelText: "Địa chỉ nhận hàng",
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: Text("Hủy", style: TextStyle(color: Colors.grey)),
                onPressed: () => Navigator.pop(ctx),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                onPressed: isSaving
                    ? null
                    : () async {
                        if (nameCtrl.text.isEmpty) return;
                        setDialogState(() => isSaving = true);

                        bool success = await authProvider.updateUserInfo(
                          nameCtrl.text,
                          phoneCtrl.text,
                          addressCtrl.text,
                        );

                        setDialogState(() => isSaving = false);
                        if (success) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Cập nhật thành công!"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Lỗi cập nhật."),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                child: isSaving
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        "Lưu thay đổi",
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ================= HEADER PROFILE =================
            Container(
              padding: EdgeInsets.fromLTRB(20, 50, 20, 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade800, Colors.blue.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // --- AVATAR VÀ NÚT CAMERA ---
                      Stack(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              color: Colors.white,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: _buildAvatarImage(
                                user?.avatarUrl,
                                user?.fullName,
                              ),
                            ),
                          ),
                          // Nút Camera nhỏ ở góc
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: _pickImage, // Bấm vào để chọn ảnh
                              child: Container(
                                padding: EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  size: 16,
                                  color: Colors.blue[800],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(width: 15),

                      // --- TÊN VÀ EMAIL ---
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.fullName ?? "Khách hàng",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              user?.email ?? "",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // --- NÚT SỬA THÔNG TIN ---
                      IconButton(
                        icon: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        onPressed: _showEditProfileDialog,
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // --- THÔNG TIN SĐT & ĐỊA CHỈ ---
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          Icons.phone,
                          user?.phone ?? "Chưa cập nhật SĐT",
                        ),
                        Divider(color: Colors.white24, height: 15),
                        _buildInfoRow(
                          Icons.location_on,
                          user?.address ?? "Chưa cập nhật địa chỉ",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ================= BADGE TRẠNG THÁI =================
            Container(
              margin: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              padding: EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBadgeIcon(
                    Icons.assignment_outlined,
                    "Chờ xác nhận",
                    _pendingCount,
                    0,
                  ),
                  _buildBadgeIcon(
                    Icons.local_shipping_outlined,
                    "Đang giao",
                    _shippingCount,
                    0,
                  ),
                  _buildBadgeIcon(Icons.history, "Lịch sử", _reviewCount, 1),
                ],
              ),
            ),

            // ================= MENU TÙY CHỌN =================
            Container(
              margin: EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (user?.role == "Customer")
                    ListTile(
                      leading: Icon(Icons.motorcycle, color: Colors.orange),
                      title: Text(
                        "Đăng ký Shipper",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800],
                        ),
                      ),
                      trailing: Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Tính năng đang bảo trì")),
                        );
                      },
                    ),
                  if (user?.role == "Customer") Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.lock_outline, color: Colors.grey[700]),
                    title: Text("Đổi mật khẩu"),
                    trailing: Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () {},
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.help_outline, color: Colors.grey[700]),
                    title: Text("Trung tâm trợ giúp"),
                    trailing: Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            SizedBox(height: 25),

            // ================= NÚT ĐĂNG XUẤT =================
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: Icon(Icons.logout, color: Colors.red),
                  label: Text("Đăng xuất", style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.all(15),
                    side: BorderSide(color: Colors.red.shade100),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _handleLogout,
                ),
              ),
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Helper: Hiển thị Avatar (Xử lý URL)
  Widget _buildAvatarImage(String? url, String? name) {
    // 1. Xử lý URL (Nối domain nếu cần)
    // Lưu ý: ApiService.baseUrl đang là .../api, ta cần bỏ /api đi để lấy root domain
    String domain = ApiService.baseUrl.replaceAll("/api", "");

    if (url != null && url.isNotEmpty) {
      String fullUrl = url.startsWith("http") ? url : domain + url;
      return Image.network(
        fullUrl,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) =>
            Center(child: Icon(Icons.person, size: 40, color: Colors.grey)),
      );
    }

    // 2. Nếu không có ảnh -> Hiện chữ cái đầu
    return Center(
      child: Text(
        (name != null && name.isNotEmpty) ? name[0].toUpperCase() : "U",
        style: TextStyle(
          fontSize: 35,
          color: Colors.blue,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Helper: Dòng thông tin
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.white, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Helper: Badge Icon
  Widget _buildBadgeIcon(IconData icon, String label, int count, int tabIndex) {
    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MyOrdersScreen(initialIndex: tabIndex),
          ),
        );
        _loadOrderCounts();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Column(
              children: [
                Icon(icon, size: 28, color: Colors.grey[800]),
                SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ],
            ),
          ),
          if (count > 0)
            Positioned(
              right: 2,
              top: -2,
              child: Container(
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  count > 9 ? "9+" : "$count",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
