import 'package:flutter/material.dart';
import '../../shared/extensions/responsive_extensions.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (context.isDesktop) {
      return desktop;
    } else if (context.isTablet) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }
}
