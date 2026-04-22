import 'package:image_picker/image_picker.dart';

class MediaCrewDraft {
  final String name;
  final String role;
  final XFile? photoFile;

  const MediaCrewDraft({
    required this.name,
    required this.role,
    required this.photoFile,
  });
}

