import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../auth/login_screen.dart';

class ShipperAccountScreen extends StatefulWidget {
  @override
  _ShipperAccountScreenState createState() => _ShipperAccountScreenState();
}

class _ShipperAccountScreenState extends State<ShipperAccountScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _stats = [];
  bool _isLoadingStats = true;

  // --- CẤU HÌNH MÀU SẮC (MÀU HỒNG CHUYÊN NGHIỆP) ---
  final Color _primaryColor = Colors.pink;
  final Color _darkPink = Colors.pink.shade700;
  final Color _lightPink = Colors.pink.shade400;
  final Color _bgPink = Colors.pink.shade50;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  // Tải thống kê từ API
  Future<void> _loadStats() async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;
    try {
      var data = await _api.getShipperStats(user.id);
      if (mounted)
        setState(() {
          _stats = data;
          _isLoadingStats = false;
        });
    } catch (e) {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  // Xử lý Đăng xuất
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Đăng xuất"),
        content: Text("Bạn muốn thoát tài khoản?"),
        actions: [
          TextButton(
            child: Text("Hủy", style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: Text("Thoát", style: TextStyle(color: Colors.red)),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
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

  // Xử lý chọn ảnh
  void _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Đang tải ảnh...")));
      bool success = await Provider.of<AuthProvider>(
        context,
        listen: false,
      ).updateAvatar(image.path);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Cập nhật thành công!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  // Hiển thị Dialog sửa thông tin
  void _showEditDialog() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;
    if (user == null) return;

    final nameCtrl = TextEditingController(text: user.fullName);
    final phoneCtrl = TextEditingController(text: user.phone ?? "");
    final addressCtrl = TextEditingController(text: user.address ?? "");
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text("Cập nhật hồ sơ"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: "Họ tên",
                    prefixIcon: Icon(Icons.person, color: _primaryColor),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 15),
                TextField(
                  controller: phoneCtrl,
                  decoration: InputDecoration(
                    labelText: "SĐT",
                    prefixIcon: Icon(Icons.phone, color: _primaryColor),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 15),
                TextField(
                  controller: addressCtrl,
                  decoration: InputDecoration(
                    labelText: "Khu vực hoạt động",
                    prefixIcon: Icon(Icons.map, color: _primaryColor),
                    border: OutlineInputBorder(),
                  ),
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
              style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
              onPressed: isSaving
                  ? null
                  : () async {
                      setStateDialog(() => isSaving = true);

                      // --- GỌI PROVIDER ĐỂ CẬP NHẬT ---
                      bool success = await auth.updateUserInfo(
                        nameCtrl.text,
                        phoneCtrl.text,
                        addressCtrl.text,
                      );

                      setStateDialog(() => isSaving = false);

                      if (success) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Đã lưu thay đổi"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Lỗi cập nhật"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              child: isSaving
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text("Lưu", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: _loadStats,
        color: _primaryColor,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // ================= 1. HEADER PROFILE (GRADIENT HỒNG) =================
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Nền Gradient
                  Container(
                    height: 240,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_darkPink, _lightPink],
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                      ),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryColor.withOpacity(0.3),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                  ),

                  // Nội dung Header
                  Positioned(
                    top: 60,
                    child: Column(
                      children: [
                        // Avatar + Nút Camera
                        Stack(
                          children: [
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(60),
                                child: _buildAvatar(
                                  user?.avatarUrl,
                                  user?.fullName,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: InkWell(
                                onTap: _pickImage,
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    color: _darkPink,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Text(
                          user?.fullName ?? "Shipper",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          user?.email ?? "",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // ================= 2. CARD THÔNG TIN (Màu hồng nhẹ) =================
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  elevation: 4,
                  shadowColor: Colors.pink.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          Icons.phone,
                          "Số điện thoại",
                          user?.phone ?? "Chưa cập nhật",
                        ),
                        Divider(height: 25, color: Colors.grey[200]),
                        _buildInfoRow(
                          Icons.map,
                          "Khu vực hoạt động",
                          user?.address ?? "Chưa cập nhật",
                        ),
                        SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: Icon(Icons.edit, size: 18),
                            label: Text("Chỉnh sửa thông tin"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _primaryColor,
                              side: BorderSide(color: _primaryColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: _showEditDialog,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 25),

              // ================= 3. THỐNG KÊ HIỆU SUẤT =================
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.bar_chart, color: _darkPink),
                    SizedBox(width: 10),
                    Text(
                      "Hiệu suất giao hàng",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 15),

              if (_isLoadingStats)
                Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: _primaryColor),
                )
              else if (_stats.isEmpty)
                Container(
                  margin: EdgeInsets.all(20),
                  padding: EdgeInsets.all(30),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 50,
                        color: Colors.grey[300],
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Chưa có dữ liệu thống kê",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _stats.length,
                  itemBuilder: (ctx, i) => _buildStatCard(_stats[i]),
                ),

              SizedBox(height: 30),

              // ================= 4. NÚT ĐĂNG XUẤT =================
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.logout, color: Colors.white),
                    label: Text(
                      "Đăng xuất",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[400],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _handleLogout,
                  ),
                ),
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Helper: Dòng thông tin
  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _bgPink,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _primaryColor, size: 22),
        ),
        SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper: Thẻ thống kê
  Widget _buildStatCard(dynamic item) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Tháng ${item['month']}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: _darkPink,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Đã kết sổ",
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "${item['successCount']}",
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      Text(
                        "Thành công",
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "${item['failedCount']}",
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      Text(
                        "Thất bại/Hủy",
                        style: TextStyle(color: Colors.red[700], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper: Avatar
  Widget _buildAvatar(String? url, String? name) {
    String domain = ApiService.baseUrl.replaceAll("/api", "");
    if (url != null && url.isNotEmpty) {
      String fullUrl = url.startsWith("http") ? url : domain + url;
      return Image.network(
        fullUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(Icons.person, color: Colors.grey),
      );
    }
    return Center(
      child: Text(
        name != null && name.isNotEmpty ? name[0].toUpperCase() : "S",
        style: TextStyle(fontSize: 40, color: _primaryColor),
      ),
    );
  }
}
