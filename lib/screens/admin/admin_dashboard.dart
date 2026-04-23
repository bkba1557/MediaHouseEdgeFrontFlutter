import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/media.dart';
import '../../providers/auth_provider.dart';
import '../../providers/media_provider.dart';
import '../../providers/response_provider.dart';
import '../../widgets/app_network_image.dart';
import 'upload_media_screen.dart';
import 'responses_screen.dart';
import 'service_requests_screen.dart';

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
    const AdminResponsesScreen(),
    const AdminServiceRequestsScreen(),
  ];

  static const _titles = [
    'لوحة التحكم',
    'رفع المحتوى',
    'الردود',
    'طلبات الخدمات',
  ];

  @override
  Widget build(BuildContext context) {
    final title = _selectedIndex >= 0 && _selectedIndex < _titles.length
        ? _titles[_selectedIndex]
        : 'Admin Dashboard';
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.upload), label: 'رفع'),
          BottomNavigationBarItem(icon: Icon(Icons.feedback), label: 'الردود'),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            label: 'الطلبات',
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
                  const Text(
                    'Welcome, Admin!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                        'Total Media',
                        '${mediaProvider.mediaList.length}',
                        Icons.photo_library,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        'Total Responses',
                        '${responseProvider.responses.length}',
                        Icons.feedback,
                        Colors.green,
                      ),
                      _buildStatCard(
                        'Pending Replies',
                        '${responseProvider.responses.where((r) => r.status == 'pending').length}',
                        Icons.pending,
                        Colors.orange,
                      ),
                      _buildStatCard(
                        'Total Views',
                        '${mediaProvider.mediaList.fold(0, (sum, item) => sum + item.views)}',
                        Icons.visibility,
                        const Color(0xFFE50914),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Recent Media',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
    ];

    String type = typeOptions.contains(media.type) ? media.type : 'image';
    String category = categoryOptions.contains(media.category)
        ? media.category
        : 'film';

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
                          value: type,
                          decoration: const InputDecoration(labelText: 'Type'),
                          items: typeOptions
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setDialogState(() => type = value ?? type),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: category,
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
                          onChanged: (value) => setDialogState(
                            () => category = value ?? category,
                          ),
                        ),
                        if (category == 'series_movies') ...[
                          const SizedBox(height: 10),
                          TextField(
                            controller: collectionTitleController,
                            decoration: const InputDecoration(
                              labelText: 'Folder / Series name',
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: sequenceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Order (episode/part number)',
                            ),
                          ),
                        ],
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
      final updatedCollectionTitle = collectionTitleController.text.trim();
      final updatedSequence = int.tryParse(sequenceController.text.trim());

      await mediaProvider.updateMediaMetadata(
        id: media.id,
        token: token,
        title: updatedTitle,
        description: updatedDescription,
        type: type,
        category: category,
        collectionTitle:
            category == 'series_movies' && updatedCollectionTitle.isNotEmpty
            ? updatedCollectionTitle
            : null,
        collectionKey:
            category == 'series_movies' && updatedCollectionTitle.isNotEmpty
            ? updatedCollectionTitle
                  .trim()
                  .toLowerCase()
                  .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
                  .replaceAll(RegExp(r'^_+|_+$'), '')
            : null,
        sequence: category == 'series_movies' ? updatedSequence : null,
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
