import 'package:flutter/material.dart';
import '../models/editorial_models.dart';

/// Reusable Material 3 Quality Validation Checklist & Score Breakdown Widget.
class QualityValidationWidget extends StatelessWidget {
  final QualityValidationChecklist checklist;
  final EditorialQualityScore score;
  final ValueChanged<QualityValidationChecklist>? onChecklistChanged;

  const QualityValidationWidget({
    super.key,
    required this.checklist,
    required this.score,
    this.onChecklistChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Knowledge & Editorial Quality Evaluation',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Score Breakdown Cards
          Row(
            children: [
              Expanded(
                child: _buildScoreMeter(context, 'Knowledge Quality',
                    score.knowledgeQuality, Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildScoreMeter(context, 'Editorial Quality',
                    score.editorialQuality, Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildScoreMeter(
                    context, 'Completeness', score.completeness, Colors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildScoreMeter(
                    context, 'Readability', score.readability, Colors.purple),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildScoreMeter(
                    context, 'Consistency', score.consistency, Colors.teal),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Card(
            color: colorScheme.primaryContainer.withValues(alpha: 0.2),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    score.overallScore >= 80.0
                        ? Icons.verified
                        : Icons.warning_amber,
                    color: score.overallScore >= 80.0
                        ? Colors.green
                        : Colors.orange,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overall Quality Score',
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: colorScheme.outline),
                      ),
                      Text(
                        '${score.overallScore.toStringAsFixed(1)}%',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Chip(
                    label: Text(
                      '${checklist.validatedCount}/9 Validated',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: checklist.isFullyValidated
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.orange.withValues(alpha: 0.2),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Quality Validation Checklist (9 Criteria)',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          _buildCheckboxTile(
            context,
            title: '1. Accuracy',
            subtitle: 'Factual correctness and domain alignment',
            value: checklist.accuracyValidated,
            onChanged: (val) => onChecklistChanged
                ?.call(checklist.copyWith(accuracyValidated: val)),
          ),
          _buildCheckboxTile(
            context,
            title: '2. Completeness',
            subtitle: 'Comprehensive coverage without missing key concepts',
            value: checklist.completenessValidated,
            onChanged: (val) => onChecklistChanged
                ?.call(checklist.copyWith(completenessValidated: val)),
          ),
          _buildCheckboxTile(
            context,
            title: '3. Grammar & Language',
            subtitle: 'Correct spelling, punctuation, and terminology',
            value: checklist.grammarValidated,
            onChanged: (val) => onChecklistChanged
                ?.call(checklist.copyWith(grammarValidated: val)),
          ),
          _buildCheckboxTile(
            context,
            title: '4. Formatting',
            subtitle: 'Clean Markdown syntax and typography',
            value: checklist.formattingValidated,
            onChanged: (val) => onChecklistChanged
                ?.call(checklist.copyWith(formattingValidated: val)),
          ),
          _buildCheckboxTile(
            context,
            title: '5. Metadata Accuracy',
            subtitle: 'Tags, Bloom levels, and study durations',
            value: checklist.metadataValidated,
            onChanged: (val) => onChecklistChanged
                ?.call(checklist.copyWith(metadataValidated: val)),
          ),
          _buildCheckboxTile(
            context,
            title: '6. References & Citations',
            subtitle: 'Source document provenance and links',
            value: checklist.referencesValidated,
            onChanged: (val) => onChecklistChanged
                ?.call(checklist.copyWith(referencesValidated: val)),
          ),
          _buildCheckboxTile(
            context,
            title: '7. Knowledge Graph Relationships',
            subtitle: 'Concept links and prerequisite connections',
            value: checklist.relationshipsValidated,
            onChanged: (val) => onChecklistChanged
                ?.call(checklist.copyWith(relationshipsValidated: val)),
          ),
          _buildCheckboxTile(
            context,
            title: '8. Learning Objectives Alignment',
            subtitle: 'Alignment with target curriculum outcomes',
            value: checklist.learningObjectivesValidated,
            onChanged: (val) => onChecklistChanged
                ?.call(checklist.copyWith(learningObjectivesValidated: val)),
          ),
          _buildCheckboxTile(
            context,
            title: '9. Difficulty Calibration',
            subtitle: 'Appropriate challenge level for target learners',
            value: checklist.difficultyValidated,
            onChanged: (val) => onChecklistChanged
                ?.call(checklist.copyWith(difficultyValidated: val)),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreMeter(
      BuildContext context, String label, double score, Color color) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.outline)),
          const SizedBox(height: 4),
          Text('${score.toStringAsFixed(1)}%',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color, fontSize: 16)),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: score / 100,
            color: color,
            backgroundColor: color.withValues(alpha: 0.15),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return CheckboxListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}
