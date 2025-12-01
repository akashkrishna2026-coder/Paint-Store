import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import '../model/product_model.dart';

class RecommendationService {
  static String? apiBaseUrl; // e.g. http://<server-ip>:8000

  static Future<List<String>> _apiPopular(int limit) async {
    final base = apiBaseUrl;
    if (base == null || base.isEmpty) return [];
    try {
      final uri = Uri.parse('$base/popular?limit=$limit');
      final resp =
          await http.get(uri).timeout(const Duration(milliseconds: 900));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        if (data is List) {
          return data.map((e) => e.toString()).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<List<String>> _apiSimilar(String productKey, int k) async {
    final base = apiBaseUrl;
    if (base == null || base.isEmpty) return [];
    try {
      final uri = Uri.parse('$base/similar/$productKey?k=$k');
      final resp =
          await http.get(uri).timeout(const Duration(milliseconds: 900));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        if (data is List) {
          return data.map((e) => e.toString()).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, int>> _fetchPurchaseCounts() async {
    final ref = FirebaseDatabase.instance.ref('orders');
    final snap = await ref.get();
    final Map<String, int> counts = {};
    if (!snap.exists || snap.value == null) return counts;
    final data = Map<String, dynamic>.from(snap.value as Map);
    for (final e in data.values) {
      try {
        final m = Map<String, dynamic>.from(e as Map);
        final items =
            (m['items'] is List) ? List.from(m['items']) : <dynamic>[];
        for (final it in items) {
          final key = it.toString();
          if (key.isEmpty) continue;
          counts.update(key, (v) => v + 1, ifAbsent: () => 1);
        }
      } catch (_) {}
    }
    return counts;
  }

  static Future<Map<String, Map<String, int>>> _fetchCoOccurrence() async {
    final ref = FirebaseDatabase.instance.ref('orders');
    final snap = await ref.get();
    final Map<String, Map<String, int>> co = {};
    if (!snap.exists || snap.value == null) return co;
    final data = Map<String, dynamic>.from(snap.value as Map);
    for (final e in data.values) {
      try {
        final m = Map<String, dynamic>.from(e as Map);
        final items = (m['items'] is List)
            ? List<String>.from(m['items'].map((x) => x.toString()))
            : <String>[];
        for (int i = 0; i < items.length; i++) {
          for (int j = i + 1; j < items.length; j++) {
            final a = items[i];
            final b = items[j];
            if (a == b) continue;
            co.putIfAbsent(a, () => {});
            co.putIfAbsent(b, () => {});
            co[a]!.update(b, (v) => v + 1, ifAbsent: () => 1);
            co[b]!.update(a, (v) => v + 1, ifAbsent: () => 1);
          }
        }
      } catch (_) {}
    }
    return co;
  }

  static double _cosine(Map<String, int> a, Map<String, int> b) {
    if (a.isEmpty || b.isEmpty) return 0.0;
    double dot = 0;
    double na = 0;
    double nb = 0;
    for (final v in a.values) na += v * v;
    for (final v in b.values) nb += v * v;
    final keys = <String>{...a.keys, ...b.keys};
    for (final k in keys) {
      final va = a[k] ?? 0;
      final vb = b[k] ?? 0;
      dot += va * vb;
    }
    final denom = sqrt(max(na, 1)) * sqrt(max(nb, 1));
    if (denom == 0) return 0.0;
    return dot / denom;
  }

  static Future<List<String>> recommendSimilarKeys(String productKey,
      {int k = 10}) async {
    final co = await _fetchCoOccurrence();
    if (!co.containsKey(productKey)) return [];
    final targetVec = co[productKey] ?? {};
    final scores = <String, double>{};
    for (final entry in co.entries) {
      final other = entry.key;
      if (other == productKey) continue;
      final sim = _cosine(targetVec, entry.value);
      if (sim > 0) scores[other] = sim;
    }
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(k).map((e) => e.key).toList();
  }

  static Future<List<String>> topPurchasedKeys({int limit = 10}) async {
    final counts = await _fetchPurchaseCounts();
    final list = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list.take(limit).map((e) => e.key).toList();
  }

  static Future<Product?> _fetchProduct(String key) async {
    final snap = await FirebaseDatabase.instance.ref('products/$key').get();
    if (snap.exists && snap.value != null) {
      return Product.fromMap(key, Map<String, dynamic>.from(snap.value as Map));
    }
    return null;
  }

  static Future<List<Product>> _fetchAllInStockProducts() async {
    final snap = await FirebaseDatabase.instance.ref('products').get();
    if (!snap.exists || snap.value == null) return [];
    final map = Map<String, dynamic>.from(snap.value as Map);
    final List<Product> list = [];
    map.forEach((k, v) {
      try {
        final p = Product.fromMap(k, Map<String, dynamic>.from(v));
        if (p.stock > 0) list.add(p);
      } catch (_) {}
    });
    return list;
  }

  static Future<List<Product>> fetchRecommendedProducts(
      {int limit = 10}) async {
    final apiKeys = await _apiPopular(limit);
    if (apiKeys.isNotEmpty) {
      final results = await Future.wait(apiKeys.map(_fetchProduct));
      final prods = results.whereType<Product>().toList();
      if (prods.isNotEmpty) return prods;
    }
    // Try popularity from orders
    final keys = await topPurchasedKeys(limit: limit);
    if (keys.isNotEmpty) {
      final futures = keys.map(_fetchProduct);
      final results = await Future.wait(futures);
      final prods = results.whereType<Product>().toList();
      if (prods.isNotEmpty) return prods;
    }
    // Fallback: in-stock products sorted by stock desc then name
    final all = await _fetchAllInStockProducts();
    all.sort((a, b) {
      final s = b.stock.compareTo(a.stock);
      return s != 0 ? s : a.name.compareTo(b.name);
    });
    return all.take(limit).toList();
  }

  static Future<List<Product>> fetchSimilarProducts(Product anchor,
      {int limit = 10}) async {
    final apiKeys = await _apiSimilar(anchor.key, limit * 2);
    if (apiKeys.isNotEmpty) {
      final results = (await Future.wait(apiKeys.map(_fetchProduct)))
          .whereType<Product>()
          .where((p) => p.key != anchor.key && p.stock > 0)
          .toList();
      if (results.isNotEmpty) {
        return results.take(limit).toList();
      }
    }
    // Try KNN similar
    final keys = await recommendSimilarKeys(anchor.key, k: limit * 2);
    if (keys.isNotEmpty) {
      final futures = keys.map(_fetchProduct);
      final results = (await Future.wait(futures))
          .whereType<Product>()
          .where((p) => p.key != anchor.key && p.stock > 0)
          .toList();
      if (results.isNotEmpty) {
        // trim to limit
        return results.take(limit).toList();
      }
    }
    // Fallback: same category or brand
    final all = await _fetchAllInStockProducts();
    final sameCategory = all
        .where((p) =>
            (p.category ?? '') == (anchor.category ?? '') &&
            p.key != anchor.key)
        .toList();
    if (sameCategory.isNotEmpty) {
      sameCategory.sort((a, b) => a.name.compareTo(b.name));
      return sameCategory.take(limit).toList();
    }
    final sameBrand = all
        .where((p) =>
            (p.brand ?? '') == (anchor.brand ?? '') && p.key != anchor.key)
        .toList();
    if (sameBrand.isNotEmpty) {
      sameBrand.sort((a, b) => a.name.compareTo(b.name));
      return sameBrand.take(limit).toList();
    }
    // Final fallback: top in-stock excluding self
    all.removeWhere((p) => p.key == anchor.key);
    all.sort((a, b) => b.stock.compareTo(a.stock));
    return all.take(limit).toList();
  }
}
