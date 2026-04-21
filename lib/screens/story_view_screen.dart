import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/media.dart';
import '../widgets/app_network_image.dart';

class StoryViewScreen extends StatefulWidget {
  final Media media;

  const StoryViewScreen({super.key, required this.media});

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen> {
  VideoPlayerController? _videoController;
  bool _isVideoReady = false;

  @override
  void initState() {
    super.initState();
    if (widget.media.isVideo) {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.media.url),
      )..initialize().then((_) {
          if (!mounted) return;
          setState(() => _isVideoReady = true);
          _videoController
            ?..setLooping(true)
            ..play();
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: _buildStoryMedia()),
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.media.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (widget.media.description.isNotEmpty)
                          Text(
                            widget.media.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70),
                          ),
                      ],
                    ),
                  ),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.48),
                    ),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryMedia() {
    if (widget.media.isVideo) {
      if (!_isVideoReady || _videoController == null) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFFE50914)),
        );
      }

      return Center(
        child: AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        ),
      );
    }

    return InteractiveViewer(
      minScale: 1,
      maxScale: 3,
      child: Center(
        child: AppNetworkImage(
          url: widget.media.url,
          fit: BoxFit.contain,
          placeholder: const CircularProgressIndicator(color: Color(0xFFE50914)),
          errorWidget: const Icon(
            Icons.broken_image_outlined,
            color: Colors.white,
            size: 54,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }
}
