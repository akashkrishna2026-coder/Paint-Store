import 'package:firebase_database/firebase_database.dart';
import 'package:c_h_p/model/painter_model.dart';

class PaintersRepository {
  DatabaseReference get _db => FirebaseDatabase.instance.ref();

  Stream<List<Painter>> paintersStream() {
    return _db.child('painters').onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return <Painter>[];
      }
      final raw = Map<String, dynamic>.from(event.snapshot.value as Map);
      final list = <Painter>[];
      raw.forEach((key, value) {
        try {
          list.add(Painter.fromMap(key, value));
        } catch (_) {}
      });
      return list;
    });
  }
}
