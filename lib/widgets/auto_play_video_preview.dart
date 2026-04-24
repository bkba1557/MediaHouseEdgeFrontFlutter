import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class AutoPlayVideoPreview extends StatefulWidget {
  final Uri url;
  final BoxFit fit;
  final bool looping;
  final Widget placeholder;
  final Widget? errorWidget;

  const AutoPlayVideoPreview({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.looping = true,
    this.placeholder = const ColoredBox(color: Colors.black),
    this.errorWidget,
  });

  @override
  State<AutoPlayVideoPreview> createState() => _AutoPlayVideoPreviewState();
}

class _AutoPlayVideoPreviewState extends State<AutoPlayVideoPreview> {
  VideoPlayerController? _controller;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant AutoPlayVideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.looping != widget.looping) {
      _disposeController();
      _init();
    }
  }

  Future<void> _init() async {
    try {
      final controller = VideoPlayerController.networkUrl(widget.url);
      _controller = controller;
      await controller.initialize();
      await controller.setLooping(widget.looping);
      await controller.setVolume(0);
      await controller.play();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() => _error = null);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    }
  }

  void _disposeController() {
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      controller.dispose();
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorWidget ?? widget.placeholder;
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return widget.placeholder;
    }

    final size = controller.value.size;
    final width = size.width > 0 ? size.width : 16.0;
    final height = size.height > 0 ? size.height : 9.0;

    return SizedBox.expand(
      child: ClipRect(
        child: FittedBox(
          fit: widget.fit,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: width,
            height: height,
            child: VideoPlayer(controller),
          ),
        ),
      ),
    );
  }
}
