import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../utils/web_performance.dart';

class AutoPlayVideoPreview extends StatefulWidget {
  final Uri url;
  final BoxFit fit;
  final bool looping;
  final Widget placeholder;
  final Widget? errorWidget;
  final double visibilityThreshold;

  const AutoPlayVideoPreview({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.looping = true,
    this.placeholder = const ColoredBox(color: Colors.black),
    this.errorWidget,
    this.visibilityThreshold = 0.35,
  });

  @override
  State<AutoPlayVideoPreview> createState() => _AutoPlayVideoPreviewState();
}

class _AutoPlayVideoPreviewState extends State<AutoPlayVideoPreview> {
  VideoPlayerController? _controller;
  Object? _error;
  bool _isVisible = false;
  bool _isInitializing = false;
  Timer? _visibilityDebounce;
  late final Key _visibilityKey = ValueKey(
    'auto-preview-${widget.url}#${identityHashCode(this)}',
  );

  @override
  void didUpdateWidget(covariant AutoPlayVideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.looping != widget.looping) {
      _disposeController();
      _error = null;
      _isInitializing = false;
      _syncPlayback();
    }
  }

  Future<void> _init() async {
    if (_isInitializing) return;

    try {
      _isInitializing = true;
      final controller = VideoPlayerController.networkUrl(widget.url);
      _controller = controller;
      await controller.initialize();
      await controller.setLooping(widget.looping);
      await controller.setVolume(0);

      if (!mounted) {
        controller.dispose();
        return;
      }

      if (_shouldPlay) {
        await controller.play();
      }

      if (!mounted) return;
      setState(() => _error = null);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      _isInitializing = false;
    }
  }

  bool get _shouldPlay => _isVisible;

  bool get _shouldDisposeWhenHidden => isHandheldWeb(context);

  void _syncPlayback() {
    if (!_shouldPlay) {
      final controller = _controller;
      if (controller == null) return;

      if (_shouldDisposeWhenHidden) {
        _disposeController();
      } else if (controller.value.isInitialized && controller.value.isPlaying) {
        unawaited(controller.pause());
      }
      return;
    }

    final controller = _controller;
    if (controller == null) {
      unawaited(_init());
      return;
    }

    if (controller.value.isInitialized && !controller.value.isPlaying) {
      unawaited(controller.play());
    }
  }

  void _handleVisibilityChange(VisibilityInfo info) {
    final nextVisible = info.visibleFraction >= widget.visibilityThreshold;
    if (nextVisible == _isVisible) return;

    _visibilityDebounce?.cancel();
    _visibilityDebounce = Timer(const Duration(milliseconds: 120), () {
      if (!mounted || nextVisible == _isVisible) return;
      _isVisible = nextVisible;
      _syncPlayback();
    });
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
    _visibilityDebounce?.cancel();
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (_error != null) {
      child = widget.errorWidget ?? widget.placeholder;
    } else {
      final controller = _controller;
      if (controller == null || !controller.value.isInitialized) {
        child = widget.placeholder;
      } else {
        final size = controller.value.size;
        final width = size.width > 0 ? size.width : 16.0;
        final height = size.height > 0 ? size.height : 9.0;

        child = SizedBox.expand(
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

    return VisibilityDetector(
      key: _visibilityKey,
      onVisibilityChanged: _handleVisibilityChange,
      child: child,
    );
  }
}
