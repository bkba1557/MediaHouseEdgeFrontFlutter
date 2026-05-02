import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../config/service_folder_config.dart';
import '../../models/media_crew_draft.dart';
import '../../providers/auth_provider.dart';
import '../../providers/media_provider.dart';
import '../../widgets/fixed_aspect_cropper_dialog.dart';

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
  final List<_SelectedUploadAsset> _selectedAssets = [];
  final List<_CrewDraft> _crew = [];

  String _selectedType = 'image';
  String _selectedCategory = 'film';
  String? _selectedCollectionKey;
  XFile? _coverFile;
  List<ServiceFolderOption> _folderOptions = const [];
  bool _isAddingCustomFolder = false;
  bool _isLoadingFolders = false;
  bool _isUploading = false;
  int _uploadingCount = 0;
  int _uploadingTotal = 0;

  final List<String> _types = const ['image', 'video'];
  final List<_UploadSection> _sections = const [
    _UploadSection(
      value: 'story',
      title: 'استوريات 24 ساعة',
      subtitle: 'تظهر كدوائر أسفل الشريط العلوي وتفتح شاشة كاملة',
      icon: Icons.auto_stories_outlined,
    ),
    _UploadSection(
      value: 'advertisement',
      title: 'بنرات الإعلانات',
      subtitle: 'تظهر في سلايدر البنرات ويمكن أن تكون صورة أو فيديو',
      icon: Icons.campaign_outlined,
    ),
    _UploadSection(
      value: 'video_backdrop',
      title: 'خلفيات فيديو',
      subtitle: 'تظهر في مساحة الخلفيات المتغيرة',
      icon: Icons.video_library_outlined,
      uploadCategory: 'film',
      forcedType: 'video',
    ),
    _UploadSection(
      value: 'film',
      title: 'قسم التصوير والأعمال',
      subtitle: 'أعمال التصوير والإنتاج المرئي',
      icon: Icons.movie_creation_outlined,
    ),
    _UploadSection(
      value: 'montage',
      title: 'قسم المونتاج والأعمال',
      subtitle: 'أعمال المونتاج وما بعد الإنتاج',
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
      subtitle: 'فيديوهات غنائية وموسيقية',
      icon: Icons.music_video_outlined,
    ),
    _UploadSection(
      value: 'art_production',
      title: 'إنتاج فني',
      subtitle: 'تصميم وإنتاج أعمال فنية',
      icon: Icons.attach_file,
    ),
    _UploadSection(
      value: 'platform_distribution',
      title: 'إنتاج وتوزيع المنصات',
      subtitle: 'بيع وتوزيع وتسويق الأعمال على المنصات',
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
      subtitle: 'تسجيل صوتي بجودة عالية',
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
      title: 'DJ Booking',
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

  String get _effectiveCategory =>
      _selectedSection.uploadCategory ?? _selectedCategory;
  String get _effectiveType => _selectedSection.forcedType ?? _selectedType;
  bool get _isSeriesMovies => _effectiveCategory == 'series_movies';
  bool get _isFolderRequired =>
      serviceCategoryRequiresFolder(_effectiveCategory);
  bool get _isSingleVideoUpload =>
      _effectiveType == 'video' && _selectedAssets.length == 1;

  double get _primaryImageAspectRatio {
    if (_selectedCategory == 'advertisement') return 16 / 9;
    if (_isSeriesMovies) return 0.72;
    return 0.86;
  }

  String? get _resolvedCollectionTitle {
    if (_isAddingCustomFolder) {
      final title = normalizeFolderTitle(_collectionTitleController.text);
      return title.isEmpty ? null : title;
    }

    if (_selectedCollectionKey == null) return null;
    for (final option in _folderOptions) {
      if (option.collectionKey == _selectedCollectionKey) {
        return option.collectionTitle;
      }
    }
    return null;
  }

  String get _uploadButtonText {
    if (_isUploading) {
      if (_uploadingTotal > 0) {
        return 'Uploading $_uploadingCount/$_uploadingTotal';
      }
      return 'Uploading...';
    }

    if (_selectedAssets.length > 1) {
      return 'Upload ${_selectedAssets.length} files';
    }
    return 'Upload';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadFolderOptions();
    });
  }

  Future<void> _loadFolderOptions() async {
    final category = _effectiveCategory;
    setState(() => _isLoadingFolders = true);

    final merged = <String, ServiceFolderOption>{};
    try {
      for (final option in defaultFoldersForCategory(category)) {
        merged[option.collectionKey] = option;
      }

      final fetched = await context.read<MediaProvider>().fetchFolders(
        category: category,
      );
      for (final folder in fetched) {
        final title = normalizeFolderTitle(folder.collectionTitle);
        final key = folder.collectionKey.trim().isEmpty
            ? buildCollectionKey(title)
            : folder.collectionKey.trim();
        if (title.isEmpty || key.isEmpty) continue;
        merged[key] = ServiceFolderOption(
          collectionKey: key,
          collectionTitle: title,
          sortOrder: folder.sortOrder,
        );
      }
    } catch (_) {}

    if (!mounted) return;

    final options = merged.values.toList(growable: false)
      ..sort(compareFolderOptions);

    setState(() {
      _folderOptions = options;
      if (_isFolderRequired && options.isEmpty) {
        _isAddingCustomFolder = true;
      }

      if (!_isAddingCustomFolder) {
        final hasSelection =
            _selectedCollectionKey != null &&
            options.any((item) => item.collectionKey == _selectedCollectionKey);
        if (!hasSelection) {
          _selectedCollectionKey = options.isEmpty
              ? null
              : options.first.collectionKey;
        }
      }

      _isLoadingFolders = false;
    });
  }

  Future<XFile?> _cropPickedImage(
    XFile file, {
    required double aspectRatio,
    required String title,
  }) {
    return showFixedAspectCropperDialog(
      context,
      sourceFile: file,
      aspectRatio: aspectRatio,
      title: title,
    );
  }

  Future<List<XFile>> _pickImages(ImagePicker picker) async {
    try {
      return await picker.pickMultiImage();
    } catch (_) {
      final single = await picker.pickImage(source: ImageSource.gallery);
      return single == null ? const [] : [single];
    }
  }

  Future<List<XFile>> _pickVideos(ImagePicker picker) async {
    try {
      return await picker.pickMultiVideo();
    } catch (_) {
      final single = await picker.pickVideo(source: ImageSource.gallery);
      return single == null ? const [] : [single];
    }
  }

  Future<void> _pickFiles({bool append = false}) async {
    final picker = ImagePicker();

    if (_effectiveType == 'video') {
      final files = await _pickVideos(picker);
      if (files.isEmpty || !mounted) return;

      final nextAssets = files
          .map(
            (file) => _SelectedUploadAsset(sourceFile: file, uploadFile: file),
          )
          .toList(growable: false);

      setState(() {
        if (!append) {
          _selectedAssets.clear();
        }
        _selectedAssets.addAll(nextAssets);
      });
      return;
    }

    final files = await _pickImages(picker);
    if (files.isEmpty) return;

    final croppedAssets = <_SelectedUploadAsset>[];
    for (final file in files) {
      final cropped = await _cropPickedImage(
        file,
        aspectRatio: _primaryImageAspectRatio,
        title: _selectedCategory == 'advertisement'
            ? 'قص صورة البنر'
            : 'قص صورة الكارت',
      );
      if (!mounted) return;
      if (cropped == null) continue;

      croppedAssets.add(
        _SelectedUploadAsset(sourceFile: file, uploadFile: cropped),
      );
    }

    if (croppedAssets.isEmpty) return;

    setState(() {
      if (!append) {
        _selectedAssets.clear();
      }
      _selectedAssets.addAll(croppedAssets);
    });
  }

  Future<void> _recropSelectedImage(int index) async {
    if (index < 0 || index >= _selectedAssets.length) return;

    final asset = _selectedAssets[index];
    final cropped = await _cropPickedImage(
      asset.sourceFile,
      aspectRatio: _primaryImageAspectRatio,
      title: _selectedCategory == 'advertisement'
          ? 'قص صورة البنر'
          : 'قص صورة الكارت',
    );
    if (cropped == null || !mounted) return;

    setState(() {
      _selectedAssets[index] = asset.copyWith(uploadFile: cropped);
    });
  }

  void _removeSelectedAsset(int index) {
    if (index < 0 || index >= _selectedAssets.length) return;
    setState(() {
      _selectedAssets.removeAt(index);
    });
  }

  void _clearSelectedAssets() {
    setState(() {
      _selectedAssets.clear();
      _coverFile = null;
    });
  }

  Future<void> _pickCover() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final cropped = await _cropPickedImage(
      file,
      aspectRatio: _primaryImageAspectRatio,
      title: 'قص صورة الغلاف',
    );
    if (cropped == null) return;

    setState(() => _coverFile = cropped);
  }

  void _addCrewMember() {
    setState(() => _crew.add(_CrewDraft()));
  }

  void _removeCrewMember(int index) {
    final removed = _crew.removeAt(index);
    removed.dispose();
    setState(() {});
  }

  String _fallbackTitleForFile(XFile file) {
    final fileName = file.name.trim();
    if (fileName.isEmpty) return _selectedSection.title;

    final dotIndex = fileName.lastIndexOf('.');
    final withoutExtension = dotIndex > 0
        ? fileName.substring(0, dotIndex)
        : fileName;
    final normalized = withoutExtension
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .trim();

    return normalized.isEmpty ? _selectedSection.title : normalized;
  }

  String _buildTitleForAsset(_SelectedUploadAsset asset, int index) {
    final typedTitle = _titleController.text.trim();
    if (typedTitle.isEmpty) {
      return _fallbackTitleForFile(asset.sourceFile);
    }
    if (_selectedAssets.length == 1) {
      return typedTitle;
    }
    return '$typedTitle ${index + 1}';
  }

  int? _sequenceForAsset(int index) {
    if (!_isSeriesMovies) return null;
    final baseSequence = int.tryParse(_sequenceController.text.trim());
    if (baseSequence == null) return null;
    return baseSequence + index;
  }

  Future<void> _upload() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAssets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر ملفًا واحدًا على الأقل قبل الرفع')),
      );
      return;
    }

    final collectionTitle = _resolvedCollectionTitle;
    if (_isFolderRequired &&
        (collectionTitle == null || collectionTitle.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر مجلدًا أو أضف مجلدًا جديدًا')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadingCount = 0;
      _uploadingTotal = _selectedAssets.length;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
      final category = _effectiveCategory;

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

      for (var index = 0; index < _selectedAssets.length; index++) {
        final asset = _selectedAssets[index];
        await mediaProvider.uploadMedia(
          file: asset.uploadFile,
          title: _buildTitleForAsset(asset, index),
          description: _descriptionController.text.trim(),
          type: _effectiveType,
          category: category,
          token: authProvider.token!,
          collectionTitle: collectionTitle,
          collectionKey: collectionTitle == null
              ? null
              : buildCollectionKey(collectionTitle),
          sequence: _sequenceForAsset(index),
          coverFile: _isSingleVideoUpload ? _coverFile : null,
          crew: _isSingleVideoUpload ? crewDrafts : null,
          refreshAfterUpload: index == _selectedAssets.length - 1,
        );

        if (!mounted) return;
        setState(() => _uploadingCount = index + 1);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedAssets.length == 1
                ? 'تم رفع المحتوى بنجاح'
                : 'تم رفع ${_selectedAssets.length} ملفات بنجاح',
          ),
        ),
      );

      _titleController.clear();
      _descriptionController.clear();
      _sequenceController.clear();
      for (final member in _crew) {
        member.dispose();
      }
      _crew.clear();
      setState(() {
        _selectedAssets.clear();
        _coverFile = null;
      });
    } catch (error) {
      if (!mounted) return;
      final partialMessage = _uploadingCount > 0 && _uploadingTotal > 1
          ? 'فشل الرفع بعد $_uploadingCount من $_uploadingTotal ملفات: $error'
          : 'فشل الرفع: $error';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(partialMessage)));
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadingCount = 0;
          _uploadingTotal = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canShowVideoExtras = _isSingleVideoUpload;
    final isMultiVideoUpload =
        _effectiveType == 'video' && _selectedAssets.length > 1;

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
                _MediaPickerPanel(
                  selectedAssets: _selectedAssets,
                  effectiveType: _effectiveType,
                  onPickInitial: _isUploading ? null : () => _pickFiles(),
                  onAddMore: _selectedAssets.isEmpty || _isUploading
                      ? null
                      : () => _pickFiles(append: true),
                  onClearAll: _selectedAssets.isEmpty || _isUploading
                      ? null
                      : _clearSelectedAssets,
                  onRemoveAsset: _isUploading ? null : _removeSelectedAsset,
                  onRecropAsset: _effectiveType == 'image' && !_isUploading
                      ? _recropSelectedImage
                      : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: _selectedAssets.length > 1
                        ? 'العنوان الأساسي (اختياري)'
                        : 'العنوان (اختياري)',
                    hintText: _selectedAssets.length > 1
                        ? 'سيُستخدم كعنوان أساسي مع ترقيم تلقائي'
                        : 'إذا تُرك فارغًا سيتم استخدام اسم الملف',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'الوصف',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                if (canShowVideoExtras) ...[
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
                ] else if (isMultiVideoUpload) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Text(
                      'عند رفع أكثر من فيديو دفعة واحدة، الغلاف وفريق العمل لن يتم تطبيقهما لأن كل فيديو يحتاج بياناته الخاصة.',
                    ),
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
                    items: _types
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(type.toUpperCase()),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedType = value;
                        _selectedAssets.clear();
                        _coverFile = null;
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
                            _sequenceController.clear();
                          }
                          _collectionTitleController.clear();
                          _selectedCollectionKey = null;
                          _isAddingCustomFolder = false;
                          _selectedAssets.clear();
                          _coverFile = null;
                        });
                        _loadFolderOptions();
                      },
                    ),
                  ),
                ),
                _SelectedSectionHint(section: _selectedSection),
                const SizedBox(height: 16),
                _FolderSelectionPanel(
                  isLoading: _isLoadingFolders,
                  isRequired: _isFolderRequired,
                  isUsingCustomFolder: _isAddingCustomFolder,
                  options: _folderOptions,
                  selectedCollectionKey: _selectedCollectionKey,
                  customFolderController: _collectionTitleController,
                  onSelectFolder: (value) {
                    setState(() {
                      _selectedCollectionKey = value;
                      _isAddingCustomFolder = false;
                    });
                  },
                  onUseCustomFolder: () {
                    setState(() {
                      _isAddingCustomFolder = true;
                      _selectedCollectionKey = null;
                    });
                  },
                  onCancelCustomFolder:
                      _isFolderRequired && _folderOptions.isEmpty
                      ? null
                      : () {
                          setState(() {
                            _isAddingCustomFolder = false;
                            _collectionTitleController.clear();
                            _selectedCollectionKey = _folderOptions.isEmpty
                                ? null
                                : _folderOptions.first.collectionKey;
                          });
                        },
                ),
                if (_isSeriesMovies) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'ترتيب المحتوى داخل المجلد',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _sequenceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText:
                          'رقم البداية داخل المجلد (سيزيد تلقائيًا عند رفع عدة ملفات)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (!_isSeriesMovies) return null;
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return null;
                      if (int.tryParse(text) == null) {
                        return 'اكتب رقمًا صحيحًا';
                      }
                      return null;
                    },
                  ),
                ],
                if (canShowVideoExtras) ...[
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

                          final cropped = await _cropPickedImage(
                            file,
                            aspectRatio: 1,
                            title: 'قص صورة عضو الفريق',
                          );
                          if (cropped == null || !mounted) return;

                          setState(() => item.photoFile = cropped);
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
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _uploadButtonText,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          )
                        : Text(
                            _uploadButtonText,
                            style: const TextStyle(fontSize: 16),
                          ),
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

