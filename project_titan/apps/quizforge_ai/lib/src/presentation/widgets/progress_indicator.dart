import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// Reusable adaptive progress indicator with semantics support.
class AppProgressIndicator extends StatelessWidget {
  final double? value;
  final String? label;
  final bool isLinear;

  const AppProgressIndicator({
    super.key,
    this.value,
    this.label,
    this.isLinear = false,
  });

  @override
  Widget build(BuildContext context) {
    final semanticLabel = label ??
        (value != null ? '${(value! * 100).toInt()}% progress' : 'Loading');

    return Semantics(
      label: semanticLabel,
      value: value != null ? '${(value! * 100).toInt()}%' : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLinear)
            LinearProgressIndicator(value: value)
          else
            CircularProgressIndicator(value: value),
          if (label != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              label!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
