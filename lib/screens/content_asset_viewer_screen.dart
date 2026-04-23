import 'package:flutter/material.dart';

import '../models/content_asset.dart';
import '../widgets/app_network_image.dart';
import '../widgets/app_video_player.dart';

class ContentAssetViewerScreen extends StatelessWidget {
  final ContentAsset asset;

  const ContentAssetViewerScreen({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(asset.title.isEmpty ? 'Preview' : asset.title),
      ),
      body: asset.isVideo ? _buildVideoView() : _buildImageView(),
    );
  }

  Widget _buildVideoView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: DecoratedBox(
                decoration: const BoxDecoration(color: Colors.black),
                child: AppVideoPlayer(
                  url: Uri.parse(asset.url),
                  autoPlay: false,
                  looping: false,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageView() {
    return InteractiveViewer(
      minScale: 0.8,
      maxScale: 4,
      child: Center(
        child: AppNetworkImage(
          url: asset.url,
          fit: BoxFit.contain,
          placeholder: const ColoredBox(color: Colors.black),
          errorWidget: const ColoredBox(color: Colors.black),
        ),
      ),
    );
  }
}
