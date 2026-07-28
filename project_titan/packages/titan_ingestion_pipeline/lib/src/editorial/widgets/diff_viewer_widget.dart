import 'package:flutter/material.dart';

/// Reusable Material 3 Diff Viewer displaying side-by-side & line-level comparisons.
class DiffViewerWidget extends StatefulWidget {
  final String originalText;
  final String revisedText;
  final String originalLabel;
  final String revisedLabel;

  const DiffViewerWidget({
    super.key,
    required this.originalText,
    required this.revisedText,
    this.originalLabel = 'Original AI Draft',
    this.revisedLabel = 'Editor Revision',
  });

  @override
  State<DiffViewerWidget> createState() => _DiffViewerWidgetState();
}

class _DiffViewerWidgetState extends State<DiffViewerWidget> {
  bool _isSideBySide = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final originalLines = widget.originalText.split('\n');
    final revisedLines = widget.revisedText.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Difference Viewer',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment<bool>(
                  value: true,
                  label: Text('Side-by-Side'),
                  icon: Icon(Icons.view_column),
                ),
                ButtonSegment<bool>(
                  value: false,
                  label: Text('Inline Diff'),
                  icon: Icon(Icons.format_line_spacing),
                ),
              ],
              selected: {_isSideBySide},
              onSelectionChanged: (Set<bool> newSelection) {
                setState(() {
                  _isSideBySide = newSelection.first;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        _isSideBySide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Original Side
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.history,
                                  size: 16, color: Colors.red),
                              const SizedBox(width: 6),
                              Text(
                                widget.originalLabel,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          ...originalLines.map((line) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2.0),
                                child: Text(
                                  line.isEmpty ? ' ' : line,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Revised Side
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.edit_note,
                                  size: 16, color: Colors.green),
                              const SizedBox(width: 6),
                              Text(
                                widget.revisedLabel,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          ...revisedLines.map((line) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2.0),
                                child: Text(
                                  line.isEmpty ? ' ' : line,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...originalLines
                        .where((line) => !revisedLines.contains(line))
                        .map((line) => Container(
                              width: double.infinity,
                              color: Colors.red.withValues(alpha: 0.15),
                              padding: const EdgeInsets.all(4),
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              child: Text('- $line',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontFamily: 'monospace',
                                  )),
                            )),
                    ...revisedLines
                        .where((line) => !originalLines.contains(line))
                        .map((line) => Container(
                              width: double.infinity,
                              color: Colors.green.withValues(alpha: 0.15),
                              padding: const EdgeInsets.all(4),
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              child: Text('+ $line',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontFamily: 'monospace',
                                  )),
                            )),
                    ...revisedLines
                        .where((line) => originalLines.contains(line))
                        .map((line) => Padding(
                              padding: const EdgeInsets.all(4),
                              child: Text('  $line',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                  )),
                            )),
                  ],
                ),
              ),
      ],
    );
  }
}
