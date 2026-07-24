import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import 'progress_indicator.dart';

/// Modal barrier loading overlay widget for async operations.
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Semantics(
            label: message ?? 'Loading content',
            child: Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: Card(
                  elevation: 6,
                  child: Padding(
                    padding: AppSpacing.paddingLg,
                    child: AppProgressIndicator(
                      label: message ?? 'Processing...',
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
