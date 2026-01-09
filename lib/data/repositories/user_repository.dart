import 'package:firebase_database/firebase_database.dart';

class UserRepository {
  Future<String> fetchUserRole(String uid) async {
    try {
      final ref = FirebaseDatabase.instance.ref('users/$uid');
      final snap = await ref.get();
      if (!snap.exists || snap.value == null) return 'Customer';
      final map = Map<String, dynamic>.from(snap.value as Map);
      final role = (map['userType'] ?? 'Customer').toString();
      return role.isEmpty ? 'Customer' : role;
    } catch (_) {
      return 'Customer';
    }
  }

  Future<void> setUserRole({required String uid, required String role}) async {
    try {
      await FirebaseDatabase.instance.ref('users/$uid/userType').set(role);
    } catch (e) {
      rethrow;
    }
  }

  Stream<String> userRoleStream(String uid) {
    final ref = FirebaseDatabase.instance.ref('users/$uid/userType');
    return ref.onValue.map((e) {
      final val = e.snapshot.value;
      final role = (val ?? 'Customer').toString();
      return role.isEmpty ? 'Customer' : role;
    }).handleError((_) => 'Customer');
  }
}
