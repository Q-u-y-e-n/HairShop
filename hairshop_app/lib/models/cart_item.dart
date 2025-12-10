class CartItem {
  final String id;
  final String title;
  final int quantity;
  final double price;
  final String? imageUrl; // <--- Thêm dòng này

  CartItem({
    required this.id,
    required this.title,
    required this.quantity,
    required this.price,
    this.imageUrl, // <--- Thêm dòng này
  });
}
