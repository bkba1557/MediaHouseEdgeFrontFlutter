import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/about_page_content.dart';

class AboutProvider with ChangeNotifier {
  AboutPageContent _page = const AboutPageContent.empty();
  bool _isLoading = false;
  String? _error;

  AboutPageContent get page => _page;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String get _baseUrl => AppConfig.apiBaseUrl;

  Future<void> fetchAboutPage() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse('$_baseUrl/about'));
      if (response.statusCode != 200) {
        throw Exception(
          _extractError(response.body, 'Failed to load about content'),
        );
      }

      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Unexpected about response format');
      }

      _page = AboutPageContent.fromJson(decoded);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<AboutPageContent> saveAboutPage({
    required String token,
    required Map<String, dynamic> payload,
  }) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/about'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception(
        _extractError(response.body, 'Failed to save about content'),
      );
    }

    final decoded = json.decode(response.body);
    final pageJson = decoded is Map<String, dynamic> ? decoded['page'] : null;
    if (pageJson is! Map<String, dynamic>) {
      throw Exception('Unexpected about save response');
    }

    _page = AboutPageContent.fromJson(pageJson);
    notifyListeners();
    return _page;
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
