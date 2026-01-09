import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:c_h_p/model/product_model.dart';
import 'package:c_h_p/data/repositories/recommendation_repository.dart';

class ExploreState {
  final bool loading;
  final List<Product> items;
  final Object? error;
  const ExploreState({this.loading = false, this.items = const [], this.error});

  ExploreState copyWith({bool? loading, List<Product>? items, Object? error}) =>
      ExploreState(
        loading: loading ?? this.loading,
        items: items ?? this.items,
        error: error,
      );
}

class ExploreViewModel extends StateNotifier<ExploreState> {
  ExploreViewModel(this._repo) : super(const ExploreState(loading: true));
  final RecommendationRepository _repo;
  bool _loaded = false;

  Future<void> loadRecommended({int limit = 10}) async {
    if (_loaded) return; // idempotent
    state = state.copyWith(loading: true, error: null);
    try {
      final items = await _repo.fetchRecommended(limit: limit);
      state = state.copyWith(loading: false, items: items, error: null);
      _loaded = true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e);
    }
  }

  Future<void> precacheHeroImages(BuildContext context) async {
    try {
      await Future.wait([
        precacheImage(const AssetImage('assets/image_b8a96a.jpg'), context),
        precacheImage(const AssetImage('assets/image_b8aca7.jpg'), context),
        precacheImage(const AssetImage('assets/image_b8b0ca.jpg'), context),
      ]);
    } catch (_) {
      // ignore precache errors
    }
  }
}
