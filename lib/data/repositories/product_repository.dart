import 'package:firebase_database/firebase_database.dart';
import 'package:c_h_p/model/product_model.dart';

/// Repository to access products stored in Firebase Realtime Database.
class ProductRepository {
  final DatabaseReference _ref = FirebaseDatabase.instance.ref('products');

  Future<List<Product>> fetchAll() async {
    final snapshot = await _ref.get();
    if (!snapshot.exists || snapshot.value == null) return [];
    final map = Map<String, dynamic>.from(snapshot.value as Map);
    final List<Product> products = [];
    map.forEach((key, value) {
      try {
        products.add(Product.fromMap(key, Map<String, dynamic>.from(value)));
      } catch (_) {
        // Ignore malformed items
      }
    });
    return products;
  }
}
