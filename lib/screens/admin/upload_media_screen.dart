import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/media_crew_draft.dart';
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
  final _collectionTitleController = TextEditingController();
  final _sequenceController = TextEditingController();
  String _selectedType = 'image';
  String _selectedCategory = 'film';
  XFile? _selectedFile;
  XFile? _coverFile;
  final List<_CrewDraft> _crew = [];
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
    _UploadSection(
      value: 'series_movies',
      title: 'مسلسلات وأفلام',
      subtitle: 'تلفزيونية ومنصات',
      icon: Icons.tv_sharp,
    ),
    _UploadSection(
      value: 'ads_shooting',
      title: 'تصوير إعلانات',
      subtitle: 'تجارية ودعائية',
      icon: Icons.videocam_outlined,
    ),
    _UploadSection(
      value: 'podcast',
      title: 'بودكاست',
      subtitle: 'برامج صوتية متنوعة',
      icon: Icons.podcasts_outlined,
    ),
    _UploadSection(
      value: 'video_clip',
      title: 'فيديو كليب',
      subtitle: 'فيديوهات غنائية',
      icon: Icons.music_video_outlined,
    ),
    _UploadSection(
      value: 'art_production',
      title: 'إنتاج فني',
      subtitle: 'تصميم وإنتاج عمل فني',
      icon: Icons.attach_file,
    ),
    _UploadSection(
      value: 'platform_distribution',
      title: 'إنتاج وتوزيع المنصات',
      subtitle: 'بيع وتوزيع وتسويق الأعمال بالمنصات',
      icon: Icons.money_outlined,
    ),
    _UploadSection(
      value: 'commercial_ads',
      title: 'إعلانات تجارية',
      subtitle: 'تلفزيونية وسوشيال ميديا وغيرها',
      icon: Icons.ads_click_outlined,
    ),
    _UploadSection(
      value: 'global_events',
      title: 'حفلات عالمية',
      subtitle: 'تغطية حفلات ومهرجانات عالمية',
      icon: Icons.public_outlined,
    ),
    _UploadSection(
      value: 'media_coverage',
      title: 'تغطية إعلامية',
      subtitle: 'تغطية إعلامية للأحداث والفعاليات',
      icon: Icons.mic_external_on_outlined,
    ),
    _UploadSection(
      value: 'audio_recordings',
      title: 'تسجيلات صوتية',
      subtitle: 'تسجيل صوتي بجودة عالية للاستوديوهات والمنتجين',
      icon: Icons.mic_external_on_outlined,
    ),
    _UploadSection(
      value: 'gov_partnership_ads',
      title: 'إعلانات بشراكة حكومية',
      subtitle: 'إنتاج إعلانات بالتعاون مع جهات حكومية',
      icon: Icons.handshake_outlined,
    ),
    _UploadSection(
      value: 'artist_contracts',
      title: 'تعاقدات فنانين',
      subtitle: 'عقود فنية وحجوزات وتنسيق التعاقدات',
      icon: Icons.assignment_ind_outlined,
    ),
    _UploadSection(
      value: 'behind_the_scenes',
      title: 'كواليس التصوير',
      subtitle: 'محتوى خلف الكاميرا ولحظات ما وراء المشهد',
      icon: Icons.photo_camera_back_outlined,
    ),
    _UploadSection(
      value: 'dj_booking',
      title: 'DJ\'s Booking',
      subtitle: 'حجوزات الدي جي والعروض الموسيقية والفعاليات',
      icon: Icons.queue_music_outlined,
    ),
    _UploadSection(
      value: 'international_institutions',
      title: 'أعمال مع مؤسسات دولية',
      subtitle: 'مشاريع مشتركة ومحتوى مخصص لجهات ومؤسسات دولية',
      icon: Icons.apartment_outlined,
    ),
  ];

  _UploadSection get _selectedSection =>
      _sections.firstWhere((section) => section.value == _selectedCategory);

  String get _effectiveType => _selectedSection.forcedType ?? _selectedType;
  bool get _isSeriesMovies =>
      (_selectedSection.uploadCategory ?? _selectedCategory) == 'series_movies';

  String _toCollectionKey(String value) {
    final trimmed = value.trim().toLowerCase();
    final normalized = trimmed.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return normalized.replaceAll(RegExp(r'^_+|_+$'), '');
  }

  Future<void> _pickFile() async {
    final picker = ImagePicker();
    final file = _effectiveType == 'video'
        ? await picker.pickVideo(source: ImageSource.gallery)
        : await picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      setState(() => _selectedFile = file);
    }
  }

  Future<void> _pickCover() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => _coverFile = file);
  }

  void _addCrewMember() {
    setState(() => _crew.add(_CrewDraft()));
  }

  void _removeCrewMember(int index) {
    final removed = _crew.removeAt(index);
    removed.dispose();
    setState(() {});
  }

  Future<void> _upload() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('اختر ملف قبل الرفع')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
      final category = _selectedSection.uploadCategory ?? _selectedCategory;

      final crewDrafts = _crew
          .where((draft) => draft.nameController.text.trim().isNotEmpty)
          .map(
            (draft) => MediaCrewDraft(
              name: draft.nameController.text.trim(),
              role: draft.roleController.text.trim(),
              photoFile: draft.photoFile,
            ),
          )
          .toList(growable: false);

      await mediaProvider.uploadMedia(
        file: _selectedFile!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _effectiveType,
        category: category,
        token: authProvider.token!,
        collectionTitle: _isSeriesMovies
            ? _collectionTitleController.text.trim()
            : null,
        collectionKey: _isSeriesMovies
            ? _toCollectionKey(_collectionTitleController.text)
            : null,
        sequence: _isSeriesMovies
            ? int.tryParse(_sequenceController.text.trim())
            : null,
        coverFile: _coverFile,
        crew: crewDrafts,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم رفع المحتوى بنجاح')));

      _titleController.clear();
      _descriptionController.clear();
      _collectionTitleController.clear();
      _sequenceController.clear();
      for (final member in _crew) {
        member.dispose();
      }
      _crew.clear();
      setState(() {
        _selectedFile = null;
        _coverFile = null;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل الرفع: $error')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
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
                if (_effectiveType == 'video') ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Video Cover (Thumbnail)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  _CoverPickerBox(
                    selectedFile: _coverFile,
                    onTap: _pickCover,
                    onClear: _coverFile == null
                        ? null
                        : () => setState(() => _coverFile = null),
                  ),
                ],
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
                          if (section.value != 'series_movies') {
                            _collectionTitleController.clear();
                            _sequenceController.clear();
                          }
                          _selectedFile = null;
                        });
                      },
                    ),
                  ),
                ),
                _SelectedSectionHint(section: _selectedSection),
                if (_isSeriesMovies) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Folder / Series',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _collectionTitleController,
                    decoration: const InputDecoration(
                      labelText: 'اسم المجلد (اسم المسلسل / الفيلم)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (!_isSeriesMovies) return null;
                      if (value == null || value.trim().isEmpty) {
                        return 'اكتب اسم المجلد';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _sequenceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'الترتيب داخل المجلد (رقم الحلقة/الجزء)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (!_isSeriesMovies) return null;
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return null;
                      if (int.tryParse(text) == null) {
                        return 'اكتب رقم صحيح';
                      }
                      return null;
                    },
                  ),
                ],
                if (_effectiveType == 'video') ...[
                  const SizedBox(height: 18),
                  const Text(
                    'Crew / فريق العمل',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  ...List.generate(_crew.length, (index) {
                    final item = _crew[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _CrewTile(
                        index: index + 1,
                        nameController: item.nameController,
                        roleController: item.roleController,
                        photoFile: item.photoFile,
                        onPickPhoto: () async {
                          final picker = ImagePicker();
                          final file = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (file == null) return;
                          setState(() => item.photoFile = file);
                        },
                        onRemove: () => _removeCrewMember(index),
                      ),
                    );
                  }),
                  OutlinedButton.icon(
                    onPressed: _addCrewMember,
                    icon: const Icon(Icons.person_add_alt_1_outlined),
                    label: const Text('Add crew member'),
                  ),
                ],
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
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _collectionTitleController.dispose();
    _sequenceController.dispose();
    for (final member in _crew) {
      member.dispose();
    }
    super.dispose();
  }
}

