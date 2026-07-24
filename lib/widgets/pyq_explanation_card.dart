import 'package:flutter/material.dart';
import '../models/explanation.dart';

class PyqExplanationCard extends StatefulWidget {
  final List<Explanation> explanations;
  final String? initialType;

  const PyqExplanationCard({
    super.key,
    required this.explanations,
    this.initialType,
  });

  @override
  State<PyqExplanationCard> createState() => _PyqExplanationCardState();
}

class _PyqExplanationCardState extends State<PyqExplanationCard> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = 0;
    if (widget.initialType != null && widget.explanations.isNotEmpty) {
      final idx = widget.explanations.indexWhere(
        (e) =>
            e.explanationType.toLowerCase() ==
            widget.initialType!.toLowerCase(),
      );
      if (idx >= 0) _selectedIndex = idx;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.explanations.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No explanation available for this question.'),
        ),
      );
    }

    final current = widget.explanations[_selectedIndex];
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Explanation Type Switcher / Segmented Tabs
            if (widget.explanations.length > 1) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(widget.explanations.length, (index) {
                    final exp = widget.explanations[index];
                    final isSelected = index == _selectedIndex;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(exp.explanationType),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedIndex = index);
                          }
                        },
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
            ],

            // Explanation Header (Source & Type Badge)
            Row(
              children: [
                _buildSourceIcon(current.explanationType, colorScheme),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        current.source.isNotEmpty
                            ? current.source
                            : current.explanationType,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Author: ${current.author}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    current.explanationType,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Main Content
            Text(
              current.content,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Metadata Footer (Source, Version, Language, Last Updated)
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _buildMetaItem(
                  Icons.source,
                  'Source: ${current.source.isNotEmpty ? current.source : "System"}',
                  colorScheme,
                ),
                _buildMetaItem(
                  Icons.numbers,
                  'Version: ${current.version}',
                  colorScheme,
                ),
                _buildMetaItem(
                  Icons.language,
                  'Lang: ${current.language}',
                  colorScheme,
                ),
                _buildMetaItem(
                  Icons.access_time,
                  'Updated: ${_formatDate(current.lastUpdated)}',
                  colorScheme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceIcon(String type, ColorScheme colorScheme) {
    IconData iconData = Icons.article;
    Color iconColor = colorScheme.primary;

    final t = type.toLowerCase();
    if (t.contains('official') || t.contains('upsc')) {
      iconData = Icons.verified;
      iconColor = Colors.green;
    } else if (t.contains('ai')) {
      iconData = Icons.auto_awesome;
      iconColor = Colors.purple;
    } else if (t.contains('editorial')) {
      iconData = Icons.edit_note;
      iconColor = Colors.blue;
    } else if (t.contains('community')) {
      iconData = Icons.people;
      iconColor = Colors.orange;
    } else if (t.contains('note')) {
      iconData = Icons.person_pin;
      iconColor = Colors.teal;
    }

    return Icon(iconData, color: iconColor, size: 22);
  }

  Widget _buildMetaItem(IconData icon, String text, ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: colorScheme.outline),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.outline,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
