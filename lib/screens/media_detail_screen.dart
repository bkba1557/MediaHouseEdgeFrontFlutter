import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/app_localizations.dart';
import '../models/media.dart';
import '../providers/auth_provider.dart';
import '../providers/media_provider.dart';
import '../widgets/app_network_image.dart';
import '../widgets/app_video_player.dart';

class MediaDetailScreen extends StatefulWidget {
  final Media media;

  const MediaDetailScreen({super.key, required this.media});

  @override
  State<MediaDetailScreen> createState() => _MediaDetailScreenState();
}

class _MediaDetailScreenState extends State<MediaDetailScreen> {
  late Media _media;
  bool _didSyncViews = false;
  bool _isSyncingViews = false;

  @override
  void initState() {
    super.initState();
    _media = widget.media;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didSyncViews) return;
    _didSyncViews = true;

    final isAdmin = context.read<AuthProvider>().isAdmin;
    if (!isAdmin) {
      _refreshMediaDetails();
    }
  }

  Future<void> _refreshMediaDetails() async {
    setState(() => _isSyncingViews = true);

    try {
      final updated = await context.read<MediaProvider>().fetchMediaById(
        _media.id,
      );
      if (!mounted) return;
      setState(() => _media = updated);
    } catch (_) {
      // Keep the initial media data when the live refresh fails.
    } finally {
      if (mounted) {
        setState(() => _isSyncingViews = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAdmin = context.select<AuthProvider, bool>((auth) => auth.isAdmin);
    final size = MediaQuery.sizeOf(context);
    final maxImageHeight = size.height * 0.62;
    final idealImageHeight = size.width * (9 / 16);
    final imageHeight = math.min(maxImageHeight, idealImageHeight);
    final previewHeight = _media.isVideo
        ? math.min(360.0, size.height * 0.42)
        : imageHeight;

    return Scaffold(
      appBar: AppBar(
        title: Text(_media.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          if (_isSyncingViews) const LinearProgressIndicator(minHeight: 2),
          SizedBox(
            height: previewHeight,
            child: _media.isVideo
                ? ColoredBox(
                    color: Colors.black,
                    child: AppVideoPlayer(
                      url: Uri.parse(_media.url),
                      autoPlay: true,
                      looping: false,
                    ),
                  )
                : AppNetworkImage(
                    url: _media.url,
                    fit: BoxFit.contain,
                    placeholder: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE50914),
                      ),
                    ),
                    errorWidget: const Center(
                      child: Icon(Icons.broken_image_outlined, size: 60),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _media.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetaChip(
                      icon: _media.isVideo
                          ? Icons.play_circle_outline_rounded
                          : Icons.image_outlined,
                      label:
                          '${context.tr('النوع', fallback: 'Type')}: ${context.tr(_media.isVideo ? 'فيديو' : 'صورة', fallback: _media.isVideo ? 'Video' : 'Image')}',
                    ),
                    _MetaChip(
                      icon: Icons.category_outlined,
                      label:
                          '${context.tr('التصنيف', fallback: 'Category')}: ${_media.category}',
                    ),
                    if ((_media.collectionTitle ?? '').trim().isNotEmpty)
                      _MetaChip(
                        icon: Icons.folder_open_outlined,
                        label:
                            '${context.tr('المجلد', fallback: 'Folder')}: ${_media.collectionTitle!.trim()}',
                      ),
                    _MetaChip(
                      icon: Icons.visibility_outlined,
                      label:
                          '${context.tr('المشاهدات', fallback: 'Views')}: ${_media.views}',
                    ),
                    _MetaChip(
                      icon: Icons.calendar_today_outlined,
                      label:
                          '${context.tr('التاريخ', fallback: 'Date')}: ${_formatDate(_media.createdAt)}',
                    ),
                    if (isAdmin && (_media.uploadedBy ?? '').trim().isNotEmpty)
                      _MetaChip(
                        icon: Icons.person_outline_rounded,
                        label:
                            '${context.tr('بواسطة', fallback: 'By')}: ${_media.uploadedBy!.trim()}',
                      ),
                  ],
                ),
                if (_media.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    context.tr('الوصف', fallback: 'Description'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Text(
                      _media.description,
                      style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                    ),
                  ),
                ],
                if (_media.crew.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    context.tr('فريق العمل', fallback: 'Crew'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 118,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _media.crew.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final member = _media.crew[index];
                        return SizedBox(
                          width: 102,
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: SizedBox(
                                  width: 66,
                                  height: 66,
                                  child: member.photoUrl.trim().isEmpty
                                      ? ColoredBox(
                                          color: theme
                                              .colorScheme
                                              .surfaceContainerHighest,
                                        )
                                      : AppNetworkImage(
                                          url: member.photoUrl,
                                          fit: BoxFit.cover,
                                          placeholder: ColoredBox(
                                            color: theme
                                                .colorScheme
                                                .surfaceContainerHighest,
                                          ),
                                          errorWidget: ColoredBox(
                                            color: theme
                                                .colorScheme
                                                .surfaceContainerHighest,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                member.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                member.role,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.textTheme.bodySmall?.color
                                      ?.withValues(alpha: 0.72),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.32,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFE50914)),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
