import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;
  bool _isLoading = false;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  bool get isAdmin => _user?.isAdmin ?? false;

  String get _baseUrl => AppConfig.apiBaseUrl;

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode != 200) {
        throw Exception(_extractError(response.body, 'Login failed'));
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String username, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'email': email,
          'password': password,
          'role': 'client',
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(_extractError(response.body, 'Registration failed'));
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> guestLogin() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/guest'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = data['token'];
        _user = User.fromJson(data['user']);
        await _saveAuthData();
        notifyListeners();
      } else {
        throw Exception('Guest login failed');
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveAuthData() async {
    if (_token == null || _token!.isEmpty || _user == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', _token!);
    await prefs.setString(
      'user',
      json.encode({
        'id': _user!.id,
        'username': _user!.username,
        'email': _user!.email,
        'role': _user!.role,
      }),
    );
  }

  Future<void> loadAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userString = prefs.getString('user');

    if (token == null || token.isEmpty || userString == null || userString.isEmpty) {
      return;
    }

    try {
      final decoded = json.decode(userString);
      if (decoded is Map<String, dynamic>) {
        _token = token;
        _user = User.fromJson(decoded);
      } else {
        throw const FormatException('Invalid user json');
      }
    } catch (_) {
      await prefs.remove('token');
      await prefs.remove('user');
      _token = null;
      _user = null;
    } finally {
      notifyListeners();
    }
  }

  Future<void> verifyLoginOtp(String email, String otp) async {
    await _verifyOtp('$_baseUrl/auth/login/verify', {
      'email': email,
      'otp': otp,
    });
  }

  Future<void> verifyRegisterOtp(String email, String otp) async {
    await _verifyOtp('$_baseUrl/auth/register/verify', {
      'email': email,
      'otp': otp,
    });
  }

  Future<void> _verifyOtp(String url, Map<String, String> body) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = data['token'];
        _user = User.fromJson(data['user']);
        await _saveAuthData();
        notifyListeners();
      } else {
        throw Exception(_extractError(response.body, 'Verification failed'));
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _token = null;
    _user = null;
    notifyListeners();
  }

  String _extractError(String body, String fallback) {
    try {
      final data = json.decode(body);
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.isNotEmpty) return message;
      }
    } catch (_) {}
    return fallback;
  }
}
