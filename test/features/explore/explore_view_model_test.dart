import 'package:flutter_test/flutter_test.dart';
import 'package:c_h_p/features/explore/viewmodel/explore_view_model.dart';
import 'package:c_h_p/data/repositories/recommendation_repository.dart';
import 'package:c_h_p/model/product_model.dart';

class _FakeRecommendationRepository extends RecommendationRepository {
  @override
  Future<List<Product>> fetchRecommended({int limit = 10}) async {
    return [
      Product(
        key: 'p1',
        name: 'Sample Paint',
        brand: 'BrandX',
        category: 'interior',
        description: 'desc',
        stock: 10,
        subCategory: 'wall',
        mainImageUrl: 'https://example.com/img.png',
        backgroundImageUrl: 'https://example.com/bg.png',
        benefits: const [],
        packSizes: const [],
        brochureUrl: 'https://example.com/brochure.pdf',
      ),
    ];
  }
}

void main() {
  test('ExploreViewModel loads recommended products successfully', () async {
    final repo = _FakeRecommendationRepository();
    final vm = ExploreViewModel(repo as dynamic);

    expect(vm.state.loading, true);
    await vm.loadRecommended(limit: 1);
    expect(vm.state.loading, false);
    expect(vm.state.items.length, 1);
    expect(vm.state.error, isNull);
  });

  test('ExploreViewModel handles error', () async {
    final repo = _ErrorRecommendationRepository();
    final vm = ExploreViewModel(repo as dynamic);

    await vm.loadRecommended(limit: 1);
    expect(vm.state.loading, false);
    expect(vm.state.items, isEmpty);
    expect(vm.state.error, isNotNull);
  });
}

class _ErrorRecommendationRepository extends RecommendationRepository {
  @override
  Future<List<Product>> fetchRecommended({int limit = 10}) async {
    throw Exception('boom');
  }
}
