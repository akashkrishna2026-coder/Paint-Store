import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:c_h_p/features/user/viewmodel/user_view_model.dart';
import 'package:c_h_p/data/repositories/user_repository.dart';

class _FakeUserRepository implements UserRepository {
  String role = 'Customer';
  @override
  Future<String> fetchUserRole(String uid) async => role;

  @override
  Future<void> setUserRole({required String uid, required String role}) async {
    this.role = role;
  }

  @override
  Stream<String> userRoleStream(String uid) => Stream.value(role);
}

void main() {
  test('UserViewModel loads role successfully', () async {
    final repo = _FakeUserRepository();
    repo.role = 'Manager';
    final vm = UserViewModel(repo);

    expect(vm.state.role, 'Customer');
    await vm.loadForUid('u1', displayName: 'Name', photoUrl: 'url');
    expect(vm.state.loading, false);
    expect(vm.state.role, 'Manager');
    expect(vm.state.error, isNull);
  });

  test('UserViewModel handles repository error', () async {
    final repo = _FakeUserRepositoryWithError();
    final vm = UserViewModel(repo);

    await vm.loadForUid('u2');
    expect(vm.state.loading, false);
    expect(vm.state.error, isNotNull);
  });
}

class _FakeUserRepositoryWithError implements UserRepository {
  @override
  Future<String> fetchUserRole(String uid) async => throw Exception('fail');

  @override
  Future<void> setUserRole({required String uid, required String role}) async {}

  @override
  Stream<String> userRoleStream(String uid) => const Stream.empty();
}
