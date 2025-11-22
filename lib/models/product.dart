// lib/models/product.dart

class Product {
  final int id;
  final String name;
  final String description;
  final String imageUrl;
  final int quantity;
  final String categoryName;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.quantity,
    required this.categoryName,
  });
}
