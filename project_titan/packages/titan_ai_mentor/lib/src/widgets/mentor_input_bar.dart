import 'package:flutter/material.dart';

import 'mentor_suggestion_card.dart';

/// Material 3 Input bar with suggestion chips for entering prompts.
class MentorInputBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSend;
  final List<String> suggestions;
  final bool isSending;

  const MentorInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.suggestions = const [
      'Explain Fundamental Rights',
      'Generate Study Plan',
      'Suggest Today\'s Revision',
    ],
    this.isSending = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (suggestions.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            child: Row(
              children: suggestions.map((s) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: MentorSuggestionCard(
                    label: s,
                    onTap: () {
                      controller.text = s;
                      onSend(s);
                      controller.clear();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Ask TITAN Mentor anything...',
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHigh,
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              IconButton.filled(
                onPressed: isSending
                    ? null
                    : () {
                        final text = controller.text.trim();
                        if (text.isNotEmpty) {
                          onSend(text);
                          controller.clear();
                        }
                      },
                icon: const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
