import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:c_h_p/data/repositories/user_repository.dart';

class UserState {
  final bool loading;
  final String role;
  final String? displayName;
  final String? photoUrl;
  final Object? error;
  const UserState({
    this.loading = false,
    this.role = 'Customer',
    this.displayName,
    this.photoUrl,
    this.error,
  });

  UserState copyWith({
    bool? loading,
    String? role,
    String? displayName,
    String? photoUrl,
    Object? error,
  }) =>
      UserState(
        loading: loading ?? this.loading,
        role: role ?? this.role,
        displayName: displayName ?? this.displayName,
        photoUrl: photoUrl ?? this.photoUrl,
        error: error,
      );
}

class UserViewModel extends StateNotifier<UserState> {
  UserViewModel(this._repo) : super(const UserState());
  final UserRepository _repo;

  Future<void> loadForUid(String uid,
      {String? displayName, String? photoUrl}) async {
    state = state.copyWith(
        loading: true,
        error: null,
        displayName: displayName,
        photoUrl: photoUrl);
    try {
      final role = await _repo.fetchUserRole(uid);
      state = state.copyWith(loading: false, role: role, error: null);
    } catch (e) {
      state = state.copyWith(loading: false, error: e);
    }
  }
}
