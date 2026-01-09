import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:c_h_p/model/product_model.dart';
import 'package:c_h_p/data/repositories/stock_repository.dart';

class StockState {
  final bool loading;
  final List<Product> products;
  final Object? error;
  const StockState(
      {this.loading = false, this.products = const [], this.error});

  StockState copyWith(
          {bool? loading, List<Product>? products, Object? error}) =>
      StockState(
        loading: loading ?? this.loading,
        products: products ?? this.products,
        error: error,
      );
}

class StockViewModel extends StateNotifier<StockState> {
  StockViewModel(this._repo) : super(const StockState()) {
    _listen();
  }
  final StockRepository _repo;
  StreamSubscription<List<Product>>? _sub;

  void _listen() {
    state = state.copyWith(loading: true, error: null);
    _sub?.cancel();
    _sub = _repo.productsStream().listen((list) {
      state = state.copyWith(loading: false, products: list, error: null);
    }, onError: (e) {
      state = state.copyWith(loading: false, error: e);
    });
  }

  Future<void> updateStock(String productKey, int newStock) =>
      _repo.updateStock(productKey, newStock);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
