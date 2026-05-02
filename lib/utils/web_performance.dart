import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

bool isHandheldWeb(BuildContext context, {double maxShortestSide = 700}) {
  if (!kIsWeb) return false;

  final size = MediaQuery.maybeSizeOf(context);
  if (size == null) return false;

  final shortestSide = size.width < size.height ? size.width : size.height;
  return shortestSide < maxShortestSide;
}
