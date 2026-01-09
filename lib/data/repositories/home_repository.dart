import 'dart:async';
import 'package:firebase_database/firebase_database.dart';

class HomeRepository {
  Stream<int> unreadCountStream(String uid) {
    final ref = FirebaseDatabase.instance
        .ref('users/$uid/notifications')
        .limitToLast(200);
    return ref.onValue.map<int>((event) {
      final snap = event.snapshot;
      if (!snap.exists || snap.value == null) return 0;
      try {
        final map = Map<String, dynamic>.from(snap.value as Map);
        int count = 0;
        map.forEach((key, value) {
          final v = value as Map;
          if (v['isRead'] == false) count++;
        });
        return count;
      } catch (_) {
        return 0;
      }
    }).handleError((_) => 0);
  }
}
