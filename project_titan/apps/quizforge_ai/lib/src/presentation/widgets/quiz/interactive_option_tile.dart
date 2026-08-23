import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';

/// Accessible option tile with selection states and post-submission immediate feedback colors.
class InteractiveOptionTile extends StatelessWidget {
  final int optionIndex;
  final String optionText;
  final bool isSelected;
  final bool isEvaluated;
  final bool isCorrectOption;
  final bool isMultipleSelect;
  final VoidCallback? onTap;

  const InteractiveOptionTile({
    super.key,
    required this.optionIndex,
    required this.optionText,
    required this.isSelected,
    required this.isEvaluated,
    required this.isCorrectOption,
    this.isMultipleSelect = false,
    this.onTap,
  });

  String _getOptionLabel(int index) {
    const letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
    return index < letters.length ? letters[index] : '${index + 1}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color borderColor = colorScheme.outlineVariant;
    Color backgroundColor = colorScheme.surface;
    Widget? trailingIcon;

    if (isEvaluated) {
      if (isCorrectOption) {
        borderColor = Colors.green;
        backgroundColor = Colors.green.withValues(alpha: 0.12);
        trailingIcon = const Icon(Icons.check_circle,
            color: Colors.green, semanticLabel: 'Correct answer');
      } else if (isSelected) {
        borderColor = colorScheme.error;
        backgroundColor = colorScheme.error.withValues(alpha: 0.12);
        trailingIcon = Icon(Icons.cancel,
            color: colorScheme.error, semanticLabel: 'Incorrect selection');
      }
    } else if (isSelected) {
      borderColor = colorScheme.primary;
      backgroundColor = colorScheme.primary.withValues(alpha: 0.08);
    }

    final optionLabel = _getOptionLabel(optionIndex);

    return Semantics(
      label: 'Option $optionLabel: $optionText',
      selected: isSelected,
      button: !isEvaluated,
      child: InkWell(
        onTap: isEvaluated ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: borderColor,
                width: isSelected || (isEvaluated && isCorrectOption) ? 2 : 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest,
                ),
                child: Text(
                  optionLabel,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  optionText,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: AppSpacing.sm),
                trailingIcon,
              ] else if (isMultipleSelect) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                  color: isSelected ? colorScheme.primary : colorScheme.outline,
                ),
              ] else ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected ? colorScheme.primary : colorScheme.outline,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
