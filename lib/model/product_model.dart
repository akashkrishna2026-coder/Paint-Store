class Product {
  final String key;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String? shadeName; // Optional shade name

  Product({
    required this.key,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.shadeName,
  });

  // ⭐ FIX: This factory constructor is now hardened against bad data types.
  factory Product.fromMap(String key, Map<String, dynamic> data) {
    // Safely parse the price, converting from String or int if necessary.
    double parsedPrice = 0.0;
    if (data['price'] is String) {
      parsedPrice = double.tryParse(data['price']) ?? 0.0;
    } else if (data['price'] is num) {
      parsedPrice = (data['price'] as num).toDouble();
    }

    return Product(
      key: key,
      name: data['name'] ?? 'Unnamed Product',
      description: data['description'] ?? 'No description available.',
      price: parsedPrice,
      imageUrl: data['imageUrl'] ?? '',
      shadeName: data['shadeName'],
    );
  }
}