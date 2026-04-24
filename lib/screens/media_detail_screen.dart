import 'package:flutter/material.dart';
import '../models/media.dart';
import '../localization/app_localizations.dart';
import '../widgets/app_network_image.dart';
import '../widgets/app_video_player.dart';
import 'dart:math' as math;

class MediaDetailScreen extends StatelessWidget {
  final Media media;
  const MediaDetailScreen({super.key, required this.media});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final maxImageHeight = size.height * 0.62;
    final idealHeight = size.width * (9 / 16);
    final imageHeight = math.min(maxImageHeight, idealHeight);

    return Scaffold(
      appBar: AppBar(title: Text(media.title)),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          if (media.isVideo)
            SizedBox(
              height: math.min(320, size.height * 0.42),
              child: ColoredBox(
                color: Colors.black,
                child: AppVideoPlayer(
                  url: Uri.parse(media.url),
                  autoPlay: true,
                  looping: false,
                ),
              ),
            )
          else
            SizedBox(
              height: imageHeight,
              child: AppNetworkImage(
                url: media.url,
                fit: BoxFit.contain,
                placeholder: const Center(
                  child: CircularProgressIndicator(color: Color(0xFFE50914)),
                ),
                errorWidget: const Center(
                  child: Icon(Icons.broken_image_outlined, size: 60),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              media.description,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              context.tr(
                'Category: {category}',
                params: {'category': media.category},
              ),
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              context.tr('Views: {views}', params: {'views': '${media.views}'}),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          if (media.crew.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                context.tr('Crew / فريق العمل'),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 112,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: media.crew.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final member = media.crew[index];
                  return SizedBox(
                    width: 96,
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: SizedBox(
                            width: 64,
                            height: 64,
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
                          style: const TextStyle(fontWeight: FontWeight.w800),
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
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
