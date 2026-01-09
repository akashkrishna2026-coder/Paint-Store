import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class NotificationsRepository {
  DatabaseReference _db() => FirebaseDatabase.instance.ref();

  Stream<Map<String, dynamic>> dismissedMapStream(String uid) {
    return _db().child('users/$uid/dismissedNotifications').onValue.map((e) {
      if (!e.snapshot.exists || e.snapshot.value == null) {
        return <String, dynamic>{};
      }
      try {
        return Map<String, dynamic>.from(e.snapshot.value as Map);
      } catch (_) {
        return <String, dynamic>{};
      }
    });
  }

  Stream<Map<String, Map<String, dynamic>>> personalStream(String uid) {
    return _db()
        .child('users/$uid/notifications')
        .orderByChild('timestamp')
        .limitToLast(100)
        .onValue
        .map((e) {
      if (!e.snapshot.exists || e.snapshot.value == null) {
        return <String, Map<String, dynamic>>{};
      }
      final map = Map<String, dynamic>.from(e.snapshot.value as Map);
      final out = <String, Map<String, dynamic>>{};
      map.forEach((k, v) {
        try {
          out[k] = Map<String, dynamic>.from(v);
        } catch (_) {}
      });
      return out;
    });
  }

  Stream<Map<String, Map<String, dynamic>>> globalManagersStream() {
    return _db()
        .child('notifications/globalForManagers')
        .orderByChild('timestamp')
        .limitToLast(100)
        .onValue
        .map((e) {
      if (!e.snapshot.exists || e.snapshot.value == null) {
        return <String, Map<String, dynamic>>{};
      }
      final map = Map<String, dynamic>.from(e.snapshot.value as Map);
      final out = <String, Map<String, dynamic>>{};
      map.forEach((k, v) {
        try {
          out[k] = Map<String, dynamic>.from(v);
        } catch (_) {}
      });
      return out;
    });
  }

  Stream<Map<String, Map<String, dynamic>>> globalAdminsStream() {
    return _db()
        .child('notifications/globalForAdmins')
        .orderByChild('timestamp')
        .limitToLast(100)
        .onValue
        .map((e) {
      if (!e.snapshot.exists || e.snapshot.value == null) {
        return <String, Map<String, dynamic>>{};
      }
      final map = Map<String, dynamic>.from(e.snapshot.value as Map);
      final out = <String, Map<String, dynamic>>{};
      map.forEach((k, v) {
        try {
          out[k] = Map<String, dynamic>.from(v);
        } catch (_) {}
      });
      return out;
    });
  }

  Future<void> markAllRead(String uid) async {
    final ref = _db().child('users/$uid/notifications');
    final snap = await ref.get();
    if (!snap.exists || snap.value == null) return;
    final updates = <String, dynamic>{};
    for (final c in snap.children) {
      final v = c.value;
      bool alreadyTrue = false;
      if (v is Map) {
        final isReadVal = v['isRead'];
        alreadyTrue = isReadVal == true;
      }
      if (!alreadyTrue) {
        updates['${c.key}/isRead'] = true;
      }
    }
    if (updates.isNotEmpty) await ref.update(updates);
  }

  Future<void> clearAll(String uid) async {
    await _db().child('users/$uid/notifications').remove();
  }

  Future<void> dismissGlobal(String uid, String signature) async {
    await _db().child('users/$uid/dismissedNotifications/$signature').set(true);
  }

  Future<void> deletePersonal(String uid, String key) async {
    await _db().child('users/$uid/notifications/$key').remove();
  }

  User? currentUser() => FirebaseAuth.instance.currentUser;
}
