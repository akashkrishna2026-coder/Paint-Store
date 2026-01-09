import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:c_h_p/model/product_model.dart';
import 'package:c_h_p/data/repositories/product_repository.dart';
import 'package:c_h_p/data/repositories/home_repository.dart';

class HomeState {
  final bool loading;
  final List<Product> products;
  final Object? error;
  final int unreadCount;
  const HomeState({
    this.loading = false,
    this.products = const [],
    this.error,
    this.unreadCount = 0,
  });

  HomeState copyWith({
    bool? loading,
    List<Product>? products,
    Object? error,
    int? unreadCount,
  }) =>
      HomeState(
        loading: loading ?? this.loading,
        products: products ?? this.products,
        error: error,
        unreadCount: unreadCount ?? this.unreadCount,
      );
}

class HomeViewModel extends StateNotifier<HomeState> {
  HomeViewModel(this._productRepo, this._homeRepo) : super(const HomeState());
  final ProductRepository _productRepo;
  final HomeRepository _homeRepo;
  bool _loaded = false;
  StreamSubscription<int>? _unreadSub;
  String? _observedUid;

  Future<void> loadAllProducts() async {
    if (_loaded) return; // idempotent
    state = state.copyWith(loading: true, error: null);
    try {
      final list = await _productRepo.fetchAll();
      state = state.copyWith(loading: false, products: list, error: null);
      _loaded = true;
    } catch (e) {
      state = state.copyWith(loading: false, error: e);
    }
  }

  void observeUnread(String uid) {
    if (_observedUid == uid && _unreadSub != null) return; // idempotent per uid
    _unreadSub?.cancel();
    _observedUid = uid;
    _unreadSub = _homeRepo.unreadCountStream(uid).listen((count) {
      state = state.copyWith(unreadCount: count);
    });
  }

  @override
  void dispose() {
    _unreadSub?.cancel();
    super.dispose();
  }
}
