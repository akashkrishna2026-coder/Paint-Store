// Helper class for clickable benefits
class Benefit {
  final String image;
  final String text;

  Benefit({required this.image, required this.text});

  factory Benefit.fromMap(Map<String, dynamic> map) {
    return Benefit(
      image: map['image'] ?? '',
      text: map['text'] ?? '',
    );
  }
}

// Helper class for different pack sizes and their prices
class PackSize {
  final String size;
  final String price;

  PackSize({required this.size, required this.price});

  factory PackSize.fromMap(String size, dynamic price) {
    return PackSize(
      size: size,
      price: price?.toString() ?? '0',
    );
  }

  // Helper to get the numeric part of the size for sorting
  int get numericSize {
    // Extracts the number (e.g., 1 from "1 L", 10 from "10 L")
    return int.tryParse(size.split(' ').first) ?? 0;
  }
}

// The main Product class
class Product {
  final String key;
  final String name;
  final String description;
  final int stock;
  final String? brand;
  final String? category;
  final String? subCategory;
  final String mainImageUrl;
  final String backgroundImageUrl;
  final List<Benefit> benefits;
  final List<PackSize> packSizes; // This list will be sorted
  final String brochureUrl;
  final int? warrantyYears; // Optional warranty (years)

  Product({
    required this.key,
    required this.name,
    required this.description,
    required this.stock,
    this.brand,
    this.category,
    this.subCategory,
    required this.mainImageUrl,
    required this.backgroundImageUrl,
    required this.benefits,
    required this.packSizes,
    required this.brochureUrl,
    this.warrantyYears,
  });

  factory Product.fromMap(String key, Map<String, dynamic> map) {
    var benefitList = <Benefit>[];
    if (map['benefits'] is List) {
      for (var item in (map['benefits'] as List)) {
        if (item is Map) {
          benefitList.add(Benefit.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }

    var packSizeList = <PackSize>[];
    if (map['packSizes'] is Map) {
      (map['packSizes'] as Map).forEach((size, price) {
        packSizeList.add(PackSize.fromMap(size.toString(), price));
      });
      // ⭐⭐⭐ THIS IS THE CRUCIAL SORTING STEP ⭐⭐⭐
      // Sorts the list numerically (1L, 4L, 10L, 20L) right after parsing
      packSizeList.sort((a, b) => a.numericSize.compareTo(b.numericSize));
    }


    return Product(
      key: key,
      name: map['name'] ?? 'No Name',
      description: map['description'] ?? 'No Description',
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      brand: map['brand'],
      category: map['category'],
      subCategory: map['subCategory'],
      mainImageUrl: map['mainImageUrl'] ?? map['imageUrl'] ?? '', // Fallback for old data
      backgroundImageUrl: map['backgroundImageUrl'] ?? '',
      benefits: benefitList,
      packSizes: packSizeList, // Assign the *already sorted* list
      brochureUrl: map['brochureUrl'] ?? '',
      warrantyYears: (map['warrantyYears'] as num?)?.toInt(),
    );
  }
}