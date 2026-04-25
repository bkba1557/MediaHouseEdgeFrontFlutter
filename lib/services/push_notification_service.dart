import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'mediahouse_general',
    'General Notifications',
    description: 'General notifications for Media House Edge',
    importance: Importance.high,
  );

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _localNotificationsReady = false;

  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  Future<void> initialize({
    required Future<void> Function() onRefreshRequested,
    required void Function(Map<String, String> data) onNotificationTap,
  }) async {
    if (_initialized) return;
    _initialized = true;

    if (!AppFirebaseOptions.isConfigured || Firebase.apps.isEmpty) {
      return;
    }

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (!kIsWeb) {
      await _initializeLocalNotifications(onNotificationTap);
    }

    FirebaseMessaging.onMessage.listen((message) async {
      await onRefreshRequested();

      if (!kIsWeb && message.notification != null) {
        await _showForegroundNotification(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      await onRefreshRequested();
      onNotificationTap(_stringifyData(message.data));
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      await onRefreshRequested();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onNotificationTap(_stringifyData(initialMessage.data));
      });
    }
  }

  Future<String?> getToken() async {
    if (!AppFirebaseOptions.isConfigured || Firebase.apps.isEmpty) {
      return null;
    }

    try {
      if (kIsWeb) {
        if (AppFirebaseOptions.webVapidKey.isEmpty) {
          return null;
        }
        return _messaging.getToken(vapidKey: AppFirebaseOptions.webVapidKey);
      }

      return _messaging.getToken();
    } catch (_) {
      return null;
    }
  }

  String currentPlatformName() {
    if (kIsWeb) return 'web';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      default:
        return 'unknown';
    }
  }

  Future<void> _initializeLocalNotifications(
    void Function(Map<String, String> data) onNotificationTap,
  ) async {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        onNotificationTap(_decodePayload(response.payload));
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    _localNotificationsReady = true;
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    if (!_localNotificationsReady) return;

    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(_stringifyData(message.data)),
    );
  }

  Map<String, String> _stringifyData(Map<String, dynamic> data) {
    return data.map((key, value) => MapEntry(key, value?.toString() ?? ''));
  }

  Map<String, String> _decodePayload(String? payload) {
    if (payload == null || payload.isEmpty) return const {};

    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) {
        return decoded.map(
          (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
        );
      }
    } catch (_) {}

    return const {};
  }
}
