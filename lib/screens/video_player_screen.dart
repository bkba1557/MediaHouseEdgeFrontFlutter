import 'package:flutter/material.dart';

import '../models/media.dart';
import '../widgets/app_network_image.dart';
import '../widgets/app_video_player.dart';

class VideoPlayerScreen extends StatelessWidget {
  final Media media;
  final List<Media>? playlist;
  final String? playlistTitle;

  const VideoPlayerScreen({
    super.key,
    required this.media,
    this.playlist,
    this.playlistTitle,
  });

  @override
  Widget build(BuildContext context) {
    final coverUrl = media.thumbnail;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < 600;
    final heroHeight = compact ? (screenWidth * 1.05).clamp(360.0, 460.0) : 420.0;
    final playerPadding = compact
        ? const EdgeInsets.fromLTRB(12, 72, 12, 18)
        : const EdgeInsets.fromLTRB(16, 56, 16, 16);

    return Scaffold(
      appBar: AppBar(title: Text(media.title)),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: heroHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (coverUrl != null && coverUrl.trim().isNotEmpty)
                  AppNetworkImage(
                    url: coverUrl,
                    fit: BoxFit.cover,
                    placeholder: const ColoredBox(color: Colors.black),
                    errorWidget: const ColoredBox(color: Colors.black),
                  )
                else
                  const ColoredBox(color: Colors.black),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.55),
                        Colors.black.withValues(alpha: 0.92),
                      ],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: playerPadding,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 980),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.black,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                              ),
                              child: AppVideoPlayer(
                                url: Uri.parse(media.url),
                                autoPlay: false,
                                looping: false,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      media.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (media.description.trim().isNotEmpty) ...[
                      const Text(
                        'الوصف',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        media.description,
                        style: const TextStyle(color: Colors.white70, height: 1.5),
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (media.crew.isNotEmpty) ...[
                      const Text(
                        'فريق العمل',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 118,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: media.crew.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final member = media.crew[index];
                            return SizedBox(
                              width: 104,
                              child: Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: SizedBox(
                                      width: 70,
                                      height: 70,
                                      child: member.photoUrl.trim().isEmpty
                                          ? const ColoredBox(color: Colors.white10)
                                          : AppNetworkImage(
                                              url: member.photoUrl,
                                              fit: BoxFit.cover,
                                              placeholder: const ColoredBox(
                                                color: Colors.white10,
                                              ),
                                              errorWidget: const ColoredBox(
                                                color: Colors.white10,
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
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    member.role,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (playlist != null && (playlistTitle?.trim().isNotEmpty ?? false)) ...[
                      Text(
                        playlistTitle!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (playlist != null && playlist!.isNotEmpty)
                      SizedBox(
                        height: 152,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: playlist!.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final item = playlist![index];
                            final thumb = item.thumbnail ?? '';
                            return InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => VideoPlayerScreen(
                                      media: item,
                                      playlist: playlist,
                                      playlistTitle: playlistTitle,
                                    ),
                                  ),
                                );
                              },
                              child: SizedBox(
                                width: 210,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      if (thumb.trim().isNotEmpty)
                                        AppNetworkImage(
                                          url: thumb,
                                          fit: BoxFit.cover,
                                          placeholder: const ColoredBox(
                                            color: Colors.white10,
                                          ),
                                          errorWidget: const ColoredBox(
                                            color: Colors.white10,
                                          ),
                                        )
                                      else
                                        const ColoredBox(color: Colors.white10),
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
                                      Positioned(
                                        left: 10,
                                        right: 10,
                                        bottom: 10,
                                        child: Text(
                                          item.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      if (item.id == media.id)
                                        Positioned(
                                          top: 10,
                                          left: 10,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE50914)
                                                  .withValues(alpha: 0.75),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: const Text(
                                              'Now',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                        ),
                                      const Align(
                                        alignment: Alignment.center,
                                        child: Icon(
                                          Icons.play_circle_fill,
                                          color: Colors.white,
                                          size: 44,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 26),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
