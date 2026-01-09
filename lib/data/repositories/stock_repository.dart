import 'package:firebase_database/firebase_database.dart';
import 'package:c_h_p/model/product_model.dart';

class StockRepository {
  DatabaseReference get _ref => FirebaseDatabase.instance.ref('products');

  Stream<List<Product>> productsStream() {
    return _ref.onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return <Product>[];
      }
      final map = Map<String, dynamic>.from(event.snapshot.value as Map);
      final List<Product> products = [];
      map.forEach((key, value) {
        try {
          products.add(Product.fromMap(key, Map<String, dynamic>.from(value)));
        } catch (_) {}
      });
      return products;
    });
  }

  Future<void> updateStock(String productKey, int newStock) async {
    final stockToUpdate = newStock < 0 ? 0 : newStock;
    await _ref.child(productKey).update({'stock': stockToUpdate});
  }
}
