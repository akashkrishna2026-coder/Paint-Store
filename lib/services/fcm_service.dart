import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final DatabaseReference _db = FirebaseDatabase.instance.ref();

  static Future<void> initBackgroundHandler(Future<void> Function(RemoteMessage) handler) async {
    FirebaseMessaging.onBackgroundMessage(handler);
  }

  static Future<void> requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  static Future<void> updateForUser(User? user) async {
    if (user == null) return;

    final token = await _messaging.getToken();
    if (token == null) return;

    final userRef = _db.child('users/${user.uid}');
    await userRef.child('fcmTokens/$token').set({
      'platform': Platform.operatingSystem,
      'createdAt': DateTime.now().toIso8601String(),
    });
    await userRef.update({'latestFcmToken': token});

    final topic = 'user_${user.uid}';
    await _messaging.subscribeToTopic(topic);
  }

  static void listenForegroundMessages({void Function(RemoteMessage)? onMessage}) {
    FirebaseMessaging.onMessage.listen((message) {
      onMessage?.call(message);
    });
  }

  static Future<void> unsubscribeForUser(User? user) async {
    if (user == null) return;
    final topic = 'user_${user.uid}';
    await _messaging.unsubscribeFromTopic(topic);
  }
}
