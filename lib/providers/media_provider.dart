import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config/app_config.dart';
import '../models/media.dart';
import '../models/media_crew_draft.dart';
import '../models/media_folder.dart';

class MediaProvider with ChangeNotifier {
  List<Media> _mediaList = [];
  bool _isLoading = false;
  String? _error;

  List<Media> get mediaList => _mediaList;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String get _baseUrl => AppConfig.apiBaseUrl;

  Future<List<MediaFolder>> fetchFolders({required String category}) async {
    final uri = Uri.parse(
      '$_baseUrl/media/folders',
    ).replace(queryParameters: {'category': category});
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(_extractError(response.body, 'Failed to load folders'));
    }

    final decoded = json.decode(response.body);
    if (decoded is! List) return const [];

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(MediaFolder.fromJson)
        .toList(growable: false);
  }

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
    String? collectionKey,
    String? collectionTitle,
    int? sequence,
    XFile? coverFile,
    List<MediaCrewDraft>? crew,
    bool refreshAfterUpload = true,
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

      String? coverUrl;
      if (coverFile != null) {
        coverUrl = await _uploadFileToFirebase(
          file: coverFile,
          type: 'image',
          category: category,
          subfolder: 'covers',
        );
      }

      List<Map<String, dynamic>>? crewJson;
      if (crew != null && crew.isNotEmpty) {
        final uploadedCrew = <MediaCrewMember>[];
        for (final member in crew) {
          final name = member.name.trim();
          final role = member.role.trim();
          final file = member.photoFile;
          if (name.isEmpty) continue;
          if (file == null) continue;

          final photoUrl = await _uploadFileToFirebase(
            file: file,
            type: 'image',
            category: category,
            subfolder: 'crew',
          );
          uploadedCrew.add(
            MediaCrewMember(name: name, role: role, photoUrl: photoUrl),
          );
        }

        if (uploadedCrew.isNotEmpty) {
          crewJson = uploadedCrew
              .map((member) => member.toJson())
              .toList(growable: false);
        }
      }

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
          if (coverUrl != null) 'thumbnail': coverUrl,
          if (crewJson != null) 'crew': crewJson,
          if (collectionKey != null) 'collectionKey': collectionKey,
          if (collectionTitle != null) 'collectionTitle': collectionTitle,
          if (sequence != null) 'sequence': sequence,
        }),
      );

      if (response.statusCode == 200) {
        if (refreshAfterUpload) {
          await fetchMedia();
        }
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
    String? subfolder,
  }) async {
    final bytes = await file.readAsBytes();
    final extension = file.name.contains('.')
        ? file.name.split('.').last.toLowerCase()
        : type == 'video'
        ? 'mp4'
        : 'jpg';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final safeName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final folder = (subfolder != null && subfolder.trim().isNotEmpty)
        ? '/${subfolder.trim()}'
        : '';
    final ref = FirebaseStorage.instance.ref(
      'media/$category$folder/$timestamp-$safeName',
    );

    final metadata = SettableMetadata(
      contentType:
          file.mimeType ??
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
    String? collectionKey,
    String? collectionTitle,
    int? sequence,
    bool clearCollectionFields = false,
    bool clearSequence = false,
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
      if (collectionKey != null || clearCollectionFields) {
        body['collectionKey'] = collectionKey;
      }
      if (collectionTitle != null || clearCollectionFields) {
        body['collectionTitle'] = collectionTitle;
      }
      if (sequence != null || clearSequence) body['sequence'] = sequence;

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
        final mediaJson = decoded is Map<String, dynamic>
            ? decoded['media']
            : null;
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
