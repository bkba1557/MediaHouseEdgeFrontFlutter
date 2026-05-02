import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/media_folder.dart';
import '../../providers/auth_provider.dart';
import '../../providers/media_provider.dart';
import '../../widgets/app_network_image.dart';

class FolderOrderManagementScreen extends StatefulWidget {
  const FolderOrderManagementScreen({super.key});

  @override
  State<FolderOrderManagementScreen> createState() =>
      _FolderOrderManagementScreenState();
}

class _FolderOrderManagementScreenState
    extends State<FolderOrderManagementScreen> {
  static const _categories = [
    ('artist_contracts', 'تعاقدات فنانين'),
    ('commercial_ads', 'إعلانات تجارية'),
    ('series_movies', 'مسلسلات وأفلام'),
  ];

  String _selectedCategory = _categories.first.$1;
  List<MediaFolder> _folders = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadFolders();
    });
  }

  Future<void> _loadFolders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final folders = await context.read<MediaProvider>().fetchFolders(
        category: _selectedCategory,
      );
      if (!mounted) return;
      setState(() => _folders = folders);
    } catch (error) {
      if (mounted) {
        setState(() => _error = '$error');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveOrder() async {
    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Missing auth token')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final folders = await context.read<MediaProvider>().reorderFolders(
        category: _selectedCategory,
        folders: _folders,
        token: token,
      );
      if (!mounted) return;
      setState(() => _folders = folders);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حفظ ترتيب الفولدرات')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('فشل حفظ الترتيب: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final updated = List<MediaFolder>.from(_folders);
      final item = updated.removeAt(oldIndex);
      updated.insert(newIndex, item);
      _folders = updated;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ترتيب الفولدرات'),
        actions: [
          TextButton.icon(
            onPressed: _isLoading || _isSaving ? null : _saveOrder,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_isSaving ? 'جارٍ الحفظ...' : 'حفظ الترتيب'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'اسحب الفولدرات لأعلى أو لأسفل ثم احفظ الترتيب.',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories
                      .map(
                        (entry) => ChoiceChip(
                          selected: _selectedCategory == entry.$1,
                          label: Text(entry.$2),
                          onSelected: (_) {
                            if (_selectedCategory == entry.$1) return;
                            setState(() => _selectedCategory = entry.$1);
                            _loadFolders();
                          },
                          selectedColor: const Color(
                            0xFFE50914,
                          ).withValues(alpha: 0.20),
                          side: BorderSide(
                            color: _selectedCategory == entry.$1
                                ? const Color(0xFFE50914)
                                : Colors.white24,
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  )
                : _folders.isEmpty
                ? const Center(
                    child: Text(
                      'لا توجد فولدرات لترتيبها في هذا القسم حاليًا',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: _folders.length,
                    onReorder: _reorder,
                    proxyDecorator: (child, _, animation) {
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (context, _) => Material(
                          color: Colors.transparent,
                          elevation: 8,
                          borderRadius: BorderRadius.circular(16),
                          child: child,
                        ),
                      );
                    },
                    itemBuilder: (context, index) {
                      final folder = _folders[index];
                      return _FolderOrderTile(
                        key: ValueKey(folder.collectionKey),
                        folder: folder,
                        index: index,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FolderOrderTile extends StatelessWidget {
  final MediaFolder folder;
  final int index;

  const _FolderOrderTile({
    super.key,
    required this.folder,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final previewUrl = (folder.previewUrl ?? '').trim();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 64,
            height: 64,
            child: previewUrl.isEmpty
                ? Container(
                    color: Colors.white.withValues(alpha: 0.06),
                    alignment: Alignment.center,
                    child: const Icon(Icons.folder_open_outlined),
                  )
                : AppNetworkImage(
                    url: previewUrl,
                    fit: BoxFit.cover,
                    placeholder: Container(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                    errorWidget: Container(
                      color: Colors.white.withValues(alpha: 0.06),
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
          ),
        ),
        title: Text(
          folder.collectionTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text('${folder.count} عنصر'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFE50914).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: 8),
            ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
