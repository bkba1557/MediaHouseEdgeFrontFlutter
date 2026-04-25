import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/admin_user.dart';
import 'auth_provider.dart';

class UserManagementProvider with ChangeNotifier {
  List<AdminUser> _users = [];
  bool _isLoading = false;
  final Set<String> _updatingIds = <String>{};

  String? _authToken;
  String _search = '';
  String _role = 'client';
  bool _isAdmin = false;

  String get _baseUrl => AppConfig.apiBaseUrl;

  List<AdminUser> get users => List.unmodifiable(_users);
  bool get isLoading => _isLoading;
  String get search => _search;

  bool isUpdating(String userId) => _updatingIds.contains(userId);

  void syncAuth(AuthProvider authProvider) {
    final nextToken = authProvider.token;
    final nextIsAdmin =
        authProvider.isAdmin && nextToken != null && nextToken.isNotEmpty;

    if (!nextIsAdmin) {
      _authToken = null;
      _isAdmin = false;
      _users = [];
      _updatingIds.clear();
      notifyListeners();
      return;
    }

    if (_authToken == nextToken && _isAdmin == nextIsAdmin) {
      return;
    }

    _authToken = nextToken;
    _isAdmin = nextIsAdmin;
    unawaited(fetchUsers(search: _search, role: _role));
  }

  Future<void> fetchUsers({String? search, String? role}) async {
    final authToken = _authToken;
    if (authToken == null || authToken.isEmpty) return;

    _search = search ?? _search;
    _role = role ?? _role;
    _isLoading = true;
    notifyListeners();

    try {
      final query = Uri(
        queryParameters: {
          if (_search.trim().isNotEmpty) 'search': _search.trim(),
          if (_role.trim().isNotEmpty) 'role': _role.trim(),
        },
      ).query;

      final response = await http.get(
        Uri.parse('$_baseUrl/users${query.isEmpty ? '' : '?$query'}'),
        headers: {'Authorization': 'Bearer $authToken'},
      );

      if (response.statusCode != 200) {
        throw Exception(_extractError(response.body, 'Failed to load users'));
      }

      final decoded = json.decode(response.body);
      _users = decoded is List
          ? decoded
                .whereType<Map>()
                .map((item) => AdminUser.fromJson(item.cast<String, dynamic>()))
                .toList(growable: false)
          : const [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateCustomerTier({
    required String userId,
    required String customerTier,
  }) async {
    final authToken = _authToken;
    if (authToken == null || authToken.isEmpty) {
      throw Exception('Missing auth token');
    }

    _updatingIds.add(userId);
    notifyListeners();

    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/users/$userId/customer-tier'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({'customerTier': customerTier}),
      );

      if (response.statusCode != 200) {
        throw Exception(
          _extractError(response.body, 'Failed to update customer tier'),
        );
      }

      _users = _users
          .map((user) {
            if (user.id != userId) return user;
            return user.copyWith(customerTier: customerTier);
          })
          .toList(growable: false);
    } finally {
      _updatingIds.remove(userId);
      notifyListeners();
    }
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
}
