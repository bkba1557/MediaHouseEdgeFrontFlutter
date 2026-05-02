import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../config/service_folder_config.dart';
import '../../localization/app_localizations.dart';
import '../../models/media.dart';
import '../../providers/auth_provider.dart';
import '../../providers/about_provider.dart';
import '../../providers/media_provider.dart';
import '../../providers/response_provider.dart';
import '../../providers/team_provider.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/fixed_aspect_cropper_dialog.dart';
import 'about_management_screen.dart';
import 'folder_order_management_screen.dart';
import 'notification_campaign_screen.dart';
import 'upload_media_screen.dart';
import 'responses_screen.dart';
import 'service_requests_screen.dart';
import 'team_management_screen.dart';
import 'user_management_screen.dart';

typedef _AdminMediaEditHandler =
    Future<void> Function({
      required BuildContext context,
      required Media media,
      required MediaProvider mediaProvider,
      required AuthProvider authProvider,
    });

typedef _AdminMediaDeleteHandler =
    Future<void> Function({
      required BuildContext context,
      required Media media,
      required MediaProvider mediaProvider,
      required AuthProvider authProvider,
    });

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const AdminHomeScreen(),
    const UploadMediaScreen(),
    const TeamManagementScreen(),
    const AboutManagementScreen(),
    const AdminResponsesScreen(),
    const AdminServiceRequestsScreen(),
    const AdminNotificationCampaignScreen(embedded: true),
    const AdminUserManagementScreen(embedded: true),
  ];

  String _titleForIndex(BuildContext context, int index) {
    switch (index) {
      case 0:
        return context.tr('لوحة التحكم');
      case 1:
        return context.tr('رفع المحتوى', fallback: 'Upload Content');
      case 2:
        return context.tr('فريق العمل', fallback: 'Team');
      case 3:
        return context.tr('من نحن', fallback: 'About Us');
      case 4:
        return context.tr('الردود', fallback: 'Responses');
      case 5:
        return context.tr('طلبات الخدمات', fallback: 'Service Requests');
      case 6:
        return context.tr('إرسال العروض', fallback: 'Send Promotions');
      case 7:
        return context.tr('إدارة المستخدمين', fallback: 'Manage Users');
      default:
        return context.tr('لوحة التحكم', fallback: 'Dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _titleForIndex(context, _selectedIndex);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFFE50914),
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: const Color(0xFFE50914),
        unselectedItemColor: Colors.white70,
        backgroundColor: Colors.black,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard),
            label: context.tr('الرئيسية', fallback: 'Home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.upload),
            label: context.tr('رفع', fallback: 'Upload'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.groups_2_outlined),
            label: context.tr('الفريق', fallback: 'Team'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.info_outline),
            label: context.tr('من نحن', fallback: 'About Us'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.feedback),
            label: context.tr('الردود', fallback: 'Responses'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.assignment_outlined),
            label: context.tr('الطلبات', fallback: 'Requests'),
          ),
        ],
      ),
    );
  }
}

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mediaProvider = Provider.of<MediaProvider>(context);
    final responseProvider = Provider.of<ResponseProvider>(context);
    final teamProvider = Provider.of<TeamProvider>(context);
    final aboutProvider = Provider.of<AboutProvider>(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final horizontalPadding = width < 600 ? 12.0 : 24.0;
        final statColumns = width >= 1100
            ? 4
            : width >= 720
            ? 2
            : 1;
        final statAspectRatio = width >= 1100
            ? 2.8
            : width >= 720
            ? 2.4
            : 3.6;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            16,
            horizontalPadding,
            96,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(
                      'مرحبًا، أيها المدير!',
                      fallback: 'Welcome, Admin!',
                    ),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _AdminShortcutButton(
                        icon: Icons.notifications_active_outlined,
                        label: context.tr(
                          'إرسال العروض',
                          fallback: 'Send Promotions',
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Scaffold(
                                appBar: AppBar(
                                  title: const Text('Send Promotions'),
                                ),
                                body: const AdminNotificationCampaignScreen(),
                              ),
                            ),
                          );
                        },
                      ),
                      _AdminShortcutButton(
                        icon: Icons.manage_accounts_outlined,
                        label: context.tr(
                          'إدارة المستخدمين',
                          fallback: 'Manage Users',
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminUserManagementScreen(),
                            ),
                          );
                        },
                      ),
                      _AdminShortcutButton(
                        icon: Icons.reorder_rounded,
                        label: context.tr(
                          'ترتيب الفولدرات',
                          fallback: 'Arrange Folders',
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const FolderOrderManagementScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: statColumns,
                    childAspectRatio: statAspectRatio,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: [
                      _buildStatCard(
                        context.tr('إجمالي الوسائط', fallback: 'Total Media'),
                        '${mediaProvider.mediaList.length}',
                        Icons.photo_library,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        context.tr(
                          'إجمالي الردود',
                          fallback: 'Total Responses',
                        ),
                        '${responseProvider.responses.length}',
                        Icons.feedback,
                        Colors.green,
                      ),
                      _buildStatCard(
                        context.tr('ردود معلقة', fallback: 'Pending Replies'),
                        '${responseProvider.responses.where((r) => r.status == 'pending').length}',
                        Icons.pending,
                        Colors.orange,
                      ),
                      _buildStatCard(
                        context.tr('إجمالي المشاهدات', fallback: 'Total Views'),
                        '${mediaProvider.mediaList.fold(0, (sum, item) => sum + item.views)}',
                        Icons.visibility,
                        const Color(0xFFE50914),
                      ),
                      _buildStatCard(
                        context.tr('أعضاء الفريق', fallback: 'Team Members'),
                        '${teamProvider.members.length}',
                        Icons.groups_2_outlined,
                        Colors.purpleAccent,
                      ),
                      _buildStatCard(
                        context.tr('أقسام من نحن', fallback: 'About Sections'),
                        '${aboutProvider.page.sections.length}',
                        Icons.info_outline,
                        Colors.tealAccent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.tr('أحدث الوسائط', fallback: 'Recent Media'),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => _AdminMediaLibraryScreen(
                                onEdit: _showEditMediaDialog,
                                onDelete: _confirmDeleteMedia,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.grid_view_rounded, size: 18),
                        label: Text(
                          context.tr(
                            'عرض كل الوسائط',
                            fallback: 'View All Media',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildRecentMedia(context, mediaProvider),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentMedia(BuildContext context, MediaProvider mediaProvider) {
    final recentMedia = mediaProvider.mediaList.take(8).toList();
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (recentMedia.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white12),
        ),
        child: const Text('No media uploaded yet'),
      );
    }

    return SizedBox(
      height: isMobile ? 160 : 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: recentMedia.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final media = recentMedia[index];
          return SizedBox(
            width: isMobile ? 132 : 160,
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (media.previewImageUrl != null)
                          AppNetworkImage(
                            url: media.previewImageUrl!,
                            fit: BoxFit.cover,
                            placeholder: Container(
                              color: Colors.black.withValues(alpha: 0.20),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFE50914),
                                ),
                              ),
                            ),
                            errorWidget: Container(
                              color: Colors.black.withValues(alpha: 0.20),
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            color: Colors.black.withValues(alpha: 0.20),
                            child: const Center(
                              child: Icon(
                                Icons.play_circle_outline,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _AdminMediaAction(
                                icon: Icons.edit_outlined,
                                tooltip: 'Edit',
                                onPressed: () => _showEditMediaDialog(
                                  context: context,
                                  media: media,
                                  mediaProvider: mediaProvider,
                                  authProvider: authProvider,
                                ),
                              ),
                              const SizedBox(width: 6),
                              _AdminMediaAction(
                                icon: Icons.delete_outline,
                                tooltip: 'Delete',
                                color: const Color(0xFFE50914),
                                onPressed: () => _confirmDeleteMedia(
                                  context: context,
                                  media: media,
                                  mediaProvider: mediaProvider,
                                  authProvider: authProvider,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      media.title,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteMedia({
    required BuildContext context,
    required Media media,
    required MediaProvider mediaProvider,
    required AuthProvider authProvider,
  }) async {
    final token = authProvider.token;
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
            title: const Text('Delete media?'),
            content: Text('Delete "${media.title}" permanently?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE50914),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      await mediaProvider.deleteMedia(media.id, token);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Deleted')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $error')));
    }
  }

  Future<void> _showEditMediaDialog({
    required BuildContext context,
    required Media media,
    required MediaProvider mediaProvider,
    required AuthProvider authProvider,
  }) async {
    final token = authProvider.token;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Missing auth token')));
      return;
    }

    final titleController = TextEditingController(text: media.title);
    final descriptionController = TextEditingController(
      text: media.description,
    );
    final collectionTitleController = TextEditingController(
      text: media.collectionTitle ?? '',
    );
    final sequenceController = TextEditingController(
      text: media.sequence?.toString() ?? '',
    );

    const typeOptions = ['image', 'video'];
    const categoryOptions = [
      'film',
      'montage',
      'advertisement',
      'story',
      'series_movies',
      'ads_shooting',
      'podcast',
      'video_clip',
      'art_production',
      'platform_distribution',
      'commercial_ads',
      'global_events',
      'media_coverage',
      'audio_recordings',
      'gov_partnership_ads',
      'artist_contracts',
      'behind_the_scenes',
      'dj_booking',
      'international_institutions',
    ];

    String type = typeOptions.contains(media.type) ? media.type : 'image';
    String category = categoryOptions.contains(media.category)
        ? media.category
        : 'film';
    var folderOptions = await _loadFolderOptions(
      mediaProvider,
      category,
      currentOption: _currentFolderOption(media),
    );
    String? selectedCollectionKey = _currentFolderOption(media)?.collectionKey;
    XFile? replacementFile;
    XFile? replacementCoverFile;
    bool isAddingCustomFolder = false;
    bool isLoadingFolders = false;
    collectionTitleController.clear();
    if (serviceCategoryRequiresFolder(category) &&
        selectedCollectionKey == null &&
        folderOptions.isNotEmpty) {
      selectedCollectionKey = folderOptions.first.collectionKey;
    }
    if (!context.mounted) return;

    bool saved = false;
    try {
      saved =
          await showDialog<bool>(
            context: context,
            builder: (dialogContext) => StatefulBuilder(
              builder: (dialogContext, setDialogState) => AlertDialog(
                title: const Text('Edit media'),
                content: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: titleController,
                          decoration: const InputDecoration(labelText: 'Title'),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: descriptionController,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: type,
                          decoration: const InputDecoration(labelText: 'Type'),
                          items: typeOptions
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                          onChanged: (value) => setDialogState(() {
                            final nextType = value ?? type;
                            if (nextType == type) return;
                            type = nextType;
                            replacementFile = null;
                            if (type == 'image') {
                              replacementCoverFile = null;
                            }
                          }),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: category,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                          ),
                          items: categoryOptions
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                          onChanged: (value) async {
                            if (value == null || value == category) return;

                            setDialogState(() {
                              category = value;
                              isLoadingFolders = serviceCategoryRequiresFolder(
                                value,
                              );
                            });

                            if (value != 'series_movies') {
                              sequenceController.clear();
                            }

                            if (!serviceCategoryRequiresFolder(value)) {
                              setDialogState(() {
                                folderOptions = const [];
                                selectedCollectionKey = null;
                                isAddingCustomFolder = false;
                                isLoadingFolders = false;
                                collectionTitleController.clear();
                              });
                              return;
                            }

                            final loadedOptions = await _loadFolderOptions(
                              mediaProvider,
                              value,
                            );
                            if (!dialogContext.mounted) return;

                            setDialogState(() {
                              folderOptions = loadedOptions;
                              isLoadingFolders = false;
                              collectionTitleController.clear();
                              if (loadedOptions.isEmpty) {
                                selectedCollectionKey = null;
                                isAddingCustomFolder = true;
                                return;
                              }

                              selectedCollectionKey =
                                  loadedOptions.first.collectionKey;
                              isAddingCustomFolder = false;
                            });
                          },
                        ),
                        if (serviceCategoryRequiresFolder(category)) ...[
                          const SizedBox(height: 10),
                          if (isLoadingFolders)
                            const LinearProgressIndicator(minHeight: 2),
                          if (folderOptions.isNotEmpty && !isAddingCustomFolder)
                            DropdownButtonFormField<String>(
                              initialValue: selectedCollectionKey,
                              decoration: const InputDecoration(
                                labelText: 'Folder',
                              ),
                              items: folderOptions
                                  .map(
                                    (option) => DropdownMenuItem(
                                      value: option.collectionKey,
                                      child: Text(option.collectionTitle),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) => setDialogState(
                                () => selectedCollectionKey = value,
                              ),
                            )
                          else
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Text(
                                folderOptions.isEmpty
                                    ? 'No folders yet. Add a new one below.'
                                    : 'Create a new folder for this section.',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              TextButton.icon(
                                onPressed: isAddingCustomFolder
                                    ? null
                                    : () {
                                        setDialogState(() {
                                          isAddingCustomFolder = true;
                                          selectedCollectionKey = null;
                                          collectionTitleController.clear();
                                        });
                                      },
                                icon: const Icon(
                                  Icons.create_new_folder_outlined,
                                ),
                                label: const Text('New folder'),
                              ),
                              if (folderOptions.isNotEmpty)
                                TextButton.icon(
                                  onPressed: !isAddingCustomFolder
                                      ? null
                                      : () {
                                          setDialogState(() {
                                            isAddingCustomFolder = false;
                                            collectionTitleController.clear();
                                            selectedCollectionKey =
                                                folderOptions
                                                    .first
                                                    .collectionKey;
                                          });
                                        },
                                  icon: const Icon(Icons.folder_open_outlined),
                                  label: const Text('Use existing'),
                                ),
                            ],
                          ),
                          if (isAddingCustomFolder) ...[
                            const SizedBox(height: 8),
                            TextField(
                              controller: collectionTitleController,
                              decoration: const InputDecoration(
                                labelText: 'New folder name',
                              ),
                            ),
                          ],
                        ],
                        if (category == 'series_movies') ...[
                          const SizedBox(height: 10),
                          TextField(
                            controller: sequenceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Order (episode/part number)',
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Media file',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: SizedBox(
                                      width: 76,
                                      height: 76,
                                      child: media.previewImageUrl != null
                                          ? AppNetworkImage(
                                              url: media.previewImageUrl!,
                                              fit: BoxFit.cover,
                                              placeholder: Container(
                                                color: Colors.black.withValues(
                                                  alpha: 0.22,
                                                ),
                                              ),
                                              errorWidget: Container(
                                                color: Colors.black.withValues(
                                                  alpha: 0.22,
                                                ),
                                                child: const Icon(
                                                  Icons.broken_image_outlined,
                                                ),
                                              ),
                                            )
                                          : Container(
                                              color: Colors.black.withValues(
                                                alpha: 0.22,
                                              ),
                                              child: const Icon(
                                                Icons.play_circle_outline,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          replacementFile == null
                                              ? 'Current ${type == 'video' ? 'video' : 'image'} will stay as is'
                                              : 'Selected file: ${replacementFile!.name}',
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.88,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            OutlinedButton.icon(
                                              onPressed: () async {
                                                final picked =
                                                    await _pickReplacementMediaFile(
                                                      dialogContext,
                                                      type: type,
                                                      category: category,
                                                    );
                                                if (picked == null ||
                                                    !dialogContext.mounted) {
                                                  return;
                                                }
                                                setDialogState(
                                                  () =>
                                                      replacementFile = picked,
                                                );
                                              },
                                              icon: Icon(
                                                type == 'video'
                                                    ? Icons.video_file_outlined
                                                    : Icons.image_outlined,
                                              ),
                                              label: Text(
                                                replacementFile == null
                                                    ? (type == 'video'
                                                          ? 'Change video'
                                                          : 'Change image')
                                                    : 'Pick another file',
                                              ),
                                            ),
                                            if (replacementFile != null)
                                              TextButton.icon(
                                                onPressed: () => setDialogState(
                                                  () => replacementFile = null,
                                                ),
                                                icon: const Icon(
                                                  Icons.close_rounded,
                                                ),
                                                label: const Text('Clear'),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (type == 'video') ...[
                                const SizedBox(height: 12),
                                Text(
                                  replacementCoverFile == null
                                      ? 'Keep the current cover or pick a new one'
                                      : 'Selected cover: ${replacementCoverFile!.name}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.78),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () async {
                                        final picked =
                                            await _pickReplacementCoverFile(
                                              dialogContext,
                                              category: category,
                                            );
                                        if (picked == null ||
                                            !dialogContext.mounted) {
                                          return;
                                        }
                                        setDialogState(
                                          () => replacementCoverFile = picked,
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.wallpaper_outlined,
                                      ),
                                      label: Text(
                                        replacementCoverFile == null
                                            ? 'Change cover'
                                            : 'Pick another cover',
                                      ),
                                    ),
                                    if (replacementCoverFile != null)
                                      TextButton.icon(
                                        onPressed: () => setDialogState(
                                          () => replacementCoverFile = null,
                                        ),
                                        icon: const Icon(Icons.close_rounded),
                                        label: const Text('Clear'),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE50914),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
          ) ??
          false;
      if (!saved) return;

      final updatedTitle = titleController.text.trim();
      final updatedDescription = descriptionController.text.trim();
      final updatedCollectionTitle = isAddingCustomFolder
          ? normalizeFolderTitle(collectionTitleController.text)
          : _resolveFolderTitle(folderOptions, selectedCollectionKey);
      final updatedSequence = int.tryParse(sequenceController.text.trim());

      if (updatedTitle.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Title is required')));
        return;
      }

      if (serviceCategoryRequiresFolder(category) &&
          updatedCollectionTitle == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select a folder or create a new one')),
        );
        return;
      }

      if (type != media.type && replacementFile == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Choose a new file when changing the media type'),
          ),
        );
        return;
      }

      await mediaProvider.updateMedia(
        id: media.id,
        token: token,
        title: updatedTitle,
        description: updatedDescription,
        type: type,
        category: category,
        replacementFile: replacementFile,
        replacementCoverFile: replacementCoverFile,
        collectionTitle: updatedCollectionTitle,
        collectionKey: updatedCollectionTitle == null
            ? null
            : buildCollectionKey(updatedCollectionTitle),
        sequence: category == 'series_movies' ? updatedSequence : null,
        clearCollectionFields: !serviceCategoryRequiresFolder(category),
        clearSequence: category != 'series_movies',
        clearThumbnail: type == 'image',
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Updated')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Update failed: $error')));
    } finally {
      titleController.dispose();
      descriptionController.dispose();
      collectionTitleController.dispose();
      sequenceController.dispose();
    }
  }

  Future<List<ServiceFolderOption>> _loadFolderOptions(
    MediaProvider mediaProvider,
    String category, {
    ServiceFolderOption? currentOption,
  }) async {
    if (!serviceCategoryRequiresFolder(category)) return const [];

    final merged = <String, ServiceFolderOption>{};
    for (final option in defaultFoldersForCategory(category)) {
      merged[option.collectionKey] = option;
    }

    try {
      final fetched = await mediaProvider.fetchFolders(category: category);
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

    if (currentOption != null) {
      merged[currentOption.collectionKey] = currentOption;
    }

    final options = merged.values.toList(growable: false)
      ..sort(compareFolderOptions);
    return options;
  }

  ServiceFolderOption? _currentFolderOption(Media media) {
    final title = normalizeFolderTitle(media.collectionTitle ?? '');
    if (title.isEmpty) return null;

    final existingKey = (media.collectionKey ?? '').trim();
    final key = existingKey.isEmpty ? buildCollectionKey(title) : existingKey;
    if (key.isEmpty) return null;

    return ServiceFolderOption(collectionKey: key, collectionTitle: title);
  }

  String? _resolveFolderTitle(
    List<ServiceFolderOption> options,
    String? collectionKey,
  ) {
    if (collectionKey == null || collectionKey.trim().isEmpty) return null;
    for (final option in options) {
      if (option.collectionKey == collectionKey) {
        return option.collectionTitle;
      }
    }
    return null;
  }

  double _imageAspectRatioForCategory(String category) {
    if (category == 'advertisement') return 16 / 9;
    if (category == 'series_movies') return 0.72;
    return 0.86;
  }

  Future<XFile?> _pickReplacementMediaFile(
    BuildContext context, {
    required String type,
    required String category,
  }) async {
    final picker = ImagePicker();
    if (type == 'video') {
      return picker.pickVideo(source: ImageSource.gallery);
    }

    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return null;
    if (!context.mounted) return null;

    return showFixedAspectCropperDialog(
      context,
      sourceFile: file,
      aspectRatio: _imageAspectRatioForCategory(category),
      title: category == 'advertisement'
          ? 'Crop banner image'
          : 'Crop media image',
    );
  }

  Future<XFile?> _pickReplacementCoverFile(
    BuildContext context, {
    required String category,
  }) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return null;
    if (!context.mounted) return null;

    return showFixedAspectCropperDialog(
      context,
      sourceFile: file,
      aspectRatio: _imageAspectRatioForCategory(category),
      title: 'Crop cover image',
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 26, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminMediaLibraryScreen extends StatefulWidget {
  final _AdminMediaEditHandler onEdit;
  final _AdminMediaDeleteHandler onDelete;

  const _AdminMediaLibraryScreen({
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_AdminMediaLibraryScreen> createState() =>
      _AdminMediaLibraryScreenState();
}

class _AdminMediaLibraryScreenState extends State<_AdminMediaLibraryScreen> {
  String _typeFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MediaProvider>().fetchMedia();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaProvider = context.watch<MediaProvider>();
    final authProvider = context.read<AuthProvider>();
    final allMedia = mediaProvider.mediaList;
    final filteredMedia = allMedia
        .where((media) {
          if (_typeFilter == 'all') return true;
          return media.type == _typeFilter;
        })
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: const Text('كل الميديا')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final crossAxisCount = width >= 1350
              ? 5
              : width >= 1040
              ? 4
              : width >= 760
              ? 3
              : 2;
          final childAspectRatio = width >= 760 ? 0.76 : 0.70;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'عرض وإدارة كل الميديا (${filteredMedia.length})',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Refresh',
                          onPressed: mediaProvider.isLoading
                              ? null
                              : () => mediaProvider.fetchMedia(),
                          icon: const Icon(Icons.refresh_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MediaTypeFilterChip(
                          label: 'الكل',
                          selected: _typeFilter == 'all',
                          onTap: () => setState(() => _typeFilter = 'all'),
                        ),
                        _MediaTypeFilterChip(
                          label: 'صور',
                          selected: _typeFilter == 'image',
                          onTap: () => setState(() => _typeFilter = 'image'),
                        ),
                        _MediaTypeFilterChip(
                          label: 'فيديو',
                          selected: _typeFilter == 'video',
                          onTap: () => setState(() => _typeFilter = 'video'),
                        ),
                      ],
                    ),
                    if (mediaProvider.isLoading) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(minHeight: 2),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: filteredMedia.isEmpty
                    ? Center(
                        child: Text(
                          mediaProvider.isLoading
                              ? 'جاري تحميل الميديا...'
                              : mediaProvider.error?.isNotEmpty == true
                              ? mediaProvider.error!
                              : 'لا توجد عناصر مطابقة للفلتر الحالي',
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: childAspectRatio,
                        ),
                        itemCount: filteredMedia.length,
                        itemBuilder: (context, index) {
                          final media = filteredMedia[index];
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      if (media.previewImageUrl != null)
                                        AppNetworkImage(
                                          url: media.previewImageUrl!,
                                          fit: BoxFit.cover,
                                          placeholder: Container(
                                            color: Colors.black.withValues(
                                              alpha: 0.20,
                                            ),
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Color(0xFFE50914),
                                              ),
                                            ),
                                          ),
                                          errorWidget: Container(
                                            color: Colors.black.withValues(
                                              alpha: 0.20,
                                            ),
                                            child: const Center(
                                              child: Icon(
                                                Icons.broken_image_outlined,
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ),
                                        )
                                      else
                                        Container(
                                          color: Colors.black.withValues(
                                            alpha: 0.20,
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.play_circle_outline,
                                              color: Colors.white70,
                                              size: 34,
                                            ),
                                          ),
                                        ),
                                      Positioned(
                                        top: 8,
                                        left: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.60,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                          ),
                                          child: Text(
                                            media.isVideo ? 'Video' : 'Image',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _AdminMediaAction(
                                              icon: Icons.edit_outlined,
                                              tooltip: 'Edit',
                                              onPressed: () => widget.onEdit(
                                                context: context,
                                                media: media,
                                                mediaProvider: mediaProvider,
                                                authProvider: authProvider,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            _AdminMediaAction(
                                              icon: Icons.delete_outline,
                                              tooltip: 'Delete',
                                              color: const Color(0xFFE50914),
                                              onPressed: () => widget.onDelete(
                                                context: context,
                                                media: media,
                                                mediaProvider: mediaProvider,
                                                authProvider: authProvider,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        media.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        media.category,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.visibility_outlined,
                                            size: 14,
                                            color: Colors.white60,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${media.views}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AdminMediaAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color? color;
  final VoidCallback onPressed;

  const _AdminMediaAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, size: 18, color: color ?? Colors.white),
          ),
        ),
      ),
    );
  }
}

class _MediaTypeFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MediaTypeFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      label: Text(label),
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFFE50914).withValues(alpha: 0.18),
      checkmarkColor: const Color(0xFFE50914),
      side: BorderSide(
        color: selected
            ? const Color(0xFFE50914)
            : Colors.white.withValues(alpha: 0.12),
      ),
    );
  }
}

class _AdminShortcutButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _AdminShortcutButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
