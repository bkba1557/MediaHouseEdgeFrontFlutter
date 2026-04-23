import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _splashVideoAsset = 'assets/videos/splash.mp4';
  static const _endTolerance = Duration(milliseconds: 120);

  VideoPlayerController? _controller;
  late final Future<void> _authLoadFuture;
  bool _navigated = false;
  bool _videoFailed = false;
  bool _showEnableAudio = false;
  bool _audioEnabled = false;

  @override
  void initState() {
    super.initState();
    _authLoadFuture = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).loadAuthData();
    if (kIsWeb) {
      _initVideo();
    } else {
      _goNext();
    }
  }

  Future<void> _initVideo() async {
    try {
      final controller = VideoPlayerController.asset(_splashVideoAsset);
      _controller = controller;

      await controller.initialize();
      if (!mounted) return;

      await controller.setLooping(false);
      controller.addListener(_handleVideoTick);

      try {
        await controller.setVolume(1);
        await controller.play();
        _audioEnabled = true;
      } catch (_) {
        // Autoplay with audio is often blocked on the web.
        _showEnableAudio = true;
        _audioEnabled = false;
        try {
          await controller.setVolume(0);
          await controller.play();
        } catch (_) {
          // If even muted autoplay is blocked, we'll wait for a user tap.
        }
      }

      setState(() {});
    } catch (_) {
      if (!mounted) return;
      setState(() => _videoFailed = true);
      _goNext();
    }
  }

  void _handleVideoTick() {
    final controller = _controller;
    if (controller == null || _navigated || !mounted) return;

    final value = controller.value;
    if (value.hasError) {
      _goNext();
      return;
    }

    if (!value.isInitialized || value.duration == Duration.zero) return;

    final atEnd = value.position + _endTolerance >= value.duration;
    if (atEnd && !value.isPlaying) {
      _goNext();
    }
  }

  Future<void> _goNext() async {
    if (_navigated || !mounted) return;
    _navigated = true;

    await _authLoadFuture;

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  void dispose() {
    final controller = _controller;
    if (controller != null) {
      controller.removeListener(_handleVideoTick);
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      body: ColoredBox(
        color: Colors.black,
        child: _videoFailed
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFE50914)),
              )
            : controller != null && controller.value.isInitialized
            ? Stack(
                fit: StackFit.expand,
                children: [
                  SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: controller.value.size.width,
                        height: controller.value.size.height,
                        child: VideoPlayer(controller),
                      ),
                    ),
                  ),
                  if (_showEnableAudio)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 24,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FilledButton.icon(
                            onPressed: () async {
                              try {
                                await controller.setVolume(1);
                                _audioEnabled = true;
                                _showEnableAudio = false;
                                if (!controller.value.isPlaying) {
                                  await controller.play();
                                }
                                if (mounted) setState(() {});
                              } catch (_) {}
                            },
                            icon: Icon(
                              _audioEnabled
                                  ? Icons.volume_up
                                  : Icons.volume_off,
                            ),
                            label: const Text('تفعيل الصوت'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: _goNext,
                            child: const Text('تخطي'),
                          ),
                        ],
                      ),
                    ),
                ],
              )
            : const Center(
                child: CircularProgressIndicator(color: Color(0xFFE50914)),
              ),
      ),
    );
  }
}
