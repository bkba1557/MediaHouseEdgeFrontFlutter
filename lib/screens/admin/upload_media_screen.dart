import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/media_provider.dart';

class UploadMediaScreen extends StatefulWidget {
  const UploadMediaScreen({super.key});

  @override
  State<UploadMediaScreen> createState() => _UploadMediaScreenState();
}

class _UploadMediaScreenState extends State<UploadMediaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedType = 'image';
  String _selectedCategory = 'film';
  XFile? _selectedFile;
  bool _isUploading = false;

  final List<String> _types = const ['image', 'video'];
  final List<_UploadSection> _sections = const [
    _UploadSection(
      value: 'story',
      title: 'استوريهات 24 ساعة',
      subtitle: 'تظهر كدوائر تحت الأب بار وتفتح شاشة كاملة',
      icon: Icons.auto_stories_outlined,
    ),
    _UploadSection(
      value: 'advertisement',
      title: 'بانرات الإعلانات',
      subtitle: 'تظهر في سلايدر الإعلانات المتحركة',
      icon: Icons.campaign_outlined,
    ),
    _UploadSection(
      value: 'video_backdrop',
      title: 'خلفيات فيديو',
      subtitle: 'تظهر في مساحة خلفيات الفيديو المتغيرة',
      icon: Icons.video_library_outlined,
      uploadCategory: 'film',
      forcedType: 'video',
    ),
    _UploadSection(
      value: 'film',
      title: 'قسم التصوير والأعمال',
      subtitle: 'تظهر في التصنيفات والأعمال الحديثة',
      icon: Icons.movie_creation_outlined,
    ),
    _UploadSection(
      value: 'montage',
      title: 'قسم المونتاج والأعمال',
      subtitle: 'تظهر في التصنيفات والأعمال الحديثة',
      icon: Icons.content_cut,
    ),
  ];

  _UploadSection get _selectedSection => _sections.firstWhere(
        (section) => section.value == _selectedCategory,
      );

  String get _effectiveType => _selectedSection.forcedType ?? _selectedType;

  Future<void> _pickFile() async {
    final picker = ImagePicker();
    final file = _effectiveType == 'video'
        ? await picker.pickVideo(source: ImageSource.gallery)
        : await picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      setState(() => _selectedFile = file);
    }
  }

  Future<void> _upload() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر ملف قبل الرفع')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final mediaProvider = Provider.of<MediaProvider>(context, listen: false);

      await mediaProvider.uploadMedia(
        file: _selectedFile!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _effectiveType,
        category: _selectedSection.uploadCategory ?? _selectedCategory,
        token: authProvider.token!,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم رفع المحتوى بنجاح')),
      );

      _titleController.clear();
      _descriptionController.clear();
      setState(() => _selectedFile = null);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل الرفع: $error')),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Media'),
        backgroundColor: const Color(0xFFE50914),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FilePickerBox(
                    selectedFile: _selectedFile,
                    effectiveType: _effectiveType,
                    onTap: _pickFile,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  if (_selectedSection.forcedType == null) ...[
                    DropdownButtonFormField<String>(
                      initialValue: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                      ),
                      items: _types.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _selectedType = value;
                          _selectedFile = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Text(
                    'اختر القسم الذي سيظهر للمستخدم',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  ..._sections.map(
                    (section) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _UploadSectionTile(
                        section: section,
                        selected: section.value == _selectedCategory,
                        onTap: () {
                          setState(() {
                            _selectedCategory = section.value;
                            if (section.forcedType != null) {
                              _selectedType = section.forcedType!;
                            }
                            _selectedFile = null;
                          });
                        },
                      ),
                    ),
                  ),
                  _SelectedSectionHint(section: _selectedSection),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _upload,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE50914),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isUploading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Upload', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

class _FilePickerBox extends StatelessWidget {
  final XFile? selectedFile;
  final String effectiveType;
  final VoidCallback onTap;

  const _FilePickerBox({
    required this.selectedFile,
    required this.effectiveType,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: selectedFile == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload, size: 50, color: Colors.grey[400]),
                  const SizedBox(height: 10),
                  Text(
                    effectiveType == 'video'
                        ? 'Tap to select video'
                        : 'Tap to select image',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: effectiveType == 'video'
                    ? const ColoredBox(
                        color: Colors.black12,
                        child: Center(
                          child: Icon(Icons.play_circle_fill, size: 64),
                        ),
                      )
                    : FutureBuilder<Uint8List>(
                        future: selectedFile!.readAsBytes(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          return Image.memory(
                            snapshot.data!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          );
                        },
                      ),
              ),
      ),
    );
  }
}

class _UploadSection {
  final String value;
  final String title;
  final String subtitle;
  final IconData icon;
  final String? uploadCategory;
  final String? forcedType;

  const _UploadSection({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.uploadCategory,
    this.forcedType,
  });
}

class _UploadSectionTile extends StatelessWidget {
  final _UploadSection section;
  final bool selected;
  final VoidCallback onTap;

  const _UploadSectionTile({
    required this.section,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFE50914).withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFFE50914) : Colors.white24,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? const Color(0xFFE50914) : Colors.white54,
            ),
            Icon(section.icon, color: selected ? const Color(0xFFE50914) : null),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(section.subtitle, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            if (section.forcedType != null)
              const Chip(label: Text('VIDEO'), visualDensity: VisualDensity.compact),
          ],
        ),
      ),
    );
  }
}

class _SelectedSectionHint extends StatelessWidget {
  final _UploadSection section;

  const _SelectedSectionHint({required this.section});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE50914).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE50914)),
      ),
      child: Row(
        children: [
          Icon(section.icon, color: const Color(0xFFE50914)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'سيظهر هذا الرفع في: ${section.title}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
