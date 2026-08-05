import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'auth_service.dart';

class PushNotifications {
  PushNotifications._();

  /// Attached to MaterialApp so a snackbar can be shown for messages that
  /// arrive while the app is already open (background/terminated messages
  /// are shown by the OS automatically).
  static final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await FirebaseMessaging.instance.requestPermission();

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) await _registerToken(token);
    FirebaseMessaging.instance.onTokenRefresh.listen(_registerToken);

    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      messengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('${notification.title}: ${notification.body}')),
      );
    });
  }

  static Future<void> _registerToken(String token) async {
    try {
      await AuthService.registerDeviceToken(token);
    } catch (_) {
      // Best-effort: a missed registration just means this device won't get pushes.
    }
  }
}
