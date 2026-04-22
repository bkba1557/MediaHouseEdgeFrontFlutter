import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/media.dart';
import '../providers/media_provider.dart';
import '../widgets/app_network_image.dart';
import '../widgets/service_request_sheet.dart';
import 'image_viewer_screen.dart';
import 'video_player_screen.dart';

enum _FolderFilter { all, images, videos }

class SeriesFolderItemsScreen extends StatefulWidget {
  final String collectionKey;
  final String collectionTitle;

  const SeriesFolderItemsScreen({
    super.key,
    required this.collectionKey,
    required this.collectionTitle,
  });

  @override
  State<SeriesFolderItemsScreen> createState() => _SeriesFolderItemsScreenState();
}

class _SeriesFolderItemsScreenState extends State<SeriesFolderItemsScreen> {
  _FolderFilter _filter = _FolderFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await Provider.of<MediaProvider>(context, listen: false)
        .fetchMedia(category: 'series_movies');
  }

  Future<void> _openRequest() async {
    await showServiceRequestSheet(
      context,
      serviceCategory: 'series_movies',
      serviceTitle: 'مسلسلات وأفلام',
    );
  }

  List<Media> _folderItems(List<Media> all) {
    final items = all
        .where(
          (m) =>
              m.category == 'series_movies' &&
              (m.collectionKey ?? '') == widget.collectionKey,
        )
        .toList(growable: false);

    items.sort((a, b) {
      final sa = a.sequence ?? 1 << 30;
      final sb = b.sequence ?? 1 << 30;
      final bySeq = sa.compareTo(sb);
      if (bySeq != 0) return bySeq;
      return a.createdAt.compareTo(b.createdAt);
    });

    return items;
  }

  List<Media> _applyFilter(List<Media> items) {
    if (_filter == _FolderFilter.images) {
      return items.where((m) => m.isImage).toList(growable: false);
    }
    if (_filter == _FolderFilter.videos) {
      return items.where((m) => m.isVideo).toList(growable: false);
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.collectionTitle),
        actions: [
          TextButton.icon(
            onPressed: _openRequest,
            icon: const Icon(Icons.assignment_outlined),
            label: const Text('تقديم طلب'),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: _FiltersBar(
              filter: _filter,
              onChanged: (value) {
                if (_filter == value) return;
                setState(() => _filter = value);
              },
            ),
          ),
          Expanded(
            child: Consumer<MediaProvider>(
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

                final folderItems = _folderItems(mediaProvider.mediaList);
                if (folderItems.isEmpty) {
                  return const Center(
                    child: Text(
                      'لا توجد عناصر في هذا المجلد',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                final items = _applyFilter(folderItems);
                if (items.isEmpty) {
                  return const Center(
                    child: Text(
                      'لا يوجد محتوى لهذا الفلتر',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                final playlist =
                    folderItems.where((m) => m.isVideo).toList(growable: false);

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
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final media = items[index];
                        final number = media.sequence ?? (index + 1);
                        return _EpisodeCard(
                          media: media,
                          number: number,
                          onTap: () {
                            if (media.isImage) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ImageViewerScreen(
                                    urls: [media.url],
                                    titles: [media.title],
                                  ),
                                ),
                              );
                              return;
                            }

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VideoPlayerScreen(
                                  media: media,
                                  playlist: playlist,
                                  playlistTitle: 'الحلقات',
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
          ),
        ],
      ),
    );
  }
}

class _FiltersBar extends StatelessWidget {
  final _FolderFilter filter;
  final ValueChanged<_FolderFilter> onChanged;

  const _FiltersBar({required this.filter, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    ChoiceChip chip(_FolderFilter value, String label, IconData icon) {
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
        chip(_FolderFilter.all, 'الكل', Icons.grid_view_outlined),
        chip(_FolderFilter.images, 'صور', Icons.image_outlined),
        chip(_FolderFilter.videos, 'فيديو', Icons.play_circle_outline),
      ],
    );
  }
}

class _EpisodeCard extends StatelessWidget {
  final Media media;
  final int number;
  final VoidCallback onTap;

  const _EpisodeCard({
    required this.media,
    required this.number,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final thumb = (media.thumbnail ?? '').trim();
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
                if (thumb.isNotEmpty)
                  AppNetworkImage(
                    url: thumb,
                    fit: BoxFit.cover,
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
                        Colors.black.withValues(alpha: 0.05),
                        Colors.black.withValues(alpha: 0.88),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE50914).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE50914)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$number',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 10,
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
                      media.isVideo ? 'VIDEO' : 'IMAGE',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ),
                if (media.isVideo)
                  const Align(
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.play_circle_fill,
                      color: Colors.white,
                      size: 54,
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
                        media.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          height: 1.15,
                        ),
                      ),
                      if (media.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          media.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            height: 1.2,
                          ),
                        ),
                      ],
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
              const Icon(Icons.wifi_off_outlined, size: 64, color: Colors.white54),
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

