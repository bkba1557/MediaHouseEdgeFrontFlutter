import 'package:cached_network_image/cached_network_image.dart';
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

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: width,
      height: height,
      placeholder: (_, __) => placeholder ?? const SizedBox.shrink(),
      errorWidget: (_, __, ___) => errorWidget ?? const SizedBox.shrink(),
    );
  }
}
