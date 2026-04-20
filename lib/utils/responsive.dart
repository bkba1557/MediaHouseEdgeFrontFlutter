import 'package:flutter/material.dart';

/// Utility class to help build responsive layouts.
class Responsive {
  /// Returns true if the device width is considered mobile.
  static bool isMobile(BuildContext ctx) => MediaQuery.of(ctx).size.width < 600;

  /// Returns true if the device width is considered tablet.
  static bool isTablet(BuildContext ctx) =>
      MediaQuery.of(ctx).size.width >= 600 && MediaQuery.of(ctx).size.width < 1024;

  /// Returns true if the device width is considered desktop.
  static bool isDesktop(BuildContext ctx) => MediaQuery.of(ctx).size.width >= 1024;

  /// Scale a size based on the screen width (base width 375).
  static double scale(BuildContext ctx, double size) {
    final width = MediaQuery.of(ctx).size.width;
    final factor = width / 375.0;
    return size * factor.clamp(1.0, 2.5);
  }
}
