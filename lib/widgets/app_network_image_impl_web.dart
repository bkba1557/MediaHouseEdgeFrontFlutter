import 'package:flutter/material.dart';

import 'app_network_image_impl.dart';

class AppNetworkImageImplFactory extends StatefulWidget
    implements AppNetworkImageImpl {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AppNetworkImageImplFactory({
    super.key,
    required this.url,
    required this.fit,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<AppNetworkImageImplFactory> createState() =>
      _AppNetworkImageImplFactoryState();
}

class _AppNetworkImageImplFactoryState
    extends State<AppNetworkImageImplFactory> {
  late String _currentUrl;
  bool _triedAlt = false;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.url;
  }

  @override
  void didUpdateWidget(covariant AppNetworkImageImplFactory oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _currentUrl = widget.url;
      _triedAlt = false;
    }
  }

  String? _altFirebaseBucketUrl(String url) {
    if (url.contains('.firebasestorage.app')) {
      return url.replaceAll('.firebasestorage.app', '.appspot.com');
    }
    if (url.contains('.appspot.com')) {
      return url.replaceAll('.appspot.com', '.firebasestorage.app');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final finiteWidth = widget.width?.isFinite == true ? widget.width : null;
    final finiteHeight = widget.height?.isFinite == true ? widget.height : null;

    return SizedBox(
      width: finiteWidth,
      height: finiteHeight,
      child: Image.network(
        _currentUrl,
        fit: widget.fit,
        width: finiteWidth,
        height: finiteHeight,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            return child;
          }
          return widget.placeholder ??
              const SizedBox.expand(
                child: ColoredBox(color: Colors.transparent),
              );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return widget.placeholder ??
              const SizedBox.expand(
                child: ColoredBox(color: Colors.transparent),
              );
        },
        errorBuilder: (context, error, stackTrace) {
          if (!_triedAlt) {
            final alt = _altFirebaseBucketUrl(_currentUrl);
            if (alt != null && alt != _currentUrl) {
              _triedAlt = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _currentUrl = alt;
                  });
                }
              });
              return widget.placeholder ??
                  const SizedBox.expand(
                    child: ColoredBox(color: Colors.transparent),
                  );
            }
          }

          return widget.errorWidget ??
              const SizedBox.expand(
                child: ColoredBox(color: Colors.transparent),
              );
        },
      ),
    );
  }
}
