import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// Builder widget handling Mobile, Tablet, Desktop, and Web responsive layouts.
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  /// Helper to check if current view is mobile width.
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < AppSpacing.mobileMax;

  /// Helper to check if current view is tablet width.
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= AppSpacing.mobileMax && width <= AppSpacing.tabletMax;
  }

  /// Helper to check if current view is desktop width.
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= AppSpacing.desktopMin;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppSpacing.desktopMin && desktop != null) {
          return desktop!;
        }
        if (constraints.maxWidth >= AppSpacing.mobileMax && tablet != null) {
          return tablet!;
        }
        return mobile;
      },
    );
  }
}
