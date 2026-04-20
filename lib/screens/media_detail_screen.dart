import 'package:flutter/material.dart';
import '../models/media.dart';

class MediaDetailScreen extends StatelessWidget {
  final Media media;
  const MediaDetailScreen({super.key, required this.media});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(media.title)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (media.isVideo)
            // Placeholder for video player
            const SizedBox(
              height: 200,
              child: ColoredBox(
                color: Colors.black12,
                child: Center(child: Icon(Icons.play_arrow, size: 64)),
              ),
            )
          else
            Image.network(media.url, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(media.description, style: const TextStyle(fontSize: 16)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Category: ${media.category}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Views: ${media.views}', style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
