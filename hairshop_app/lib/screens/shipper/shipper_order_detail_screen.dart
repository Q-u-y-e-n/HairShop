import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';

class ShipperOrderDetailScreen extends StatefulWidget {
  final int orderId;
  final String
  currentStatus; // Trạng thái hiện tại của đơn (Confirmed/Shipping)

  const ShipperOrderDetailScreen({
    required this.orderId,
    required this.currentStatus,
  });

  @override
  _ShipperOrderDetailScreenState createState() =>
      _ShipperOrderDetailScreenState();
}

class _ShipperOrderDetailScreenState extends State<ShipperOrderDetailScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _order;
  bool _isLoading = true; // Loading khi tải dữ liệu
  bool _isActionLoading = false; // Loading khi bấm nút hành động

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  // Tải chi tiết đơn hàng
  void _loadDetail() async {
    try {
      var data = await _api.getOrderDetail(widget.orderId);
      if (mounted) {
        setState(() {
          _order = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Hàm xử lý nút bấm (Nhận đơn / Giao xong)
  void _updateStatus(String newStatus) async {
    // 1. Lấy ID Shipper hiện tại
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;

    setState(() => _isActionLoading = true);

    try {
      // 2. Gọi API cập nhật trạng thái (Gửi kèm ID Shipper)
      bool success = await _api.updateOrderStatus(
        widget.orderId,
        newStatus,
        user.id,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text("Thao tác thành công!"),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context); // Quay về danh sách để reload
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi: Có thể đơn đã bị người khác nhận."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi kết nối: $e")));
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return Scaffold(
        appBar: AppBar(title: Text("Đang tải...")),
        body: Center(child: CircularProgressIndicator()),
      );
    if (_order == null)
      return Scaffold(
        appBar: AppBar(title: Text("Lỗi")),
        body: Center(child: Text("Không tải được đơn hàng")),
      );

    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    var items = _order!['items'] as List;

    // Lấy domain gốc để nối vào link ảnh (Bỏ phần /api đi)
    String domain = ApiService.baseUrl.replaceAll("/api", "");

    return Scaffold(
      appBar: AppBar(
        title: Text("Chi tiết đơn #${widget.orderId}"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. THẺ THÔNG TIN KHÁCH HÀNG
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.local_shipping, color: Colors.orange),
                              SizedBox(width: 8),
                              Text(
                                "THÔNG TIN GIAO HÀNG",
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Divider(height: 20),
                          _infoRow(
                            Icons.person,
                            "Khách hàng",
                            _order!['customerName'],
                          ),
                          SizedBox(height: 10),
                          // Hiển thị SĐT chuẩn từ API
                          _infoRow(
                            Icons.phone,
                            "Số điện thoại",
                            _order!['phone'] ?? "Không có SĐT",
                          ),
                          SizedBox(height: 10),
                          _infoRow(
                            Icons.location_on,
                            "Địa chỉ",
                            _order!['address'] ?? "Chưa có địa chỉ",
                          ),
                          SizedBox(height: 10),
                          _infoRow(
                            Icons.payment,
                            "Thanh toán",
                            _order!['payment'] ?? "Tiền mặt",
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 15),

                  // 2. DANH SÁCH SẢN PHẨM (ĐÃ SỬA LỖI ẢNH)
                  Text(
                    "Danh sách sản phẩm:",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 5),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: items.map((item) {
                        // Xử lý link ảnh
                        String imgUrl = "";
                        if (item['imageUrl'] != null) {
                          imgUrl = item['imageUrl'];
                          if (!imgUrl.startsWith("http")) {
                            imgUrl = domain + imgUrl; // Nối domain vào
                          }
                        }

                        return ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: imgUrl.isNotEmpty
                                  ? Image.network(
                                      imgUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => Icon(
                                        Icons.image_not_supported,
                                        color: Colors.grey,
                                      ),
                                    )
                                  : Icon(Icons.image, color: Colors.grey),
                            ),
                          ),
                          title: Text(
                            item['productName'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            "x${item['quantity']}",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            currency.format(item['price']),
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  SizedBox(height: 20),
                  // 3. TỔNG TIỀN
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
                          "TỔNG THU HỘ (COD):",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red[800],
                          ),
                        ),
                        Text(
                          currency.format(_order!['total']),
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. KHU VỰC NÚT BẤM (ĐÃ THÊM SAFEAREA)
          SafeArea(
            top: false,
            child: Container(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
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
              child: _buildActionButtons(),
            ),
          ),
        ],
      ),
    );
  }

  // Widget hiển thị thông tin 1 dòng
  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text(
                value,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget hiển thị các nút hành động
  Widget _buildActionButtons() {
    if (_isActionLoading) {
      return Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 15),
            Text("Đang xử lý..."),
          ],
        ),
      );
    }

    // A. Nếu là Đơn mới (Confirmed) -> Nút NHẬN ĐƠN
    if (widget.currentStatus == "Confirmed") {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          icon: Icon(Icons.handshake, color: Colors.white),
          label: Text(
            "NHẬN GIAO ĐƠN NÀY",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () => _updateStatus("Shipping"),
        ),
      );
    }

    // B. Nếu là Đang giao (Shipping) -> Nút THÀNH CÔNG / THẤT BẠI
    if (widget.currentStatus == "Shipping") {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => _updateStatus("Cancelled"),
              child: Text(
                "GIAO THẤT BẠI",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => _updateStatus("Completed"),
              child: Text(
                "GIAO THÀNH CÔNG",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Center(
      child: Text(
        "Đơn hàng này đã kết thúc",
        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
      ),
    );
  }
}
