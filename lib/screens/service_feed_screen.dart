import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/app_localizations.dart';
import '../models/media.dart';
import '../providers/media_provider.dart';
import '../widgets/app_network_image.dart';
import '../widgets/auto_play_video_preview.dart';
import '../widgets/service_request_sheet.dart';
import 'image_viewer_screen.dart';
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
    final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
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
      serviceTitle: context.tr(widget.serviceTitle),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(widget.serviceTitle)),
        actions: [
          TextButton.icon(
            onPressed: _openRequestSheet,
            icon: const Icon(Icons.assignment_outlined),
            label: Text(context.tr('تقديم طلب')),
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
                _load();
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

                final items = mediaProvider.mediaList
                    .where((m) => m.category == widget.serviceKey)
                    .toList(growable: false);

                if (items.isEmpty) {
                  return _EmptyState(
                    subtitle: widget.serviceSubtitle,
                    onRequest: _openRequestSheet,
                  );
                }

                return LayoutBuilder(
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
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.86,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final media = items[index];
                        return _MediaTile(media: media);
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
        chip(
          _ServiceFeedFilter.all,
          context.tr('الكل'),
          Icons.grid_view_outlined,
        ),
        chip(
          _ServiceFeedFilter.images,
          context.tr('صور'),
          Icons.image_outlined,
        ),
        chip(
          _ServiceFeedFilter.videos,
          context.tr('فيديو'),
          Icons.play_circle_outline,
        ),
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

  const _EmptyState({required this.subtitle, required this.onRequest});

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
              const Icon(
                Icons.movie_filter_outlined,
                size: 64,
                color: Colors.white54,
              ),
              const SizedBox(height: 12),
              Text(
                context.tr('لا توجد منشورات لهذه الخدمة حالياً'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr(subtitle),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRequest,
                icon: const Icon(Icons.assignment_outlined),
                label: Text(context.tr('تقديم طلب الخدمة')),
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
              Text(
                context.tr('حصل خطأ أثناء تحميل المحتوى'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
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
                label: Text(context.tr('إعادة المحاولة')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
