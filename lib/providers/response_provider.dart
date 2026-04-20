import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/response.dart';

class ResponseProvider with ChangeNotifier {
  List<ClientResponse> _responses = [];
  bool _isLoading = false;

  List<ClientResponse> get responses => _responses;
  bool get isLoading => _isLoading;

  final String _baseUrl = 'http://10.0.2.2:5000/api';

  Future<void> submitResponse({
    required String clientName,
    required String clientEmail,
    required String message,
    int? rating,
    String? mediaId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/responses/submit'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'clientName': clientName,
          'clientEmail': clientEmail,
          'message': message,
          'rating': rating,
          'mediaId': mediaId,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to submit response');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchResponses(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/responses/all'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _responses = data.map((json) => ClientResponse.fromJson(json)).toList();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> replyToResponse(String id, String reply, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/responses/reply/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'reply': reply}),
      );

      if (response.statusCode == 200) {
        await fetchResponses(token);
      }
    } catch (e) {
      rethrow;
    }
  }
}
