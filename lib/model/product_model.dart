// lib/model/product_model.dart

class Product {
  final String key;
  final String name;
  final String? shadeName;
  final String price;
  final String imageUrl;
  final String description;
  final String category;
  final String subCategory;
  final String brand;   // ⭐ ADD THIS
  final int stock;      // ⭐ ADD THIS

  Product({
    required this.key,
    required this.name,
    this.shadeName,
    required this.price,
    required this.imageUrl,
    required this.description,
    required this.category,
    required this.subCategory,
    required this.brand,   // ⭐ ADD THIS
    required this.stock,   // ⭐ ADD THIS
  });

  factory Product.fromMap(String key, Map<String, dynamic> map) {
    return Product(
      key: key,
      name: map['name'] ?? 'No Name',
      shadeName: map['shadeName'],
      price: map['price']?.toString() ?? '0.00',
      imageUrl: map['imageUrl'] ?? '',
      description: map['description'] ?? 'No Description',
      category: map['category'] ?? 'Uncategorized',
      subCategory: map['subCategory'] ?? 'General',
      brand: map['brand'] ?? 'Unbranded', // ⭐ ADD THIS
      stock: (map['stock'] as num?)?.toInt() ?? 0, // ⭐ ADD THIS
    );
  }
}