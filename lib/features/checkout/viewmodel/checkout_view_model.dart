import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:c_h_p/data/repositories/orders_repository.dart';

class CheckoutState {
  final bool loading;
  final String name;
  final String phone;
  final String email;
  final String address;
  final double? lat;
  final double? lng;
  final Object? error;
  const CheckoutState({
    this.loading = false,
    this.name = '',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.lat,
    this.lng,
    this.error,
  });

  CheckoutState copyWith({
    bool? loading,
    String? name,
    String? phone,
    String? email,
    String? address,
    double? lat,
    double? lng,
    Object? error,
  }) {
    return CheckoutState(
      loading: loading ?? this.loading,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      error: error,
    );
  }
}

class CheckoutViewModel extends StateNotifier<CheckoutState> {
  CheckoutViewModel(this._ordersRepo) : super(const CheckoutState());
  final OrdersRepository _ordersRepo;

  Future<void> prefillFromAuthAndProfile() async {
    state = state.copyWith(loading: true, error: null);
    final user = FirebaseAuth.instance.currentUser;
    String name = state.name;
    String phone = state.phone;
    String email = state.email;
    String address = state.address;

    if (user != null) {
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        name = user.displayName!;
      }
      if (user.email != null && user.email!.isNotEmpty) {
        email = user.email!;
      }
      if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
        phone = user.phoneNumber!;
      }
      try {
        final profile = await _ordersRepo.fetchUserProfile();
        if (profile != null) {
          name = name.isEmpty && profile['fullName'] is String
              ? profile['fullName']
              : name;
          phone = phone.isEmpty && profile['phone'] is String
              ? profile['phone']
              : phone;
          email = email.isEmpty && profile['email'] is String
              ? profile['email']
              : email;
          address = address.isEmpty && profile['address'] is String
              ? profile['address']
              : address;
        }
      } catch (e) {
        state = state.copyWith(loading: false, error: e);
        return;
      }
    }

    state = state.copyWith(
      loading: false,
      name: name,
      phone: phone,
      email: email,
      address: address,
    );
  }

  void setLatLng(double? lat, double? lng) {
    state = state.copyWith(lat: lat, lng: lng);
  }

  Future<void> saveProfile({
    required String fullName,
    required String phone,
    required String email,
    required String address,
  }) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _ordersRepo.updateUserProfile(
        fullName: fullName,
        phone: phone,
        email: email,
        address: address,
        lat: state.lat,
        lng: state.lng,
      );
      state = state.copyWith(loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e);
    }
  }
}
