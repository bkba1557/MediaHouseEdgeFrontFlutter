import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class FirebaseAssetUploadService {
  static Future<String> uploadFile({
    required XFile file,
    required String type,
    required String folder,
    String? subfolder,
  }) async {
    if (Firebase.apps.isEmpty) {
      throw Exception(
        'Firebase is not configured. Start the app with Firebase dart-defines.',
      );
    }

    final bytes = await file.readAsBytes();
    final extension = file.name.contains('.')
        ? file.name.split('.').last.toLowerCase()
        : type == 'video'
        ? 'mp4'
        : 'jpg';
    final safeName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final normalizedSubfolder = subfolder == null || subfolder.trim().isEmpty
        ? ''
        : '/${subfolder.trim()}';

    final ref = FirebaseStorage.instance.ref(
      'content/$folder$normalizedSubfolder/$timestamp-$safeName',
    );

    final metadata = SettableMetadata(
      contentType:
          file.mimeType ??
          (type == 'video' ? 'video/$extension' : 'image/$extension'),
    );

    await ref.putData(bytes, metadata);
    return ref.getDownloadURL();
  }
}
