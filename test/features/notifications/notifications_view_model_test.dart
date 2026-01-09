import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:c_h_p/features/notifications/viewmodel/notifications_view_model.dart';
import 'package:c_h_p/data/repositories/notifications_repository.dart';
import 'package:c_h_p/data/repositories/user_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class _FakeNotifRepo implements NotificationsRepository {
  final _dismissedCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _personalCtrl =
      StreamController<Map<String, Map<String, dynamic>>>.broadcast();
  final _globalManagersCtrl =
      StreamController<Map<String, Map<String, dynamic>>>.broadcast();
  final _globalAdminsCtrl =
      StreamController<Map<String, Map<String, dynamic>>>.broadcast();

  // Streams
  @override
  Stream<Map<String, dynamic>> dismissedMapStream(String uid) =>
      _dismissedCtrl.stream;
  @override
  Stream<Map<String, Map<String, dynamic>>> personalStream(String uid) =>
      _personalCtrl.stream;
  @override
  Stream<Map<String, Map<String, dynamic>>> globalManagersStream() =>
      _globalManagersCtrl.stream;
  @override
  Stream<Map<String, Map<String, dynamic>>> globalAdminsStream() =>
      _globalAdminsCtrl.stream;

  // Actions (no-ops for unit tests)
  @override
  Future<void> clearAll(String uid) async {}
  @override
  Future<void> deletePersonal(String uid, String key) async {}
  @override
  Future<void> dismissGlobal(String uid, String signature) async {}
  @override
  Future<void> markAllRead(String uid) async {}

  @override
  User? currentUser() => null;

  // Helpers
  void emitPersonal(Map<String, Map<String, dynamic>> v) =>
      _personalCtrl.add(v);
  void emitGlobalManagers(Map<String, Map<String, dynamic>> v) =>
      _globalManagersCtrl.add(v);
  void emitGlobalAdmins(Map<String, Map<String, dynamic>> v) =>
      _globalAdminsCtrl.add(v);
  void emitDismissed(Map<String, dynamic> v) => _dismissedCtrl.add(v);

  Future<void> close() async {
    await _dismissedCtrl.close();
    await _personalCtrl.close();
    await _globalManagersCtrl.close();
    await _globalAdminsCtrl.close();
  }
}

class _FakeUserRepo implements UserRepository {
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
  test('NotificationsViewModel merges personal only for Customer', () async {
    final notifRepo = _FakeNotifRepo();
    final userRepo = _FakeUserRepo()..role = 'Customer';
    final vm = NotificationsViewModel(notifRepo, userRepo);

    await vm.start('u1');

    notifRepo.emitPersonal({
      'p1': {'message': 'hello', 'timestamp': 1, 'type': 'x'},
    });
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(vm.state.entries.length, 1);
    expect(vm.state.entries.first.src, 'p');

    // Emit global; should be ignored for Customer
    notifRepo.emitGlobalManagers({
      'g1': {'message': 'mgr', 'timestamp': 2, 'type': 'x'},
    });
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(vm.state.entries.length, 1);

    await notifRepo.close();
  });

  test(
      'NotificationsViewModel includes global for Manager and filters dismissed',
      () async {
    final notifRepo = _FakeNotifRepo();
    final userRepo = _FakeUserRepo()..role = 'Manager';
    final vm = NotificationsViewModel(notifRepo, userRepo);

    await vm.start('u2');

    notifRepo.emitPersonal({
      'p1': {'message': 'hello', 'timestamp': 1, 'type': 'x'},
    });
    notifRepo.emitGlobalManagers({
      'g1': {'message': 'mgr', 'timestamp': 2, 'type': 'x'},
    });
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(vm.state.entries.length, 2);
    expect(vm.state.entries[0].src, anyOf('p', 'g'));

    // Dismiss the global item via signature
    notifRepo.emitDismissed({'x|2|mgr': true});
    await Future<void>.delayed(const Duration(milliseconds: 10));

    // Only personal should remain
    expect(vm.state.entries.length, 1);
    expect(vm.state.entries.first.src, 'p');

    await notifRepo.close();
  });
}
