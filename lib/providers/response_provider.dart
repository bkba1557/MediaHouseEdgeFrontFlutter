import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/response.dart';

class ResponseProvider with ChangeNotifier {
  List<ClientResponse> _responses = [];
  List<ClientResponse> _serviceRequests = [];
  bool _isLoading = false;
  bool _isLoadingServiceRequests = false;
  bool _isSubmittingServiceRequest = false;

  List<ClientResponse> get responses => _responses;
  List<ClientResponse> get serviceRequests => _serviceRequests;
  bool get isLoading => _isLoading;
  bool get isLoadingServiceRequests => _isLoadingServiceRequests;
  bool get isSubmittingServiceRequest => _isSubmittingServiceRequest;

  String get _baseUrl => AppConfig.apiBaseUrl;

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
        Uri.parse('$_baseUrl/responses/all?kind=feedback'),
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

  Future<void> fetchServiceRequests(String token) async {
    _isLoadingServiceRequests = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/responses/all?kind=service'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _serviceRequests =
            data.map((json) => ClientResponse.fromJson(json)).toList();
      }
    } finally {
      _isLoadingServiceRequests = false;
      notifyListeners();
    }
  }

  Future<void> submitServiceRequest({
    required String serviceCategory,
    required String serviceTitle,
    required String clientName,
    required String clientEmail,
    required String clientPhoneCountry,
    required String clientPhoneDialCode,
    required String clientPhoneNumber,
    required String message,
  }) async {
    _isSubmittingServiceRequest = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/responses/submit'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'clientName': clientName,
          'clientEmail': clientEmail,
          'clientPhoneCountry': clientPhoneCountry,
          'clientPhoneDialCode': clientPhoneDialCode,
          'clientPhoneNumber': clientPhoneNumber,
          'message': message,
          'serviceCategory': serviceCategory,
          'serviceTitle': serviceTitle,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to submit service request');
      }
    } finally {
      _isSubmittingServiceRequest = false;
      notifyListeners();
    }
  }

  Future<void> updateResponseStatus({
    required String id,
    required String status,
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/responses/status/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'status': status}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update status');
    }
  }

  Future<void> replyToResponse(
    String id,
    String reply,
    String token, {
    bool refreshServiceRequests = false,
  }) async {
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
        if (refreshServiceRequests) {
          await fetchServiceRequests(token);
        } else {
          await fetchResponses(token);
        }
      }
    } catch (e) {
      rethrow;
    }
  }
}
