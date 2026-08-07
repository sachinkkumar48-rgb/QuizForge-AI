import 'package:flutter/material.dart';
import 'mentor_hint_card.dart';

class QuizCard extends StatefulWidget {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String? hint;

  const QuizCard({
    super.key,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.hint,
  });

  @override
  State<QuizCard> createState() => _QuizCardState();
}

class _QuizCardState extends State<QuizCard> {
  int? _selectedIndex;
  bool _isAnswerRevealed = false;
  bool _showHint = false;

  void _selectOption(int index) {
    if (!_isAnswerRevealed) {
      setState(() {
        _selectedIndex = index;
        if (index != widget.correctIndex && widget.hint != null) {
          _showHint = true;
        } else if (index == widget.correctIndex) {
          _showHint = false;
        }
      });
    }
  }

  void _toggleRevealAnswer() {
    setState(() {
      _isAnswerRevealed = !_isAnswerRevealed;
    });
  }

  void _resetSelection() {
    setState(() {
      _selectedIndex = null;
      _showHint = false;
      _isAnswerRevealed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isWrong = _selectedIndex != null && _selectedIndex != widget.correctIndex;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.quiz_rounded,
                  color: theme.colorScheme.primary,
                  size: 24.0,
                ),
                const SizedBox(width: 8.0),
                Text(
                  'Knowledge Check',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const Divider(height: 24.0),
            Text(
              widget.question,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16.0),
            ...List.generate(widget.options.length, (index) {
              final optionText = widget.options[index];
              final isSelected = _selectedIndex == index;
              final isCorrect = index == widget.correctIndex;

              Color borderColor = theme.colorScheme.outlineVariant;
              Color backgroundColor = theme.colorScheme.surface;

              if (_isAnswerRevealed) {
                if (isCorrect) {
                  borderColor = Colors.green;
                  backgroundColor = Colors.green.withAlpha(30);
                } else if (isSelected && !isCorrect) {
                  borderColor = theme.colorScheme.error;
                  backgroundColor = theme.colorScheme.errorContainer.withAlpha(60);
                }
              } else if (isSelected) {
                if (isCorrect) {
                  borderColor = Colors.green;
                  backgroundColor = Colors.green.withAlpha(30);
                } else {
                  borderColor = theme.colorScheme.error;
                  backgroundColor = theme.colorScheme.errorContainer.withAlpha(50);
                }
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 10.0),
                child: Material(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12.0),
                  child: InkWell(
                    onTap: () => _selectOption(index),
                    borderRadius: BorderRadius.circular(12.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: borderColor, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? (isCorrect ? Colors.green : theme.colorScheme.error)
                                  : theme.colorScheme.surfaceContainerHighest,
                            ),
                            child: Center(
                              child: Text(
                                String.fromCharCode(65 + index),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: Text(
                              optionText,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if ((_isAnswerRevealed || isSelected) && isCorrect)
                            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20.0),
                          if ((_isAnswerRevealed || isSelected) && isSelected && !isCorrect)
                            Icon(Icons.cancel_rounded, color: theme.colorScheme.error, size: 20.0),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            if (isWrong && widget.hint != null && _showHint) ...[
              const SizedBox(height: 10.0),
              MentorHintCard(hint: widget.hint!),
            ],
            const SizedBox(height: 12.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isWrong && !_isAnswerRevealed) ...[
                  OutlinedButton.icon(
                    onPressed: _resetSelection,
                    icon: const Icon(Icons.refresh_rounded, size: 18.0),
                    label: const Text('Try Again'),
                  ),
                  const SizedBox(width: 12.0),
                ],
                OutlinedButton.icon(
                  onPressed: _toggleRevealAnswer,
                  icon: Icon(
                    _isAnswerRevealed ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    size: 18.0,
                  ),
                  label: Text(_isAnswerRevealed ? 'Hide Explanation' : 'Reveal Answer'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
              ],
            ),
            if (_isAnswerRevealed) ...[
              const SizedBox(height: 16.0),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withAlpha(100),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: theme.colorScheme.primary.withAlpha(60)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Explanation',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    Text(
                      widget.explanation,
                      style: theme.textTheme.bodySmall?.copyWith(
                        height: 1.4,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
