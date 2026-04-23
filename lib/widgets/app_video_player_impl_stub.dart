import 'package:chewie/chewie.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../config/app_config.dart';
import 'app_video_player.dart';

class AppVideoPlayerImplFactory extends StatefulWidget
    implements AppVideoPlayer {
  final Uri url;
  final bool autoPlay;
  final bool looping;
  final bool allowFullScreen;
  final bool allowPlaybackSpeedChanging;

  const AppVideoPlayerImplFactory({
    super.key,
    required this.url,
    this.autoPlay = false,
    this.looping = false,
    this.allowFullScreen = true,
    this.allowPlaybackSpeedChanging = true,
  });

  @override
  State<AppVideoPlayerImplFactory> createState() =>
      _AppVideoPlayerImplFactoryState();
}

class _AppVideoPlayerImplFactoryState
    extends State<AppVideoPlayerImplFactory> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  String? _error;

  Uri _resolveVideoUri(Uri uri) {
    if (!kIsWeb) return uri;

    if (!uri.hasScheme) {
      final backend = Uri.parse(AppConfig.apiBaseUrl);
      final backendOrigin = backend.replace(path: '', query: '', fragment: '');
      return backendOrigin.resolveUri(uri);
    }

    if (Uri.base.scheme == 'https' && uri.scheme == 'http') {
      return uri.replace(scheme: 'https');
    }

    return uri;
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final controller = VideoPlayerController.networkUrl(
        _resolveVideoUri(widget.url),
      );
      _videoController = controller;
      await controller.initialize();
      if (!mounted) return;

      _chewieController = ChewieController(
        videoPlayerController: controller,
        autoPlay: widget.autoPlay,
        looping: widget.looping,
        aspectRatio: _safeAspectRatio(controller.value.aspectRatio),
        allowFullScreen: widget.allowFullScreen,
        allowPlaybackSpeedChanging: widget.allowPlaybackSpeedChanging,
        showControlsOnInitialize: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFFE50914),
          handleColor: const Color(0xFFE50914),
          bufferedColor: Colors.white24,
          backgroundColor: Colors.white10,
        ),
        errorBuilder: (context, message) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ),
      );

      setState(() {});
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  double _safeAspectRatio(double aspectRatio) {
    if (aspectRatio.isNaN || aspectRatio.isInfinite || aspectRatio <= 0) {
      return 16 / 9;
    }
    return aspectRatio;
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }

    final chewie = _chewieController;
    if (chewie == null || _videoController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE50914)),
      );
    }

    return ClipRect(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox.expand(
          child: Chewie(controller: chewie),
        ),
      ),
    );
  }
}
