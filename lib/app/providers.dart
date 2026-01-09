import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:c_h_p/model/product_model.dart';
import 'package:c_h_p/services/recommendation_service.dart';
import 'package:c_h_p/data/repositories/recommendation_repository.dart';
import 'package:c_h_p/features/explore/viewmodel/explore_view_model.dart';
import 'package:c_h_p/data/repositories/product_repository.dart';
import 'package:c_h_p/features/home/viewmodel/home_view_model.dart';
import 'package:c_h_p/data/repositories/home_repository.dart';
import 'package:c_h_p/data/repositories/user_repository.dart';
import 'package:c_h_p/features/user/viewmodel/user_view_model.dart';
import 'package:c_h_p/data/repositories/notifications_repository.dart';
import 'package:c_h_p/features/notifications/viewmodel/notifications_view_model.dart';
import 'package:c_h_p/data/repositories/stock_repository.dart';
import 'package:c_h_p/features/stock/viewmodel/stock_view_model.dart';
import 'package:c_h_p/data/repositories/orders_repository.dart';
import 'package:c_h_p/features/checkout/viewmodel/checkout_view_model.dart';
import 'package:c_h_p/features/payment/viewmodel/payment_view_model.dart';
import 'package:c_h_p/data/repositories/report_repository.dart';
import 'package:c_h_p/features/report/viewmodel/report_view_model.dart';
import 'package:c_h_p/data/repositories/cart_repository.dart';
import 'package:c_h_p/features/cart/viewmodel/cart_view_model.dart';
import 'package:c_h_p/data/repositories/painters_repository.dart';
import 'package:c_h_p/features/painters/viewmodel/painters_view_model.dart';
import 'package:c_h_p/features/visualizer/viewmodel/visualizer_view_model.dart';

final recommendedProductsProvider = FutureProvider<List<Product>>((ref) async {
  return RecommendationService.fetchRecommendedProducts(limit: 10);
});

final recommendationRepositoryProvider =
    Provider<RecommendationRepository>((ref) {
  return RecommendationRepository();
});

final exploreVMProvider =
    StateNotifierProvider<ExploreViewModel, ExploreState>((ref) {
  final repo = ref.read(recommendationRepositoryProvider);
  return ExploreViewModel(repo);
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository();
});

final homeVMProvider = StateNotifierProvider<HomeViewModel, HomeState>((ref) {
  final productRepo = ref.read(productRepositoryProvider);
  final homeRepo = ref.read(homeRepositoryProvider);
  return HomeViewModel(productRepo, homeRepo);
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

final userVMProvider = StateNotifierProvider<UserViewModel, UserState>((ref) {
  final repo = ref.read(userRepositoryProvider);
  return UserViewModel(repo);
});

final notificationsRepositoryProvider =
    Provider<NotificationsRepository>((ref) => NotificationsRepository());

final notificationsVMProvider =
    StateNotifierProvider<NotificationsViewModel, NotificationsState>((ref) {
  final repo = ref.read(notificationsRepositoryProvider);
  final userRepo = ref.read(userRepositoryProvider);
  return NotificationsViewModel(repo, userRepo);
});

final stockRepositoryProvider = Provider<StockRepository>((ref) {
  return StockRepository();
});

final stockVMProvider =
    StateNotifierProvider<StockViewModel, StockState>((ref) {
  final repo = ref.read(stockRepositoryProvider);
  return StockViewModel(repo);
});

// Checkout/Payment
final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return OrdersRepository();
});

final checkoutVMProvider =
    StateNotifierProvider<CheckoutViewModel, CheckoutState>((ref) {
  final repo = ref.read(ordersRepositoryProvider);
  return CheckoutViewModel(repo);
});

final paymentVMProvider =
    StateNotifierProvider<PaymentViewModel, PaymentState>((ref) {
  final repo = ref.read(ordersRepositoryProvider);
  return PaymentViewModel(repo);
});

// Report Issue MVVM
final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository();
});

final reportVMProvider =
    StateNotifierProvider<ReportViewModel, ReportState>((ref) {
  final repo = ref.read(reportRepositoryProvider);
  return ReportViewModel(repo);
});

// Cart MVVM
final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepository();
});

final cartVMProvider = StateNotifierProvider<CartViewModel, CartState>((ref) {
  final repo = ref.read(cartRepositoryProvider);
  return CartViewModel(repo);
});

// Painters MVVM
final paintersRepositoryProvider = Provider<PaintersRepository>((ref) {
  return PaintersRepository();
});

final paintersVMProvider =
    StateNotifierProvider<PaintersViewModel, PaintersState>((ref) {
  final repo = ref.read(paintersRepositoryProvider);
  return PaintersViewModel(repo);
});

// Visualizer MVVM
final visualizerVMProvider =
    StateNotifierProvider<VisualizerViewModel, VisualizerState>((ref) {
  return VisualizerViewModel();
});
