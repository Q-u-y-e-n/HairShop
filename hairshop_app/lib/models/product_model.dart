class Product {
  final int id;
  final String name;
  final double price;
  final String? imageUrl;
  final String? brand;
  final String? categoryName;

  // --- BỔ SUNG TRƯỜNG DESCRIPTION ---
  final String? description;
  // ----------------------------------

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
    this.brand,
    this.categoryName,
    // --- THÊM VÀO CONSTRUCTOR ---
    this.description,
    // ----------------------------
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      // Chuyển đổi an toàn sang double
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'],
      brand: json['brand'],
      categoryName: json['categoryName'],

      // --- MAP DỮ LIỆU TỪ JSON ---
      description: json['description'],
      // ---------------------------
    );
  }
}
