import 'package:flutter/material.dart';

class OfflineBanner extends StatelessWidget {
  final bool isOffline;

  const OfflineBanner({
    super.key,
    required this.isOffline,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOffline) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      color: Colors.amber.shade800,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.wifi_off,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Text(
            'Offline Mode • Working from local cache',
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