class _SelectedUploadAsset {
  final XFile sourceFile;
  final XFile uploadFile;

  const _SelectedUploadAsset({
    required this.sourceFile,
    required this.uploadFile,
  });

  _SelectedUploadAsset copyWith({XFile? uploadFile}) {
    return _SelectedUploadAsset(
      sourceFile: sourceFile,
      uploadFile: uploadFile ?? this.uploadFile,
    );
  }

  String get displayName =>
      sourceFile.name.isNotEmpty ? sourceFile.name : uploadFile.name;
}

class _MediaPickerPanel extends StatelessWidget {
  final List<_SelectedUploadAsset> selectedAssets;
  final String effectiveType;
  final VoidCallback? onPickInitial;
  final VoidCallback? onAddMore;
  final VoidCallback? onClearAll;
  final ValueChanged<int>? onRemoveAsset;
  final ValueChanged<int>? onRecropAsset;

  const _MediaPickerPanel({
    required this.selectedAssets,
    required this.effectiveType,
    this.onPickInitial,
    this.onAddMore,
    this.onClearAll,
    this.onRemoveAsset,
    this.onRecropAsset,
  });

  @override
  Widget build(BuildContext context) {
    final isVideo = effectiveType == 'video';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isVideo ? 'الفيديوهات المختارة' : 'الصور المختارة',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (selectedAssets.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE50914).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${selectedAssets.length}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (selectedAssets.isEmpty)
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onPickInitial,
              child: Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isVideo
                          ? Icons.video_library_outlined
                          : Icons.image_outlined,
                      size: 52,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isVideo
                          ? 'اضغط لاختيار فيديو أو عدة فيديوهات'
                          : 'اضغط لاختيار صورة أو عدة صور',
                      style: TextStyle(color: Colors.grey[300]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isVideo
                          ? 'يمكنك رفع أكثر من فيديو دفعة واحدة'
                          : 'سيتم قص كل صورة على مقاس القسم المختار',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    isVideo
                        ? 'يمكنك إضافة دفعة جديدة أو حذف أي ملف قبل الرفع.'
                        : 'يمكنك إعادة قص أي صورة أو حذفها قبل الرفع.',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ),
                TextButton.icon(
                  onPressed: onAddMore,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('إضافة المزيد'),
                ),
                TextButton.icon(
                  onPressed: onClearAll,
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: const Text('مسح الكل'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(
                selectedAssets.length,
                (index) => _SelectedMediaCard(
                  asset: selectedAssets[index],
                  isVideo: isVideo,
                  onRemove: onRemoveAsset == null
                      ? null
                      : () => onRemoveAsset!(index),
                  onRecrop: !isVideo && onRecropAsset != null
                      ? () => onRecropAsset!(index)
                      : null,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SelectedMediaCard extends StatelessWidget {
  final _SelectedUploadAsset asset;
  final bool isVideo;
  final VoidCallback? onRemove;
  final VoidCallback? onRecrop;

  const _SelectedMediaCard({
    required this.asset,
    required this.isVideo,
    this.onRemove,
    this.onRecrop,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 176,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 132,
                    child: isVideo
                        ? Container(
                            color: Colors.black26,
                            child: const Center(
                              child: Icon(
                                Icons.play_circle_fill_outlined,
                                size: 56,
                              ),
                            ),
                          )
                        : FutureBuilder<Uint8List>(
                            future: asset.uploadFile.readAsBytes(),
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
                if (onRemove != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.58),
                      ),
                      onPressed: onRemove,
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
              child: Text(
                asset.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (onRecrop != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onRecrop,
                    icon: const Icon(Icons.crop_outlined, size: 18),
                    label: const Text('إعادة القص'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FolderSelectionPanel extends StatelessWidget {
  final bool isLoading;
  final bool isRequired;
  final bool isUsingCustomFolder;
  final List<ServiceFolderOption> options;
  final String? selectedCollectionKey;
  final TextEditingController customFolderController;
  final ValueChanged<String?> onSelectFolder;
  final VoidCallback onUseCustomFolder;
  final VoidCallback? onCancelCustomFolder;

  const _FolderSelectionPanel({
    required this.isLoading,
    required this.isRequired,
    required this.isUsingCustomFolder,
    required this.options,
    required this.selectedCollectionKey,
    required this.customFolderController,
    required this.onSelectFolder,
    required this.onUseCustomFolder,
    this.onCancelCustomFolder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
        color: Colors.white.withValues(alpha: 0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isRequired
                      ? 'المجلد / الفئة (مطلوب)'
                      : 'المجلد / الفئة (اختياري)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (!isUsingCustomFolder)
                TextButton.icon(
                  onPressed: onUseCustomFolder,
                  icon: const Icon(Icons.create_new_folder_outlined),
                  label: const Text('إضافة جديد'),
                )
              else if (onCancelCustomFolder != null)
                TextButton.icon(
                  onPressed: onCancelCustomFolder,
                  icon: const Icon(Icons.list_alt_outlined),
                  label: const Text('اختيار موجود'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFFE50914)),
              ),
            )
          else if (isUsingCustomFolder || options.isEmpty)
            TextFormField(
              controller: customFolderController,
              decoration: InputDecoration(
                labelText: options.isEmpty
                    ? 'اكتب اسم المجلد أو الفئة الجديدة'
                    : 'اسم المجلد الجديد',
                border: const OutlineInputBorder(),
              ),
            )
          else
            DropdownButtonFormField<String>(
              initialValue: selectedCollectionKey,
              decoration: const InputDecoration(
                labelText: 'اختر المجلد',
                border: OutlineInputBorder(),
              ),
              items: options
                  .map(
                    (option) => DropdownMenuItem(
                      value: option.collectionKey,
                      child: Text(option.collectionTitle),
                    ),
                  )
                  .toList(growable: false),
              onChanged: onSelectFolder,
            ),
          if (options.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'يمكنك استخدام مجلد موجود أو إنشاء مجلد جديد أثناء الرفع.',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ],
      ),
    );
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
