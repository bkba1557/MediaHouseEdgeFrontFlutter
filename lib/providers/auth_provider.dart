import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  User? _user;
  String? _token;
  bool _isLoading = false;
  Future<void>? _googleInitialization;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  bool get isAdmin => _user?.isAdmin ?? false;

  String get _baseUrl => AppConfig.apiBaseUrl;

  firebase_auth.FirebaseAuth get _firebaseAuth {
    if (Firebase.apps.isEmpty) {
      throw Exception(
        'Social sign-in requires Firebase to be configured for this app.',
      );
    }
    return firebase_auth.FirebaseAuth.instance;
  }

  Future<void> login(String email, String password) async {
    await loginWithPassword(email, password);
  }

  Future<void> loginWithPassword(String email, String password) async {
    await _authenticate('$_baseUrl/auth/login', {
      'email': email.trim(),
      'password': password,
    }, fallbackMessage: 'Login failed');
  }

  Future<void> requestLoginOtp(String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login/request-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email.trim()}),
      );

      if (response.statusCode != 200) {
        throw Exception(
          _extractError(response.body, 'Unable to send login code'),
        );
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

  Future<void> signInWithGoogle() async {
    await _runWithLoading(() async {
      await _ensureFirebaseConfigured();
      await _ensureGoogleInitialized();
      final googleUser = await _googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception('Google sign-in did not return an ID token');
      }

      final credential = firebase_auth.GoogleAuthProvider.credential(
        idToken: idToken,
      );
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      await _completeFirebaseSocialLogin(
        provider: 'google',
        firebaseUser: userCredential.user,
      );
    });
  }

  Future<void> signInWithApple() async {
    await _runWithLoading(() async {
      await _ensureFirebaseConfigured();

      if (!_supportsAppleOnCurrentPlatform()) {
        throw Exception('Apple sign-in is not supported on this platform');
      }

      final provider = firebase_auth.AppleAuthProvider();
      final credential = kIsWeb
          ? await _firebaseAuth.signInWithPopup(provider)
          : await _firebaseAuth.signInWithProvider(provider);

      await _completeFirebaseSocialLogin(
        provider: 'apple',
        firebaseUser: credential.user,
      );
    });
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
        await _storeAuthResponse(response.body);
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
    await prefs.setString('user', json.encode(_user!.toJson()));
  }

  Future<void> loadAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userString = prefs.getString('user');

    if (token == null ||
        token.isEmpty ||
        userString == null ||
        userString.isEmpty) {
      return;
    }

    try {
      final decoded = json.decode(userString);
      if (decoded is Map<String, dynamic>) {
        _token = token;
        _user = User.fromJson(decoded);
        await refreshProfile(silent: true);
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

  Future<void> refreshProfile({bool silent = false}) async {
    final token = _token;
    if (token == null || token.isEmpty || (_user?.isGuest ?? false)) {
      return;
    }

    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final userJson = data is Map<String, dynamic> ? data['user'] : null;
        if (userJson is Map<String, dynamic>) {
          _user = User.fromJson(userJson);
          await _saveAuthData();
        }
      }
    } catch (_) {
      // Keep cached auth data when the refresh fails.
    } finally {
      if (!silent) {
        _isLoading = false;
        notifyListeners();
      }
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

  Future<void> _authenticate(
    String url,
    Map<String, String> body, {
    required String fallbackMessage,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        await _storeAuthResponse(response.body);
      } else {
        throw Exception(_extractError(response.body, fallbackMessage));
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
        await _storeAuthResponse(response.body);
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

  Future<void> _runWithLoading(Future<void> Function() action) async {
    _isLoading = true;
    notifyListeners();

    try {
      await action();
    } on firebase_auth.FirebaseAuthException catch (error) {
      await _clearFirebaseSession();
      throw Exception(error.message ?? 'Authentication failed');
    } catch (error) {
      await _clearFirebaseSession();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _ensureFirebaseConfigured() async {
    if (Firebase.apps.isEmpty) {
      throw Exception(
        'Social sign-in requires Firebase to be configured for this app.',
      );
    }
  }

  Future<void> _ensureGoogleInitialized() async {
    if (!_supportsGoogleOnCurrentPlatform()) {
      throw Exception('Google sign-in is not supported on this platform');
    }

    if (kIsWeb && AppConfig.googleClientId.isEmpty) {
      throw Exception('Google sign-in on web requires GOOGLE_CLIENT_ID.');
    }

    if ((defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS) &&
        AppConfig.googleClientId.isEmpty) {
      throw Exception(
        'Google sign-in on Apple platforms requires GOOGLE_CLIENT_ID.',
      );
    }

    if (AppConfig.googleServerClientId.isEmpty) {
      throw Exception(
        'Google sign-in on native platforms requires GOOGLE_SERVER_CLIENT_ID.',
      );
    }

    _googleInitialization ??= _googleSignIn
        .initialize(
          clientId: AppConfig.googleClientId.isEmpty
              ? null
              : AppConfig.googleClientId,
          serverClientId: AppConfig.googleServerClientId,
        )
        .catchError((Object error) {
          _googleInitialization = null;
          throw error;
        });

    await _googleInitialization;
  }

  bool _supportsGoogleOnCurrentPlatform() {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  bool _supportsAppleOnCurrentPlatform() {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  Future<void> _completeFirebaseSocialLogin({
    required String provider,
    required firebase_auth.User? firebaseUser,
  }) async {
    if (firebaseUser == null) {
      throw Exception('Social sign-in did not return a user');
    }

    final idToken = await firebaseUser.getIdToken(true);
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/social/firebase'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'provider': provider, 'idToken': idToken}),
    );

    if (response.statusCode != 200) {
      throw Exception(
        _extractError(response.body, 'Unable to complete social sign-in'),
      );
    }

    await _storeAuthResponse(response.body);
  }

  Future<void> _storeAuthResponse(String responseBody) async {
    final data = json.decode(responseBody);
    _token = data['token'];
    _user = User.fromJson(data['user']);
    await _saveAuthData();
    notifyListeners();
  }

  Future<void> _clearFirebaseSession() async {
    if (Firebase.apps.isNotEmpty) {
      try {
        await _firebaseAuth.signOut();
      } catch (_) {}
    }

    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _clearFirebaseSession();
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
