import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config/app_config.dart';
import '../models/media.dart';

class MediaProvider with ChangeNotifier {
  List<Media> _mediaList = [];
  bool _isLoading = false;
  String? _error;

  List<Media> get mediaList => _mediaList;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String get _baseUrl => AppConfig.apiBaseUrl;

  Future<void> fetchMedia({String? type, String? category}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String url = '$_baseUrl/media/all';
      final queryParams = <String, String>{};
      if (type != null) queryParams['type'] = type;
      if (category != null) queryParams['category'] = category;

      if (queryParams.isNotEmpty) {
        url += '?${Uri(queryParameters: queryParams).query}';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _mediaList = data.map((json) => Media.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load media');
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> uploadMedia({
    required XFile file,
    required String title,
    required String description,
    required String type,
    required String category,
    required String token,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (Firebase.apps.isEmpty) {
        throw Exception(
          'Firebase is not configured. Start the app with Firebase dart-defines.',
        );
      }

      final downloadUrl = await _uploadFileToFirebase(
        file: file,
        type: type,
        category: category,
      );

      final response = await http.post(
        Uri.parse('$_baseUrl/media/upload'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'title': title,
          'description': description,
          'type': type,
          'category': category,
          'url': downloadUrl,
        }),
      );

      if (response.statusCode == 200) {
        await fetchMedia();
      } else {
        throw Exception(_extractError(response.body, 'Upload failed'));
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> _uploadFileToFirebase({
    required XFile file,
    required String type,
    required String category,
  }) async {
    final bytes = await file.readAsBytes();
    final extension = file.name.contains('.')
        ? file.name.split('.').last.toLowerCase()
        : type == 'video'
            ? 'mp4'
            : 'jpg';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final ref = FirebaseStorage.instance.ref(
      'media/$category/$timestamp-$safeName',
    );

    final metadata = SettableMetadata(
      contentType: file.mimeType ??
          (type == 'video' ? 'video/$extension' : 'image/$extension'),
    );

    await ref.putData(bytes, metadata);
    return ref.getDownloadURL();
  }

  Future<void> deleteMedia(String id, String token) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/media/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        _mediaList.removeWhere((media) => media.id == id);
        notifyListeners();
      } else {
        throw Exception('Delete failed');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateMediaMetadata({
    required String id,
    required String token,
    required String title,
    required String description,
    required String type,
    required String category,
    String? url,
    String? thumbnail,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{
        'title': title,
        'description': description,
        'type': type,
        'category': category,
      };
      if (url != null) body['url'] = url;
      if (thumbnail != null) body['thumbnail'] = thumbnail;

      final response = await http.patch(
        Uri.parse('$_baseUrl/media/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final mediaJson = decoded is Map<String, dynamic> ? decoded['media'] : null;
        if (mediaJson is Map<String, dynamic>) {
          final updated = Media.fromJson(mediaJson);
          final index = _mediaList.indexWhere((m) => m.id == id);
          if (index != -1) {
            _mediaList[index] = updated;
          }
          notifyListeners();
        } else {
          await fetchMedia();
        }
      } else {
        throw Exception(_extractError(response.body, 'Update failed'));
      }
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
