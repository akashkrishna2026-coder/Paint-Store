import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class OrdersRepository {
  DatabaseReference get _root => FirebaseDatabase.instance.ref();
  User? get _user => FirebaseAuth.instance.currentUser;

  Future<Map<String, dynamic>?> fetchUserProfile() async {
    final u = _user;
    if (u == null) return null;
    final snap = await _root.child('users/${u.uid}/profile').get();
    if (!snap.exists || snap.value == null) return null;
    return Map<String, dynamic>.from(snap.value as Map);
  }

  Future<void> updateUserProfile({
    required String fullName,
    required String phone,
    required String email,
    required String address,
    double? lat,
    double? lng,
  }) async {
    final u = _user;
    if (u == null) return;
    final payload = <String, dynamic>{
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'address': address,
      'updatedAt': ServerValue.timestamp,
    };
    if (lat != null && lng != null) {
      payload['location'] = {'lat': lat, 'lng': lng};
    }
    await _root.child('users/${u.uid}/profile').update(payload);
  }

  Future<List<String>> fetchCartItemNames() async {
    final u = _user;
    if (u == null) return <String>[];
    final snap = await _root.child('users/${u.uid}/cart').get();
    if (!snap.exists || snap.value == null) return <String>[];
    final cartMap = Map<String, dynamic>.from(snap.value as Map);
    final List<String> names = [];
    for (final e in cartMap.entries) {
      final v = Map<String, dynamic>.from(e.value);
      final n = (v['name'] ?? '').toString();
      if (n.isNotEmpty) names.add(n);
    }
    return names;
  }

  Future<String?> saveOrder({
    required String paymentId,
    String? signature,
    required int totalAmountPaise,
    String? deliveryAddress,
    double? lat,
    double? lng,
    String? fullName,
    String? email,
    String? phone,
    required List<String> items,
  }) async {
    final u = _user;
    if (u == null) return null;
    final userOrdersRef = _root.child('users/${u.uid}/orders');
    final orderRef = userOrdersRef.push();
    final payload = {
      'userId': u.uid,
      'orderId': orderRef.key,
      'paymentId': paymentId,
      'signature': signature,
      'orderTotal': totalAmountPaise / 100.0,
      'status': 'Payment Successful - Pending Confirmation',
      'timestamp': ServerValue.timestamp,
      'deliveryAddress': deliveryAddress ?? '',
      if (lat != null && lng != null)
        'deliveryLocation': {'lat': lat, 'lng': lng},
      'customer': {
        'name': fullName ?? '',
        'email': email ?? '',
        'phone': phone ?? '',
      },
      'items': items,
      'manager': {
        'status': 'pending',
        'eta': null,
        'notes': null,
      },
    };
    await orderRef.set(payload);
    // Mirror to global orders for manager dashboard
    try {
      await _root.child('orders').child(orderRef.key!).set(payload);
    } catch (_) {}
    return orderRef.key;
  }

  Future<void> sendPurchaseNotifications({
    required List<String> productNames,
    required int totalAmountPaise,
    String? deliveryAddress,
    double? lat,
    double? lng,
    String? fullName,
    String? email,
    String? phone,
  }) async {
    final u = _user;
    if (u == null) return;
    final productInfo =
        productNames.isNotEmpty ? productNames.join(', ') : 'Items';
    final payload = {
      'message': 'New Order: $productInfo',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'isRead': false,
      'type': 'order',
      'orderDetails': {
        'products': productNames,
        'totalAmount': totalAmountPaise / 100.0,
        'deliveryAddress': deliveryAddress ?? 'Not specified',
        if (lat != null && lng != null) 'location': {'lat': lat, 'lng': lng},
        'customer': {
          'name': fullName ?? 'N/A',
          'email': email ?? 'N/A',
          'phone': phone ?? 'N/A',
        },
      },
    };
    try {
      await _root.child('users/${u.uid}/notifications').push().set(payload);
    } catch (_) {}
    try {
      await _root.child('notifications/globalForManagers').push().set(payload);
    } catch (_) {}
    try {
      await _root.child('notifications/globalForAdmins').push().set(payload);
    } catch (_) {}
  }

  Future<void> clearCart() async {
    final u = _user;
    if (u == null) return;
    await _root.child('users/${u.uid}/cart').remove();
  }
}
