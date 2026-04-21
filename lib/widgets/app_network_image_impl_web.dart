import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';

import 'app_network_image_impl.dart';

class AppNetworkImageImplFactory extends StatelessWidget
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

  static int _id = 0;
  static final Map<String, String> _viewTypes = {};

  static String? _altFirebaseBucketUrl(String url) {
    if (url.contains('.firebasestorage.app')) {
      return url.replaceAll('.firebasestorage.app', '.appspot.com');
    }
    if (url.contains('.appspot.com')) {
      return url.replaceAll('.appspot.com', '.firebasestorage.app');
    }
    return null;
  }

  String _resolveViewType() {
    final key = '$url|$fit';
    final existing = _viewTypes[key];
    if (existing != null) return existing;

    final viewType = 'app-network-image-${_id++}';
    _viewTypes[key] = viewType;

    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final container = html.DivElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.overflow = 'hidden';

      final img = html.ImageElement()
        ..src = url
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = _cssObjectFit(fit)
        ..style.display = 'block'
        ..style.opacity = '0'
        ..style.visibility = 'hidden'
        ..style.transition = 'opacity 160ms ease';

      var triedAlt = false;
      img.onLoad.listen((_) {
        img.style.opacity = '1';
        img.style.visibility = 'visible';
      });
      img.onError.listen((_) {
        if (!triedAlt) {
          final alt = _altFirebaseBucketUrl(img.src ?? url);
          if (alt != null && alt != img.src) {
            triedAlt = true;
            img.src = alt;
            return;
          }
        }
        // Keep the element hidden so the Flutter placeholder behind remains visible.
        img.style.opacity = '0';
        img.style.visibility = 'hidden';
        img.style.display = 'none';
      });

      container.append(img);
      return container;
    });

    return viewType;
  }

  static String _cssObjectFit(BoxFit fit) {
    switch (fit) {
      case BoxFit.contain:
        return 'contain';
      case BoxFit.fill:
        return 'fill';
      case BoxFit.none:
        return 'none';
      case BoxFit.scaleDown:
        return 'scale-down';
      case BoxFit.cover:
      case BoxFit.fitHeight:
      case BoxFit.fitWidth:
        return 'cover';
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewType = _resolveViewType();
    final image = HtmlElementView(viewType: viewType);

    final constrained = (width != null || height != null)
        ? SizedBox(width: width, height: height, child: image)
        : image;

    if (placeholder == null && errorWidget == null) return constrained;

    // We can't reliably detect load progress/errors from HtmlElementView,
    // so we keep the placeholder behind it as a graceful fallback.
    return Stack(
      fit: StackFit.expand,
      children: [
        if (placeholder != null) placeholder!,
        constrained,
      ],
    );
  }
}
