import 'package:flutter/material.dart';
import '../models/assessment_models.dart';

/// Responsive Material 3 chart visualizing difficulty ratio distribution.
class DifficultyDistributionChart extends StatelessWidget {
  final DifficultyProfile profile;

  const DifficultyDistributionChart({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Difficulty Distribution (${profile.targetDifficultyLevel})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  Expanded(
                    flex: (profile.easyRatio * 100).toInt(),
                    child: Container(
                      height: 24,
                      color: Colors.green,
                      child: const Center(
                        child: Text('Easy',
                            style:
                                TextStyle(color: Colors.white, fontSize: 10)),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: (profile.mediumRatio * 100).toInt(),
                    child: Container(
                      height: 24,
                      color: Colors.orange,
                      child: const Center(
                        child: Text('Medium',
                            style:
                                TextStyle(color: Colors.white, fontSize: 10)),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: (profile.hardRatio * 100).toInt(),
                    child: Container(
                      height: 24,
                      color: Colors.red,
                      child: const Center(
                        child: Text('Hard',
                            style:
                                TextStyle(color: Colors.white, fontSize: 10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
