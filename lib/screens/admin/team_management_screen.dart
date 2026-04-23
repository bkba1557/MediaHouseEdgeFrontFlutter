import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/content_asset.dart';
import '../../models/team_member.dart';
import '../../providers/auth_provider.dart';
import '../../providers/team_provider.dart';
import '../../services/firebase_asset_upload_service.dart';
import '../../widgets/app_network_image.dart';

class TeamManagementScreen extends StatefulWidget {
  const TeamManagementScreen({super.key});

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TeamProvider>().fetchTeamMembers();
    });
  }

  Future<void> _openEditor([TeamMember? member]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TeamMemberEditorScreen(member: member),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _deleteMember(TeamMember member) async {
    final token = context.read<AuthProvider>().token;
    final teamProvider = context.read<TeamProvider>();
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Missing auth token')));
      return;
    }

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('حذف عضو الفريق؟'),
            content: Text('سيتم حذف "${member.name}" نهائيًا.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('حذف'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      await teamProvider.deleteTeamMember(member.id, token);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حذف العضو')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل الحذف: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TeamProvider>(
      builder: (context, provider, _) {
        final members = [...provider.members]
          ..sort((a, b) => a.order.compareTo(b.order));

        return RefreshIndicator(
          onRefresh: provider.fetchTeamMembers,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
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
                                  'فريق العمل',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'أضف الموظفين، صورهم، مهاراتهم، وأعمالهم.',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () => _openEditor(),
                            icon: const Icon(Icons.person_add_alt_1_outlined),
                            label: const Text('إضافة عضو'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      if (provider.isLoading && members.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(
                              color: Color(0xFFE50914),
                            ),
                          ),
                        )
                      else if (members.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white12),
                            color: Colors.white.withValues(alpha: 0.04),
                          ),
                          child: const Text(
                            'لا يوجد أعضاء فريق مضافون حتى الآن.',
                          ),
                        )
                      else
                        ...members.map(
                          (member) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _TeamMemberAdminCard(
                              member: member,
                              onEdit: () => _openEditor(member),
                              onDelete: () => _deleteMember(member),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class TeamMemberEditorScreen extends StatefulWidget {
  final TeamMember? member;

  const TeamMemberEditorScreen({super.key, this.member});

  @override
  State<TeamMemberEditorScreen> createState() => _TeamMemberEditorScreenState();
}

class _TeamMemberEditorScreenState extends State<TeamMemberEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _roleController = TextEditingController();
  final _bioController = TextEditingController();
  final _skillsController = TextEditingController();
  final _orderController = TextEditingController();
  final List<_PortfolioDraft> _portfolio = [];
  XFile? _photoFile;
  String? _existingPhotoUrl;
  bool _isSaving = false;

  bool get _isEditing => widget.member != null;

  @override
  void initState() {
    super.initState();
    final member = widget.member;
    if (member == null) return;

    _nameController.text = member.name;
    _roleController.text = member.role;
    _bioController.text = member.bio;
    _skillsController.text = member.skills.join(', ');
    _orderController.text = member.order.toString();
    _existingPhotoUrl = member.photoUrl;
    _portfolio.addAll(
      member.portfolio.map((item) => _PortfolioDraft.fromAsset(item)),
    );
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => _photoFile = file);
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
      final provider = context.read<TeamProvider>();
      var photoUrl = (_existingPhotoUrl ?? '').trim();
      if (_photoFile != null) {
        photoUrl = await FirebaseAssetUploadService.uploadFile(
          file: _photoFile!,
          type: 'image',
          folder: 'team',
          subfolder: 'photos',
        );
      }

      final portfolioPayload = <Map<String, dynamic>>[];
      for (var index = 0; index < _portfolio.length; index++) {
        final item = _portfolio[index];
        final title = item.titleController.text.trim();
        final description = item.descriptionController.text.trim();
        final currentUrl = item.currentUrl.trim();

        if (title.isEmpty && currentUrl.isEmpty && item.file == null) {
          continue;
        }
        if (title.isEmpty) {
          throw Exception('أدخل عنوان العمل رقم ${index + 1}');
        }

        var assetUrl = currentUrl;
        if (item.file != null) {
          assetUrl = await FirebaseAssetUploadService.uploadFile(
            file: item.file!,
            type: item.type,
            folder: 'team',
            subfolder: 'portfolio',
          );
        }
        if (assetUrl.isEmpty) {
          throw Exception('اختر ملفًا للعمل "$title"');
        }

        String? thumbnail = item.currentThumbnail.trim().isEmpty
            ? null
            : item.currentThumbnail.trim();
        if (item.type == 'video' && item.thumbnailFile != null) {
          thumbnail = await FirebaseAssetUploadService.uploadFile(
            file: item.thumbnailFile!,
            type: 'image',
            folder: 'team',
            subfolder: 'portfolio-covers',
          );
        }

        portfolioPayload.add({
          'title': title,
          'description': description,
          'type': item.type,
          'url': assetUrl,
          if (thumbnail != null && thumbnail.isNotEmpty) 'thumbnail': thumbnail,
        });
      }

      final payload = {
        'name': _nameController.text.trim(),
        'role': _roleController.text.trim(),
        'bio': _bioController.text.trim(),
        'photoUrl': photoUrl,
        'skills': _skillsController.text
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList(growable: false),
        'order': int.tryParse(_orderController.text.trim()) ?? 0,
        'portfolio': portfolioPayload,
      };

      if (_isEditing) {
        await provider.updateTeamMember(
          id: widget.member!.id,
          token: token,
          payload: payload,
        );
      } else {
        await provider.createTeamMember(token: token, payload: payload);
      }
      await provider.fetchTeamMembers();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'تم تحديث عضو الفريق' : 'تمت إضافة عضو الفريق',
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل الحفظ: $error')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addPortfolioItem() {
    setState(() => _portfolio.add(_PortfolioDraft()));
  }

  void _removePortfolioItem(int index) {
    final item = _portfolio.removeAt(index);
    item.dispose();
    setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _bioController.dispose();
    _skillsController.dispose();
    _orderController.dispose();
    for (final item in _portfolio) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'تعديل عضو الفريق' : 'إضافة عضو فريق'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: Text(
              _isSaving ? 'جاري الحفظ...' : 'حفظ',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 940),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'البيانات الأساسية',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 14),
                  _ImagePickerPanel(
                    title: 'صورة الموظف',
                    networkUrl: _photoFile == null ? _existingPhotoUrl : null,
                    file: _photoFile,
                    type: 'image',
                    onPick: _pickPhoto,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'الاسم',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'اكتب الاسم'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _roleController,
                    decoration: const InputDecoration(
                      labelText: 'المسمى الوظيفي',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'اكتب المسمى الوظيفي'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _bioController,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'نبذة تعريفية',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _skillsController,
                    decoration: const InputDecoration(
                      labelText: 'المهارات (افصل بينها بفاصلة)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _orderController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'الترتيب',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'الأعمال',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _addPortfolioItem,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: const Text('إضافة عمل'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_portfolio.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white12),
                        color: Colors.white.withValues(alpha: 0.04),
                      ),
                      child: const Text('أضف أعمال الموظف بالصور أو الفيديو.'),
                    )
                  else
                    ...List.generate(_portfolio.length, (index) {
                      final item = _portfolio[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _PortfolioDraftCard(
                          index: index + 1,
                          draft: item,
                          onRemove: () => _removePortfolioItem(index),
                        ),
                      );
                    }),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          _isSaving ? 'جاري الحفظ...' : 'حفظ البيانات',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
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
}

class _TeamMemberAdminCard extends StatelessWidget {
  final TeamMember member;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TeamMemberAdminCard({
    required this.member,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
        color: Colors.white.withValues(alpha: 0.04),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 84,
              height: 84,
              child: member.photoUrl.trim().isEmpty
                  ? Container(
                      color: Colors.white10,
                      child: const Icon(
                        Icons.person_outline,
                        color: Colors.white70,
                      ),
                    )
                  : AppNetworkImage(
                      url: member.photoUrl,
                      fit: BoxFit.cover,
                      placeholder: const ColoredBox(color: Colors.white10),
                      errorWidget: const ColoredBox(color: Colors.white10),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  member.role,
                  style: const TextStyle(color: Colors.white70),
                ),
                if (member.bio.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    member.bio,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, height: 1.5),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      icon: Icons.badge_outlined,
                      label: 'ترتيب ${member.order}',
                    ),
                    _InfoChip(
                      icon: Icons.work_outline,
                      label: '${member.portfolio.length} أعمال',
                    ),
                    if (member.skills.isNotEmpty)
                      _InfoChip(
                        icon: Icons.auto_awesome_outlined,
                        label: '${member.skills.length} مهارات',
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'تعديل',
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFE50914),
                ),
                tooltip: 'حذف',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFE50914)),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}

class _PortfolioDraft {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  String type;
  XFile? file;
  XFile? thumbnailFile;
  String currentUrl;
  String currentThumbnail;

  _PortfolioDraft({
    this.type = 'image',
    this.currentUrl = '',
    this.currentThumbnail = '',
  });

  factory _PortfolioDraft.fromAsset(ContentAsset asset) {
    final draft = _PortfolioDraft(
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

class _PortfolioDraftCard extends StatefulWidget {
  final int index;
  final _PortfolioDraft draft;
  final VoidCallback onRemove;

  const _PortfolioDraftCard({
    required this.index,
    required this.draft,
    required this.onRemove,
  });

  @override
  State<_PortfolioDraftCard> createState() => _PortfolioDraftCardState();
}

class _PortfolioDraftCardState extends State<_PortfolioDraftCard> {
  Future<void> _pickAsset() async {
    final picker = ImagePicker();
    final file = widget.draft.type == 'video'
        ? await picker.pickVideo(source: ImageSource.gallery)
        : await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => widget.draft.file = file);
  }

  Future<void> _pickThumbnail() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => widget.draft.thumbnailFile = file);
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;

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
                'العمل ${widget.index}',
                style: const TextStyle(fontWeight: FontWeight.w900),
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
          _ImagePickerPanel(
            title: draft.type == 'video' ? 'الفيديو' : 'الصورة',
            networkUrl: draft.file == null
                ? (draft.type == 'video'
                      ? (draft.currentThumbnail.trim().isEmpty
                            ? null
                            : draft.currentThumbnail)
                      : (draft.currentUrl.trim().isEmpty
                            ? null
                            : draft.currentUrl))
                : null,
            file: draft.file,
            type: draft.type,
            onPick: _pickAsset,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: draft.titleController,
            decoration: const InputDecoration(
              labelText: 'عنوان العمل',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: draft.descriptionController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'وصف العمل',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey('${widget.index}-${draft.type}'),
            initialValue: draft.type,
            decoration: const InputDecoration(
              labelText: 'نوع الملف',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'image', child: Text('Image')),
              DropdownMenuItem(value: 'video', child: Text('Video')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => draft.type = value);
            },
          ),
          if (draft.type == 'video') ...[
            const SizedBox(height: 12),
            _ImagePickerPanel(
              title: 'صورة الغلاف',
              networkUrl:
                  draft.thumbnailFile == null &&
                      draft.currentThumbnail.trim().isNotEmpty
                  ? draft.currentThumbnail
                  : null,
              file: draft.thumbnailFile,
              type: 'image',
              onPick: _pickThumbnail,
            ),
          ],
        ],
      ),
    );
  }
}

class _ImagePickerPanel extends StatelessWidget {
  final String title;
  final String? networkUrl;
  final XFile? file;
  final String type;
  final VoidCallback onPick;

  const _ImagePickerPanel({
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
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
              color: Colors.white.withValues(alpha: 0.04),
            ),
            child: file != null
                ? _LocalFilePreview(file: file!, type: type)
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

class _LocalFilePreview extends StatelessWidget {
  final XFile file;
  final String type;

  const _LocalFilePreview({required this.file, required this.type});

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