class _CrewDraft {
  final nameController = TextEditingController();
  final roleController = TextEditingController();
  XFile? photoFile;

  void dispose() {
    nameController.dispose();
    roleController.dispose();
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

class _CoverPickerBox extends StatelessWidget {
  final XFile? selectedFile;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _CoverPickerBox({
    required this.selectedFile,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 170,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white.withValues(alpha: 0.03),
        ),
        child: selectedFile == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_outlined, size: 46, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to select cover image',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  FutureBuilder<Uint8List>(
                    future: selectedFile!.readAsBytes(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFE50914),
                          ),
                        );
                      }
                      return Image.memory(snapshot.data!, fit: BoxFit.cover);
                    },
                  ),
                  if (onClear != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.55),
                        ),
                        onPressed: onClear,
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _CrewTile extends StatelessWidget {
  final int index;
  final TextEditingController nameController;
  final TextEditingController roleController;
  final XFile? photoFile;
  final VoidCallback onPickPhoto;
  final VoidCallback onRemove;

  const _CrewTile({
    required this.index,
    required this.nameController,
    required this.roleController,
    required this.photoFile,
    required this.onPickPhoto,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Member $index',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                tooltip: 'Remove',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 66,
                height: 66,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: onPickPhoto,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: photoFile == null
                        ? Container(
                            color: Colors.white.withValues(alpha: 0.06),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white54,
                            ),
                          )
                        : FutureBuilder<Uint8List>(
                            future: photoFile!.readAsBytes(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFFE50914),
                                  ),
                                );
                              }
                              return Image.memory(
                                snapshot.data!,
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: roleController,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onPickPhoto,
            icon: const Icon(Icons.photo_camera_outlined),
            label: Text(photoFile == null ? 'Add photo' : 'Change photo'),
          ),
        ],
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
            Icon(
              section.icon,
              color: selected ? const Color(0xFFE50914) : null,
            ),
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
              const Chip(
                label: Text('VIDEO'),
                visualDensity: VisualDensity.compact,
              ),
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
