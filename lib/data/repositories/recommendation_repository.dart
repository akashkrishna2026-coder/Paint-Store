import 'package:c_h_p/model/product_model.dart';
import 'package:c_h_p/services/recommendation_service.dart';

/// Repository layer for recommendations. Wraps the existing service for MVVM.
class RecommendationRepository {
  Future<List<Product>> fetchRecommended({int limit = 10}) async {
    return RecommendationService.fetchRecommendedProducts(limit: limit);
  }
}
