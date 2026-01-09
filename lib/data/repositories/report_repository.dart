import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ReportRepository {
  DatabaseReference get _db => FirebaseDatabase.instance.ref();
  User? get _user => FirebaseAuth.instance.currentUser;

  Future<void> submitIssue(String issueText) async {
    final u = _user;
    if (u == null) throw Exception('Not authenticated');
    await _db.child('reports').push().set({
      'userId': u.uid,
      'name': u.displayName ?? 'Anonymous',
      'email': u.email ?? 'No Email',
      'issue': issueText,
      'timestamp': ServerValue.timestamp,
      'status': 'Pending',
    });
  }

  Stream<List<MapEntry<String, Map<String, dynamic>>>> reportsStream() {
    return _db.child('reports').onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return <MapEntry<String, Map<String, dynamic>>>[];
      }
      final raw = Map<String, dynamic>.from(event.snapshot.value as Map);
      final list = raw.entries.map((e) {
        final v = Map<String, dynamic>.from(e.value as Map);
        return MapEntry<String, Map<String, dynamic>>(e.key, v);
      }).toList();
      list.sort((a, b) {
        final at = (a.value['timestamp'] ?? 0) as int;
        final bt = (b.value['timestamp'] ?? 0) as int;
        return bt.compareTo(at);
      });
      return list;
    });
  }

  Future<void> resolveReport({
    required String reportKey,
    required String userId,
    required String issueText,
  }) async {
    await _db.child('reports/$reportKey').update({'status': 'Resolved'});
    final shortIssue =
        issueText.length > 30 ? '${issueText.substring(0, 30)}...' : issueText;
    await _db.child('users/$userId/notifications').push().set({
      'message':
          'Your report about "$shortIssue" has been received and is now being processed.',
      'timestamp': ServerValue.timestamp,
      'isRead': false,
    });
  }
}
