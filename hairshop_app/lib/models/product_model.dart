class Product {
  final int id;
  final String name;
  final double price;
  final String? imageUrl;
  final String? brand;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
    this.brand,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'],
      brand: json['brand'],
    );
  }
}
