import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/media.dart';
import '../providers/media_provider.dart';
import '../widgets/app_network_image.dart';
import '../widgets/service_request_sheet.dart';
import 'series_folder_items_screen.dart';

class SeriesFoldersScreen extends StatefulWidget {
  const SeriesFoldersScreen({super.key});

  @override
  State<SeriesFoldersScreen> createState() => _SeriesFoldersScreenState();
}

class _SeriesFoldersScreenState extends State<SeriesFoldersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await Provider.of<MediaProvider>(
      context,
      listen: false,
    ).fetchMedia(category: 'series_movies');
  }

  Future<void> _openRequest() async {
    await showServiceRequestSheet(
      context,
      serviceCategory: 'series_movies',
      serviceTitle: 'مسلسلات وأفلام',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مسلسلات وأفلام'),
        actions: [
          TextButton.icon(
            onPressed: _openRequest,
            icon: const Icon(Icons.assignment_outlined),
            label: const Text('تقديم طلب'),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Consumer<MediaProvider>(
        builder: (context, mediaProvider, _) {
          if (mediaProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE50914)),
            );
          }

          final error = mediaProvider.error;
          if (error != null && error.trim().isNotEmpty) {
            return _ErrorState(message: error, onRetry: _load);
          }

          final items = mediaProvider.mediaList
              .where((m) => m.category == 'series_movies')
              .toList(growable: false);
          final folders = _groupByFolder(items);

          if (folders.isEmpty) {
            return _EmptyState(onRequest: _openRequest);
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final columns = width >= 1200
                  ? 5
                  : width >= 960
                  ? 4
                  : width >= 720
                  ? 3
                  : 2;
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: folders.length,
                itemBuilder: (context, index) {
                  final folder = folders[index];
                  return _FolderTile(
                    title: folder.title,
                    count: folder.items.length,
                    preview: folder.items.firstOrNull,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SeriesFolderItemsScreen(
                            collectionKey: folder.collectionKey,
                            collectionTitle: folder.title,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  List<_FolderGroup> _groupByFolder(List<Media> items) {
    final groups = <String, _FolderGroup>{};
    for (final media in items) {
      final key = (media.collectionKey ?? '').trim();
      final title = (media.collectionTitle ?? '').trim();
      if (key.isEmpty || title.isEmpty) continue;

      groups.putIfAbsent(
        key,
        () => _FolderGroup(collectionKey: key, title: title),
      );
      groups[key]!.items.add(media);
    }

    final list = groups.values.toList(growable: false);
    list.sort((a, b) => a.title.compareTo(b.title));
    for (final group in list) {
      group.items.sort((a, b) {
        final sa = a.sequence ?? 1 << 30;
        final sb = b.sequence ?? 1 << 30;
        final bySeq = sa.compareTo(sb);
        if (bySeq != 0) return bySeq;
        return a.createdAt.compareTo(b.createdAt);
      });
    }
    return list;
  }
}

class _FolderGroup {
  final String collectionKey;
  final String title;
  final List<Media> items = [];

  _FolderGroup({required this.collectionKey, required this.title});
}

class _FolderTile extends StatelessWidget {
  final String title;
  final int count;
  final Media? preview;
  final VoidCallback onTap;

  const _FolderTile({
    required this.title,
    required this.count,
    required this.preview,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final coverUrl = preview?.previewImageUrl;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Colors.black),
                if (coverUrl != null && coverUrl.trim().isNotEmpty)
                  AppNetworkImage(
                    url: coverUrl,
                    fit: BoxFit.contain,
                    placeholder: const ColoredBox(color: Colors.white10),
                    errorWidget: const ColoredBox(color: Colors.white10),
                  )
                else
                  const ColoredBox(color: Colors.white10),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.06),
                        Colors.black.withValues(alpha: 0.82),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$count عنصر',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onRequest;

  const _EmptyState({required this.onRequest});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.folder_open, size: 64, color: Colors.white54),
              const SizedBox(height: 12),
              const Text(
                'لا توجد مجلدات حالياً',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: onRequest,
                icon: const Icon(Icons.assignment_outlined),
                label: const Text('تقديم طلب الخدمة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wifi_off_outlined,
                size: 64,
                color: Colors.white54,
              ),
              const SizedBox(height: 12),
              const Text(
                'حصل خطأ أثناء تحميل المحتوى',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
