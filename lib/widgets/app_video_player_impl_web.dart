// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';

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
  static int _nextId = 0;

  late String _viewType;
  late List<String> _candidates;

  @override
  void initState() {
    super.initState();
    _candidates = _buildUrlCandidates(widget.url);
    _viewType = 'app-video-player-${_nextId++}';
    _registerViewFactory();
  }

  @override
  void didUpdateWidget(covariant AppVideoPlayerImplFactory oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url ||
        oldWidget.autoPlay != widget.autoPlay ||
        oldWidget.looping != widget.looping) {
      _candidates = _buildUrlCandidates(widget.url);
      _viewType = 'app-video-player-${_nextId++}';
      _registerViewFactory();
    }
  }

  static String _backendOrigin() {
    final uri = Uri.parse(AppConfig.apiBaseUrl);
    return uri.replace(path: '', query: '', fragment: '').toString();
  }

  static String _sanitizeUrl(String url) {
    var value = url.trim();
    if (value.isEmpty) return value;
    if (value.contains(' ')) value = value.replaceAll(' ', '%20');
    if (value.startsWith('//')) return '${Uri.base.scheme}:$value';
    return value;
  }

  static List<String> _buildUrlCandidates(Uri uri) {
    final original = _sanitizeUrl(uri.toString());
    final candidates = <String>[];

    void add(String value) {
      final trimmed = _sanitizeUrl(value);
      if (trimmed.isEmpty) return;
      if (!candidates.contains(trimmed)) candidates.add(trimmed);
    }

    if (original.isEmpty) return candidates;

    if (!original.contains('://') &&
        !original.startsWith('data:') &&
        !original.startsWith('blob:')) {
      final frontendOrigin = Uri.base.origin;
      final backendOrigin = _backendOrigin();
      if (original.startsWith('/')) {
        add('$backendOrigin$original');
        add('$frontendOrigin$original');
      } else {
        add('$backendOrigin/$original');
        add('$frontendOrigin/$original');
      }
      return candidates;
    }

    final preferred =
        (Uri.base.scheme == 'https' && original.startsWith('http://'))
        ? original.replaceFirst('http://', 'https://')
        : original;

    add(preferred);
    add(original);
    return candidates;
  }

  void _registerViewFactory() {
    final candidates = List<String>.from(_candidates);
    final autoPlay = widget.autoPlay;
    final looping = widget.looping;

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final container = html.DivElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.minWidth = '100%'
        ..style.minHeight = '100%'
        ..style.maxWidth = '100%'
        ..style.maxHeight = '100%'
        ..style.position = 'relative'
        ..style.overflow = 'hidden'
        ..style.direction = 'ltr'
        ..style.boxSizing = 'border-box'
        ..style.backgroundColor = 'black'
        ..style.display = 'block';

      final video = html.VideoElement()
        ..controls = true
        ..autoplay = autoPlay
        ..loop = looping
        ..preload = 'auto'
        ..style.position = 'absolute'
        ..style.left = '0'
        ..style.top = '0'
        ..style.right = '0'
        ..style.bottom = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.minWidth = '100%'
        ..style.minHeight = '100%'
        ..style.maxWidth = '100%'
        ..style.maxHeight = '100%'
        ..style.objectFit = 'contain'
        ..style.objectPosition = 'center center'
        ..style.display = 'block'
        ..style.boxSizing = 'border-box'
        ..style.margin = '0'
        ..style.padding = '0'
        ..style.backgroundColor = 'black';

      video.setAttribute('playsinline', 'true');

      var candidateIndex = 0;
      void loadCandidate() {
        if (candidateIndex >= candidates.length) return;
        video.src = candidates[candidateIndex];
        video.load();
      }

      video.onError.listen((_) {
        candidateIndex += 1;
        loadCandidate();
      });

      loadCandidate();
      container.append(video);
      return container;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox.expand(
          child: HtmlElementView(viewType: _viewType),
        ),
      ),
    );
  }
}
