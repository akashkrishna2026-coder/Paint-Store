import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:c_h_p/features/home/viewmodel/home_view_model.dart';
import 'package:c_h_p/model/product_model.dart';
import 'package:c_h_p/data/repositories/product_repository.dart';
import 'package:c_h_p/data/repositories/home_repository.dart';

class _FakeProductRepository implements ProductRepository {
  final List<Product> _items;
  _FakeProductRepository(this._items);
  @override
  Future<List<Product>> fetchAll() async {
    return _items;
  }
}

class _FakeHomeRepository implements HomeRepository {
  final _controller = StreamController<int>.broadcast();
  @override
  Stream<int> unreadCountStream(String uid) => _controller.stream;
  void emit(int v) => _controller.add(v);
  Future<void> close() async => _controller.close();
}

Product _makeProduct(String key) => Product(
      key: key,
      name: 'P$key',
      description: 'desc',
      stock: 1,
      mainImageUrl: 'https://example.com/img.png',
      backgroundImageUrl: '',
      benefits: const [],
      packSizes: const [],
      brochureUrl: '',
    );

void main() {
  test('HomeViewModel loadAllProducts() populates products and clears loading',
      () async {
    final products = [_makeProduct('1'), _makeProduct('2')];
    final productRepo = _FakeProductRepository(products);
    final homeRepo = _FakeHomeRepository();
    final vm = HomeViewModel(productRepo, homeRepo);

    expect(vm.state.loading, false);
    expect(vm.state.products, isEmpty);

    await vm.loadAllProducts();

    expect(vm.state.loading, false);
    expect(vm.state.products.length, 2);
    expect(vm.state.error, isNull);

    await homeRepo.close();
  });

  test('HomeViewModel observeUnread() updates unreadCount from stream',
      () async {
    final productRepo = _FakeProductRepository([]);
    final homeRepo = _FakeHomeRepository();
    final vm = HomeViewModel(productRepo, homeRepo);

    vm.observeUnread('uid-1');

    homeRepo.emit(3);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(vm.state.unreadCount, 3);

    homeRepo.emit(0);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(vm.state.unreadCount, 0);

    await homeRepo.close();
  });
}
