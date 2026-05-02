import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../localization/app_localizations.dart';
import '../../models/about_page_content.dart';
import '../../models/content_asset.dart';
import '../../providers/about_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase_asset_upload_service.dart';
import '../../widgets/app_network_image.dart';

class AboutManagementScreen extends StatefulWidget {
  const AboutManagementScreen({super.key});

  @override
  State<AboutManagementScreen> createState() => _AboutManagementScreenState();
}

class _AboutManagementScreenState extends State<AboutManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _heroTitleController = TextEditingController();
  final _heroSubtitleController = TextEditingController();
  final _introController = TextEditingController();
  final _commercialRegisterController = TextEditingController();
  final _taxNumberController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _addressArController = TextEditingController();
  final _addressEnController = TextEditingController();
  final List<_AboutSectionDraft> _sections = [];
  bool _isLoadingPage = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  Future<void> _load() async {
    setState(() => _isLoadingPage = true);
    final provider = context.read<AboutProvider>();
    await provider.fetchAboutPage();
    if (!mounted) return;
    _applyPage(provider.page);
    setState(() => _isLoadingPage = false);
  }

  void _applyPage(AboutPageContent page) {
    for (final section in _sections) {
      section.dispose();
    }
    _sections.clear();

    _heroTitleController.text = page.heroTitle;
    _heroSubtitleController.text = page.heroSubtitle;
    _introController.text = page.intro;
    _commercialRegisterController.text = page.companyProfile.commercialRegister;
    _taxNumberController.text = page.companyProfile.taxNumber;
    _phoneController.text = page.companyProfile.phone;
    _whatsappController.text = page.companyProfile.whatsapp;
    _emailController.text = page.companyProfile.email;
    _websiteController.text = page.companyProfile.website;
    _addressArController.text = page.companyProfile.addressAr;
    _addressEnController.text = page.companyProfile.addressEn;

    final sortedSections = [...page.sections]
      ..sort((a, b) => a.order.compareTo(b.order));
    _sections.addAll(sortedSections.map(_AboutSectionDraft.fromSection));
  }

  void _addSection() {
    setState(() => _sections.add(_AboutSectionDraft()));
  }

  void _removeSection(int index) {
    final section = _sections.removeAt(index);
    section.dispose();
    setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Missing auth token')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final aboutProvider = context.read<AboutProvider>();
      final sectionsPayload = <Map<String, dynamic>>[];
      for (var index = 0; index < _sections.length; index++) {
        final section = _sections[index];
        final title = section.titleController.text.trim();
        final body = section.bodyController.text.trim();
        if (title.isEmpty && body.isEmpty && section.media.isEmpty) continue;
        if (title.isEmpty) {
          throw Exception('اكتب عنوان القسم رقم ${index + 1}');
        }

        final mediaPayload = <Map<String, dynamic>>[];
        for (
          var mediaIndex = 0;
          mediaIndex < section.media.length;
          mediaIndex++
        ) {
          final item = section.media[mediaIndex];
          final titleText = item.titleController.text.trim();
          final description = item.descriptionController.text.trim();
          final currentUrl = item.currentUrl.trim();

          if (titleText.isEmpty && currentUrl.isEmpty && item.file == null) {
            continue;
          }
          if (titleText.isEmpty) {
            throw Exception(
              'اكتب عنوان العنصر ${mediaIndex + 1} في القسم "$title"',
            );
          }

          var mediaUrl = currentUrl;
          if (item.file != null) {
            mediaUrl = await FirebaseAssetUploadService.uploadFile(
              file: item.file!,
              type: item.type,
              folder: 'about',
              subfolder: 'section-$index',
            );
          }
          if (mediaUrl.isEmpty) {
            throw Exception('اختر ملفًا للعنصر "$titleText"');
          }

          String? thumbnail = item.currentThumbnail.trim().isEmpty
              ? null
              : item.currentThumbnail.trim();
          if (item.type == 'video' && item.thumbnailFile != null) {
            thumbnail = await FirebaseAssetUploadService.uploadFile(
              file: item.thumbnailFile!,
              type: 'image',
              folder: 'about',
              subfolder: 'section-$index-covers',
            );
          }

          mediaPayload.add({
            'title': titleText,
            'description': description,
            'type': item.type,
            'url': mediaUrl,
            if (thumbnail != null && thumbnail.isNotEmpty)
              'thumbnail': thumbnail,
          });
        }

        sectionsPayload.add({
          'title': title,
          'body': body,
          'order': index,
          'media': mediaPayload,
        });
      }

      await aboutProvider.saveAboutPage(
        token: token,
        payload: {
          'heroTitle': _heroTitleController.text.trim(),
          'heroSubtitle': _heroSubtitleController.text.trim(),
          'intro': _introController.text.trim(),
          'companyProfile': {
            'commercialRegister': _commercialRegisterController.text.trim(),
            'taxNumber': _taxNumberController.text.trim(),
            'phone': _phoneController.text.trim(),
            'whatsapp': _whatsappController.text.trim(),
            'email': _emailController.text.trim(),
            'website': _websiteController.text.trim(),
            'addressAr': _addressArController.text.trim(),
            'addressEn': _addressEnController.text.trim(),
          },
          'sections': sectionsPayload,
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حفظ صفحة من نحن')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل الحفظ: $error')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _heroTitleController.dispose();
    _heroSubtitleController.dispose();
    _introController.dispose();
    _commercialRegisterController.dispose();
    _taxNumberController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _addressArController.dispose();
    _addressEnController.dispose();
    for (final section in _sections) {
      section.dispose();
    }
    super.dispose();
  }

  Widget _buildCompanyField({
    required TextEditingController controller,
    required String label,
    String? fallback,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      minLines: maxLines > 1 ? maxLines : null,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: context.tr(label, fallback: fallback),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildCompanyInfoSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        final fieldWidth = isWide
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;

        Widget field({
          required TextEditingController controller,
          required String label,
          String? fallback,
          int maxLines = 1,
          TextInputType? keyboardType,
        }) {
          return SizedBox(
            width: fieldWidth,
            child: _buildCompanyField(
              controller: controller,
              label: label,
              fallback: fallback,
              maxLines: maxLines,
              keyboardType: keyboardType,
            ),
          );
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12),
            color: Colors.white.withValues(alpha: 0.04),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('بيانات الشركة', fallback: 'Company Info'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr(
                  'هذه البيانات تظهر في قسم بيانات الشركة بالصفحة الرئيسية.',
                  fallback:
                      'These values appear in the company info section on the home page.',
                ),
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  field(
                    controller: _commercialRegisterController,
                    label: 'السجل التجاري',
                    fallback: 'Commercial Register',
                  ),
                  field(
                    controller: _taxNumberController,
                    label: 'الرقم الضريبي',
                    fallback: 'Tax Number',
                  ),
                  field(
                    controller: _phoneController,
                    label: 'الهاتف',
                    fallback: 'Phone',
                    keyboardType: TextInputType.phone,
                  ),
                  field(
                    controller: _whatsappController,
                    label: 'واتساب',
                    fallback: 'WhatsApp',
                    keyboardType: TextInputType.phone,
                  ),
                  field(
                    controller: _emailController,
                    label: 'البريد',
                    fallback: 'Email',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  field(
                    controller: _websiteController,
                    label: 'الموقع',
                    fallback: 'Website',
                    keyboardType: TextInputType.url,
                  ),
                  field(
                    controller: _addressArController,
                    label: 'العنوان بالعربية',
                    fallback: 'Arabic Address',
                    maxLines: 3,
                  ),
                  field(
                    controller: _addressEnController,
                    label: 'العنوان بالإنجليزية',
                    fallback: 'English Address',
                    maxLines: 3,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'من نحن',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'حرر الصفحة التعريفية للشركة وأضف أقسامًا وصورًا وفيديوهات.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(_isSaving ? 'جاري الحفظ...' : 'حفظ'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (_isLoadingPage)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(
                        color: Color(0xFFE50914),
                      ),
                    ),
                  )
                else ...[
                  TextFormField(
                    controller: _heroTitleController,
                    decoration: const InputDecoration(
                      labelText: 'العنوان الرئيسي',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'اكتب عنوان الصفحة'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _heroSubtitleController,
                    decoration: const InputDecoration(
                      labelText: 'العنوان الفرعي',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _introController,
                    minLines: 4,
                    maxLines: 7,
                    decoration: const InputDecoration(
                      labelText: 'المقدمة',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 26),
                  _buildCompanyInfoSection(),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'الأقسام',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _addSection,
                        icon: const Icon(Icons.add),
                        label: const Text('إضافة قسم'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_sections.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white12),
                        color: Colors.white.withValues(alpha: 0.04),
                      ),
                      child: const Text('أضف أول قسم في صفحة من نحن.'),
                    )
                  else
                    ...List.generate(_sections.length, (index) {
                      final section = _sections[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _AboutSectionEditorCard(
                          index: index + 1,
                          section: section,
                          onRemove: () => _removeSection(index),
                        ),
                      );
                    }),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AboutSectionDraft {
  final titleController = TextEditingController();
  final bodyController = TextEditingController();
  final List<_AboutMediaDraft> media = [];

  _AboutSectionDraft();

  factory _AboutSectionDraft.fromSection(AboutSection section) {
    final draft = _AboutSectionDraft();
    draft.titleController.text = section.title;
    draft.bodyController.text = section.body;
    draft.media.addAll(section.media.map(_AboutMediaDraft.fromAsset));
    return draft;
  }

  void dispose() {
    titleController.dispose();
    bodyController.dispose();
    for (final item in media) {
      item.dispose();
    }
  }
}

class _AboutMediaDraft {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  String type;
  XFile? file;
  XFile? thumbnailFile;
  String currentUrl;
  String currentThumbnail;

  _AboutMediaDraft({
    this.type = 'image',
    this.currentUrl = '',
    this.currentThumbnail = '',
  });

  factory _AboutMediaDraft.fromAsset(ContentAsset asset) {
    final draft = _AboutMediaDraft(
      type: asset.type,
      currentUrl: asset.url,
      currentThumbnail: asset.thumbnail ?? '',
    );
    draft.titleController.text = asset.title;
    draft.descriptionController.text = asset.description;
    return draft;
  }

  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
  }
}

class _AboutSectionEditorCard extends StatefulWidget {
  final int index;
  final _AboutSectionDraft section;
  final VoidCallback onRemove;

  const _AboutSectionEditorCard({
    required this.index,
    required this.section,
    required this.onRemove,
  });

  @override
  State<_AboutSectionEditorCard> createState() =>
      _AboutSectionEditorCardState();
}

class _AboutSectionEditorCardState extends State<_AboutSectionEditorCard> {
  void _addMedia() {
    setState(() => widget.section.media.add(_AboutMediaDraft()));
  }

  void _removeMedia(int index) {
    final item = widget.section.media.removeAt(index);
    item.dispose();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final section = widget.section;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
        color: Colors.white.withValues(alpha: 0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'القسم ${widget.index}',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _addMedia,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('إضافة وسائط'),
              ),
              IconButton(
                onPressed: widget.onRemove,
                icon: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFE50914),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: section.titleController,
            decoration: const InputDecoration(
              labelText: 'عنوان القسم',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: section.bodyController,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'المحتوى النصي',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          if (section.media.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: const Text('لا توجد وسائط مضافة لهذا القسم.'),
            )
          else
            ...List.generate(section.media.length, (index) {
              final item = section.media[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AboutMediaEditorCard(
                  index: index + 1,
                  item: item,
                  onRemove: () => _removeMedia(index),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _AboutMediaEditorCard extends StatefulWidget {
  final int index;
  final _AboutMediaDraft item;
  final VoidCallback onRemove;

  const _AboutMediaEditorCard({
    required this.index,
    required this.item,
    required this.onRemove,
  });

  @override
  State<_AboutMediaEditorCard> createState() => _AboutMediaEditorCardState();
}

class _AboutMediaEditorCardState extends State<_AboutMediaEditorCard> {
  Future<void> _pickFile() async {
    final picker = ImagePicker();
    final file = widget.item.type == 'video'
        ? await picker.pickVideo(source: ImageSource.gallery)
        : await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => widget.item.file = file);
  }

  Future<void> _pickThumbnail() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => widget.item.thumbnailFile = file);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
        color: Colors.black.withValues(alpha: 0.12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'عنصر ${widget.index}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              IconButton(
                onPressed: widget.onRemove,
                icon: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFE50914),
                ),
              ),
            ],
          ),
          _AboutPickerPanel(
            title: item.type == 'video' ? 'الفيديو' : 'الصورة',
            networkUrl: item.file == null
                ? (item.type == 'video'
                      ? (item.currentThumbnail.trim().isEmpty
                            ? null
                            : item.currentThumbnail)
                      : (item.currentUrl.trim().isEmpty
                            ? null
                            : item.currentUrl))
                : null,
            file: item.file,
            type: item.type,
            onPick: _pickFile,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: item.titleController,
            decoration: const InputDecoration(
              labelText: 'عنوان العنصر',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: item.descriptionController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'الوصف',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey('${widget.index}-${item.type}'),
            initialValue: item.type,
            decoration: const InputDecoration(
              labelText: 'نوع الوسيط',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'image', child: Text('Image')),
              DropdownMenuItem(value: 'video', child: Text('Video')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => item.type = value);
            },
          ),
          if (item.type == 'video') ...[
            const SizedBox(height: 12),
            _AboutPickerPanel(
              title: 'صورة الغلاف',
              networkUrl:
                  item.thumbnailFile == null &&
                      item.currentThumbnail.trim().isNotEmpty
                  ? item.currentThumbnail
                  : null,
              file: item.thumbnailFile,
              type: 'image',
              onPick: _pickThumbnail,
            ),
          ],
        ],
      ),
    );
  }
}

class _AboutPickerPanel extends StatelessWidget {
  final String title;
  final String? networkUrl;
  final XFile? file;
  final String type;
  final VoidCallback onPick;

  const _AboutPickerPanel({
    required this.title,
    required this.networkUrl,
    required this.file,
    required this.type,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPick,
          child: Container(
            height: 170,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
              color: Colors.white.withValues(alpha: 0.04),
            ),
            child: file != null
                ? _AboutLocalFilePreview(file: file!, type: type)
                : (networkUrl != null && networkUrl!.trim().isNotEmpty)
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AppNetworkImage(
                      url: networkUrl!,
                      fit: BoxFit.cover,
                      placeholder: const ColoredBox(color: Colors.white10),
                      errorWidget: const ColoredBox(color: Colors.white10),
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        type == 'video'
                            ? Icons.video_library_outlined
                            : Icons.image_outlined,
                        size: 40,
                        color: Colors.white54,
                      ),
                      const SizedBox(height: 10),
                      const Text('اضغط لاختيار ملف'),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _AboutLocalFilePreview extends StatelessWidget {
  final XFile file;
  final String type;

  const _AboutLocalFilePreview({required this.file, required this.type});

  @override
  Widget build(BuildContext context) {
    if (type == 'video') {
      return const Center(
        child: Icon(Icons.play_circle_fill, size: 54, color: Colors.white70),
      );
    }

    return FutureBuilder<Uint8List>(
      future: file.readAsBytes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFE50914)),
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        );
      },
    );
  }
}
