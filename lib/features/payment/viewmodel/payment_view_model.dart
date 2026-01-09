import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:c_h_p/data/repositories/orders_repository.dart';

class PaymentState {
  final bool processing;
  final bool completed;
  final String? lastOrderId;
  final Object? error;
  const PaymentState({
    this.processing = false,
    this.completed = false,
    this.lastOrderId,
    this.error,
  });

  PaymentState copyWith({
    bool? processing,
    bool? completed,
    String? lastOrderId,
    Object? error,
  }) =>
      PaymentState(
        processing: processing ?? this.processing,
        completed: completed ?? this.completed,
        lastOrderId: lastOrderId ?? this.lastOrderId,
        error: error,
      );
}

class PaymentViewModel extends StateNotifier<PaymentState> {
  PaymentViewModel(this._ordersRepo) : super(const PaymentState());
  final OrdersRepository _ordersRepo;

  Future<String?> handlePaymentSuccess({
    required String paymentId,
    String? signature,
    required int totalAmountPaise,
    String? deliveryAddress,
    double? lat,
    double? lng,
    String? fullName,
    String? email,
    String? phone,
  }) async {
    state = state.copyWith(processing: true, completed: false, error: null);
    try {
      final items = await _ordersRepo.fetchCartItemNames();
      final orderId = await _ordersRepo.saveOrder(
        paymentId: paymentId,
        signature: signature,
        totalAmountPaise: totalAmountPaise,
        deliveryAddress: deliveryAddress,
        lat: lat,
        lng: lng,
        fullName: fullName,
        email: email,
        phone: phone,
        items: items,
      );
      await _ordersRepo.sendPurchaseNotifications(
        productNames: items,
        totalAmountPaise: totalAmountPaise,
        deliveryAddress: deliveryAddress,
        lat: lat,
        lng: lng,
        fullName: fullName,
        email: email,
        phone: phone,
      );
      await _ordersRepo.clearCart();
      state = state.copyWith(
          processing: false, completed: true, lastOrderId: orderId);
      return orderId;
    } catch (e) {
      state = state.copyWith(processing: false, completed: false, error: e);
      rethrow;
    }
  }
}
