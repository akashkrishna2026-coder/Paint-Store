import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:c_h_p/data/repositories/cart_repository.dart';

class CartState {
  final bool loading;
  final Map<String, Map<String, dynamic>> items; // productKey -> cart entry
  final Object? error;
  const CartState({
    this.loading = false,
    this.items = const {},
    this.error,
  });

  CartState copyWith({
    bool? loading,
    Map<String, Map<String, dynamic>>? items,
    Object? error,
  }) {
    return CartState(
      loading: loading ?? this.loading,
      items: items ?? this.items,
      error: error,
    );
  }
}

class CartViewModel extends StateNotifier<CartState> {
  CartViewModel(this._repo) : super(const CartState()) {
    _subscribe();
  }
  final CartRepository _repo;
  StreamSubscription<Map<String, Map<String, dynamic>>>? _sub;

  void _subscribe() {
    state = state.copyWith(loading: true, error: null);
    _sub?.cancel();
    _sub = _repo.cartStream().listen((map) {
      state = state.copyWith(loading: false, items: map, error: null);
    }, onError: (e) {
      state = state.copyWith(loading: false, error: e);
    });
  }

  Future<void> updateQuantity(
      {required String productKey, required int quantity}) async {
    await _repo.updateQuantity(productKey: productKey, quantity: quantity);
  }

  Future<void> changeSize({
    required String productKey,
    required String size,
    required String price,
  }) async {
    await _repo.changeSize(productKey: productKey, size: size, price: price);
  }

  Future<void> removeItem(String productKey) async {
    await _repo.removeItem(productKey);
  }

  Future<void> clearCart() async {
    await _repo.clearCart();
  }

  Future<void> addOrUpdateItem({
    required String productKey,
    required String name,
    required String mainImageUrl,
    required String size,
    required String price,
  }) async {
    await _repo.addOrUpdateItem(
      productKey: productKey,
      name: name,
      mainImageUrl: mainImageUrl,
      size: size,
      price: price,
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
