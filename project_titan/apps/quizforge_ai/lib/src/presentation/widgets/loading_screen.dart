import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import 'progress_indicator.dart';

/// Full screen loading view with semantically accessible feedback.
class LoadingScreen extends StatelessWidget {
  final String message;

  const LoadingScreen({
    super.key,
    this.message = 'Loading, please wait...',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: AppProgressIndicator(
            label: message,
          ),
        ),
      ),
    );
  }
}
