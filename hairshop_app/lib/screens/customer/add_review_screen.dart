import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class AddReviewScreen extends StatefulWidget {
  final int orderId;
  final int productId;
  final String productName;

  const AddReviewScreen({
    required this.orderId,
    required this.productId,
    required this.productName,
  });

  @override
  _AddReviewScreenState createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  int _rating = 5;
  final _commentCtrl = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    // Cho phép chọn ảnh từ thư viện
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  void _submit() async {
    setState(() => _isLoading = true);
    final user = Provider.of<AuthProvider>(context, listen: false).user;

    try {
      bool success = await ApiService().submitReview(
        user!.id,
        widget.productId,
        widget.orderId,
        _rating,
        _commentCtrl.text,
        _imageFile?.path,
      );
      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Đánh giá thành công!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Đóng màn hình đánh giá
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Viết đánh giá")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // Tên sản phẩm
            Text("Sản phẩm:", style: TextStyle(color: Colors.grey)),
            SizedBox(height: 5),
            Text(
              widget.productName,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Divider(height: 30),

            // Chọn sao
            Text(
              "Chất lượng sản phẩm",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.orange,
                    size: 40,
                  ),
                  onPressed: () => setState(() => _rating = index + 1),
                );
              }),
            ),

            // Nhập nội dung
            SizedBox(height: 10),
            TextField(
              controller: _commentCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Hãy chia sẻ cảm nhận của bạn về sản phẩm...",
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            SizedBox(height: 20),

            // Tải ảnh thực tế
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                ),
                child: _imageFile == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, color: Colors.blue, size: 40),
                          Text(
                            "Thêm ảnh thực tế",
                            style: TextStyle(color: Colors.blue),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(_imageFile!, fit: BoxFit.cover),
                      ),
              ),
            ),
            SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "GỬI ĐÁNH GIÁ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
