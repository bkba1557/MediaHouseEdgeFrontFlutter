import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../config/app_navigator.dart';
import '../models/app_notification.dart';
import '../services/push_notification_service.dart';
import 'auth_provider.dart';

class NotificationProvider with ChangeNotifier {
  final PushNotificationService _pushService = PushNotificationService.instance;

  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  bool _isSending = false;
  int _unreadCount = 0;

  String? _authToken;
  String? _userId;
  String? _activeSessionKey;
  String? _registeredPushToken;
  bool _messagingInitialized = false;
  StreamSubscription<String>? _tokenRefreshSubscription;

  String get _baseUrl => AppConfig.apiBaseUrl;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  int get unreadCount => _unreadCount;

  void syncAuth(AuthProvider authProvider) {
    final previousAuthToken = _authToken;
    final previousPushToken = _registeredPushToken;
    final hadSession = _hasActiveSession;

    _authToken = authProvider.token;
    _userId = authProvider.user?.id;

    final eligibleUser =
        authProvider.user != null &&
        !authProvider.user!.isGuest &&
        authProvider.isAuthenticated;

    if (!eligibleUser) {
      _activeSessionKey = null;
      _registeredPushToken = null;
      _notifications = [];
      _unreadCount = 0;
      _isLoading = false;
      _isSending = false;
      notifyListeners();

      if (hadSession &&
          previousAuthToken != null &&
          previousAuthToken.isNotEmpty &&
          previousPushToken != null &&
          previousPushToken.isNotEmpty) {
        unawaited(_unregisterPushToken(previousAuthToken, previousPushToken));
      }
      return;
    }

    final nextSessionKey = '${_userId ?? ''}:${_authToken ?? ''}';
    if (_activeSessionKey == nextSessionKey) {
      return;
    }

    _activeSessionKey = nextSessionKey;
    unawaited(_activateSession());
  }

  Future<void> fetchNotifications({bool silent = false}) async {
    final authToken = _authToken;
    if (authToken == null || authToken.isEmpty) return;

    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/notifications'),
        headers: {'Authorization': 'Bearer $authToken'},
      );

      if (response.statusCode != 200) {
        final error = _extractError(
          response.body,
          'Failed to load notifications',
        );
        if (!silent) {
          throw Exception(error);
        }
        return;
      }

      final decoded = json.decode(response.body);
      final notificationJson = decoded is Map<String, dynamic>
          ? decoded['notifications']
          : null;

      _notifications = notificationJson is List
          ? notificationJson
                .whereType<Map>()
                .map(
                  (item) =>
                      AppNotification.fromJson(item.cast<String, dynamic>()),
                )
                .toList(growable: false)
          : const [];
      _unreadCount =
          decoded is Map<String, dynamic> && decoded['unreadCount'] is num
          ? (decoded['unreadCount'] as num).toInt()
          : _notifications.where((item) => !item.isRead).length;
    } finally {
      if (!silent) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    final authToken = _authToken;
    if (authToken == null || authToken.isEmpty) return;

    final response = await http.patch(
      Uri.parse('$_baseUrl/notifications/$id/read'),
      headers: {'Authorization': 'Bearer $authToken'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        _extractError(response.body, 'Failed to mark notification as read'),
      );
    }

    _notifications = _notifications
        .map((notification) {
          if (notification.id != id || notification.isRead) {
            return notification;
          }
          return notification.copyWith(isRead: true, readAt: DateTime.now());
        })
        .toList(growable: false);

    _unreadCount = _notifications.where((item) => !item.isRead).length;
    notifyListeners();
  }

  Future<void> markAllAsRead() async {
    final authToken = _authToken;
    if (authToken == null || authToken.isEmpty) return;

    final response = await http.patch(
      Uri.parse('$_baseUrl/notifications/read-all'),
      headers: {'Authorization': 'Bearer $authToken'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        _extractError(
          response.body,
          'Failed to mark all notifications as read',
        ),
      );
    }

    final now = DateTime.now();
    _notifications = _notifications
        .map((notification) => notification.copyWith(isRead: true, readAt: now))
        .toList(growable: false);
    _unreadCount = 0;
    notifyListeners();
  }

  Future<void> sendPromotion({
    required String title,
    required String body,
    required String audience,
    String? userId,
  }) async {
    final authToken = _authToken;
    if (authToken == null || authToken.isEmpty) {
      throw Exception('Missing auth token');
    }

    _isSending = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/notifications/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({
          'title': title,
          'body': body,
          'audience': audience,
          if (userId != null && userId.isNotEmpty) 'userId': userId,
          'type': 'promo',
          'data': {'screen': 'notifications'},
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
          _extractError(response.body, 'Failed to send notification'),
        );
      }
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<void> _activateSession() async {
    try {
      await _ensureMessagingInitialized();
      await fetchNotifications(silent: true);
      await _registerCurrentPushToken();
    } catch (_) {
      // Keep the app usable even when notification bootstrapping fails.
    }
  }

  Future<void> _ensureMessagingInitialized() async {
    if (_messagingInitialized) return;
    _messagingInitialized = true;

    await _pushService.initialize(
      onRefreshRequested: () async {
        if (_hasActiveSession) {
          await fetchNotifications(silent: true);
        }
      },
      onNotificationTap: (data) {
        final navigator = rootNavigatorKey.currentState;
        if (navigator == null) return;
        navigator.pushNamed('/notifications');
      },
    );

    _tokenRefreshSubscription ??= _pushService.onTokenRefresh.listen((token) {
      _registeredPushToken = token;
      if (_hasActiveSession) {
        unawaited(_registerPushToken(token));
      }
    });
  }

  Future<void> _registerCurrentPushToken() async {
    final pushToken = await _pushService.getToken();
    if (pushToken == null || pushToken.isEmpty) return;

    _registeredPushToken = pushToken;
    await _registerPushToken(pushToken);
  }

  Future<void> _registerPushToken(String pushToken) async {
    final authToken = _authToken;
    if (authToken == null || authToken.isEmpty || pushToken.isEmpty) return;

    try {
      await http.post(
        Uri.parse('$_baseUrl/notifications/device-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({
          'token': pushToken,
          'platform': _pushService.currentPlatformName(),
        }),
      );
    } catch (_) {}
  }

  Future<void> _unregisterPushToken(String authToken, String pushToken) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/notifications/device-token/remove'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({'token': pushToken}),
      );
    } catch (_) {}
  }

  bool get _hasActiveSession {
    return _authToken != null &&
        _authToken!.isNotEmpty &&
        _userId != null &&
        _userId!.isNotEmpty;
  }

  String _extractError(String body, String fallback) {
    try {
      final decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'];
        if (message is String && message.isNotEmpty) {
          return message;
        }
      }
    } catch (_) {}

    return fallback;
  }

  @override
  void dispose() {
    _tokenRefreshSubscription?.cancel();
    super.dispose();
  }
}
