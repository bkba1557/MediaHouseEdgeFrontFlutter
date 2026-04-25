import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/service_folder_config.dart';
import '../models/media.dart';
import '../providers/media_provider.dart';
import '../widgets/app_network_image.dart';
import '../widgets/auto_play_video_preview.dart';
import '../widgets/service_request_sheet.dart';
import 'image_viewer_screen.dart';
import 'service_folder_items_screen.dart';
import 'story_view_screen.dart';
import 'video_player_screen.dart';

enum _ServiceFeedFilter { all, images, videos }

class ServiceFeedScreen extends StatefulWidget {
  final String serviceKey;
  final String serviceTitle;
  final String serviceSubtitle;

  const ServiceFeedScreen({
    super.key,
    required this.serviceKey,
    required this.serviceTitle,
    required this.serviceSubtitle,
  });

  @override
  State<ServiceFeedScreen> createState() => _ServiceFeedScreenState();
}

class _ServiceFeedScreenState extends State<ServiceFeedScreen> {
  _ServiceFeedFilter _filter = _ServiceFeedFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final mediaProvider = context.read<MediaProvider>();
    final type = switch (_filter) {
      _ServiceFeedFilter.images => 'image',
      _ServiceFeedFilter.videos => 'video',
      _ServiceFeedFilter.all => null,
    };
    await mediaProvider.fetchMedia(category: widget.serviceKey, type: type);
  }

  Future<void> _openRequestSheet() async {
    await showServiceRequestSheet(
      context,
      serviceCategory: widget.serviceKey,
      serviceTitle: widget.serviceTitle,
    );
  }

  bool _usesFolders(List<Media> items) {
    if (serviceCategoryRequiresFolder(widget.serviceKey)) return true;
    if (defaultFoldersForCategory(widget.serviceKey).isNotEmpty) return true;
    return items.any((item) {
      final key = (item.collectionKey ?? '').trim();
      final title = (item.collectionTitle ?? '').trim();
      return key.isNotEmpty && title.isNotEmpty;
    });
  }

  List<_FolderGroup> _groupByFolder(List<Media> items) {
    final groups = <String, _FolderGroup>{};

    for (final preset in defaultFoldersForCategory(widget.serviceKey)) {
      groups[preset.collectionKey] = _FolderGroup(
        collectionKey: preset.collectionKey,
        title: preset.collectionTitle,
      );
    }

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
        final bySequence = sa.compareTo(sb);
        if (bySequence != 0) return bySequence;
        return a.createdAt.compareTo(b.createdAt);
      });
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.serviceTitle),
        actions: [
          TextButton.icon(
            onPressed: _openRequestSheet,
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
              .where((item) => item.category == widget.serviceKey)
              .toList(growable: false);

          if (_usesFolders(items)) {
            final folders = _groupByFolder(items);
            if (folders.isEmpty) {
              return _EmptyState(
                subtitle: widget.serviceSubtitle,
                onRequest: _openRequestSheet,
                icon: Icons.folder_open,
                title: 'لا توجد مجلدات حالياً',
              );
            }

            return _FoldersView(
              folders: folders,
              onOpenFolder: (folder) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: context.read<MediaProvider>(),
                      child: ServiceFolderItemsScreen(
                        serviceCategory: widget.serviceKey,
                        serviceTitle: widget.serviceTitle,
                        collectionKey: folder.collectionKey,
                        collectionTitle: folder.title,
                      ),
                    ),
                  ),
                );
              },
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: _FiltersBar(
                  filter: _filter,
                  onChanged: (value) {
                    if (_filter == value) return;
                    setState(() => _filter = value);
                    _load();
                  },
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? _EmptyState(
                        subtitle: widget.serviceSubtitle,
                        onRequest: _openRequestSheet,
                        icon: Icons.movie_filter_outlined,
                        title: 'لا توجد منشورات لهذه الخدمة حالياً',
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final columns = width >= 1100
                              ? 5
                              : width >= 860
                              ? 4
                              : width >= 560
                              ? 3
                              : 2;
                          return GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 0.86,
                                ),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              return _MediaTile(media: items[index]);
                            },
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

class _FolderGroup {
  final String collectionKey;
  final String title;
  final List<Media> items = [];

  _FolderGroup({required this.collectionKey, required this.title});
}

class _FoldersView extends StatelessWidget {
  final List<_FolderGroup> folders;
  final ValueChanged<_FolderGroup> onOpenFolder;

  const _FoldersView({required this.folders, required this.onOpenFolder});

