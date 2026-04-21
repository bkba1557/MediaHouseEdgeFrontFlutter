import 'package:flutter/material.dart';
import '../models/media.dart';
import '../widgets/app_network_image.dart';
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
              height: math.min(260, size.height * 0.35),
              child: const ColoredBox(
                color: Colors.black12,
                child: Center(child: Icon(Icons.play_arrow, size: 64)),
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
            child: Text(media.description, style: const TextStyle(fontSize: 16)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Category: ${media.category}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Views: ${media.views}', style: const TextStyle(fontSize: 14)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
