import 'package:flutter/widgets.dart';

import 'app_network_image_impl_stub.dart'
    if (dart.library.js_interop) 'app_network_image_impl_web.dart'
    if (dart.library.html) 'app_network_image_impl_web.dart';

abstract class AppNetworkImageImpl extends Widget {
  const factory AppNetworkImageImpl({
    required String url,
    required BoxFit fit,
    double? width,
    double? height,
    Widget? placeholder,
    Widget? errorWidget,
  }) = AppNetworkImageImplFactory;
}