  @override
  Widget build(BuildContext context) {
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
              preview: folder.items.isEmpty ? null : folder.items.first,
              onTap: () => onOpenFolder(folder),
            );
          },
        );
      },
    );
  }
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
                if (preview?.isVideo == true)
                  IgnorePointer(
                    child: AutoPlayVideoPreview(
                      url: Uri.parse(preview!.url),
                      fit: BoxFit.cover,
                      placeholder:
                          coverUrl != null && coverUrl.trim().isNotEmpty
                          ? AppNetworkImage(
                              url: coverUrl,
                              fit: BoxFit.contain,
                              placeholder: const ColoredBox(
                                color: Colors.white10,
                              ),
                              errorWidget: const ColoredBox(
                                color: Colors.white10,
                              ),
                            )
                          : const ColoredBox(color: Colors.white10),
                      errorWidget:
                          coverUrl != null && coverUrl.trim().isNotEmpty
                          ? AppNetworkImage(
                              url: coverUrl,
                              fit: BoxFit.contain,
                              placeholder: const ColoredBox(
                                color: Colors.white10,
                              ),
                              errorWidget: const ColoredBox(
                                color: Colors.white10,
                              ),
                            )
                          : const ColoredBox(color: Colors.white10),
                    ),
                  )
                else if (coverUrl != null && coverUrl.trim().isNotEmpty)
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

class _FiltersBar extends StatelessWidget {
  final _ServiceFeedFilter filter;
  final ValueChanged<_ServiceFeedFilter> onChanged;

  const _FiltersBar({required this.filter, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    ChoiceChip chip(_ServiceFeedFilter value, String label, IconData icon) {
      final selected = filter == value;
      return ChoiceChip(
        selected: selected,
        onSelected: (_) => onChanged(value),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
        selectedColor: const Color(0xFFE50914).withValues(alpha: 0.22),
        backgroundColor: Colors.white.withValues(alpha: 0.06),
        labelStyle: TextStyle(color: selected ? Colors.white : Colors.white70),
        side: BorderSide(
          color: selected ? const Color(0xFFE50914) : Colors.white24,
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        chip(_ServiceFeedFilter.all, 'الكل', Icons.grid_view_outlined),
        chip(_ServiceFeedFilter.images, 'صور', Icons.image_outlined),
        chip(_ServiceFeedFilter.videos, 'فيديو', Icons.play_circle_outline),
      ],
    );
  }
}

class _MediaTile extends StatelessWidget {
  final Media media;

  const _MediaTile({required this.media});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        if (media.isImage) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ImageViewerScreen(urls: [media.url], titles: [media.title]),
            ),
          );
          return;
        }
        if (media.category == 'story') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => StoryViewScreen(media: media)),
          );
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => VideoPlayerScreen(media: media)),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Colors.black),
            if (media.isVideo)
              IgnorePointer(
                child: AutoPlayVideoPreview(
                  url: Uri.parse(media.url),
                  fit: BoxFit.cover,
                  placeholder: media.previewImageUrl != null
                      ? AppNetworkImage(
                          url: media.previewImageUrl!,
                          fit: BoxFit.contain,
                          placeholder: Container(color: Colors.white10),
                          errorWidget: Container(
                            color: Colors.white10,
                            child: const Icon(
                              Icons.broken_image_outlined,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : const ColoredBox(color: Colors.white10),
                  errorWidget: media.previewImageUrl != null
                      ? AppNetworkImage(
                          url: media.previewImageUrl!,
                          fit: BoxFit.contain,
                          placeholder: Container(color: Colors.white10),
                          errorWidget: Container(
                            color: Colors.white10,
                            child: const Icon(
                              Icons.broken_image_outlined,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : const ColoredBox(color: Colors.white10),
                ),
              )
            else if (media.previewImageUrl != null)
              AppNetworkImage(
                url: media.previewImageUrl!,
                fit: BoxFit.contain,
                placeholder: Container(color: Colors.white10),
                errorWidget: Container(
                  color: Colors.white10,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white,
                  ),
                ),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.86),
                  ],
                ),
              ),
            ),
            if (media.isVideo)
              const Center(
                child: Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
                  size: 46,
                ),
              ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: Text(
                media.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String subtitle;
  final VoidCallback onRequest;
  final IconData icon;
  final String title;

  const _EmptyState({
    required this.subtitle,
    required this.onRequest,
    required this.icon,
    required this.title,
  });

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
              Icon(icon, size: 64, color: Colors.white54),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
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
