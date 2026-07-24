import 'package:flutter/material.dart';

import '../models/recommendation_models.dart';
import 'recommendation_card.dart';
import 'recommendation_summary_card.dart';

/// Material 3 interactive list component displaying study recommendations
/// with summary header, priority filtering, and empty state support.
class RecommendationList extends StatefulWidget {
  final List<Recommendation> recommendations;
  final ValueChanged<Recommendation>? onRecommendationTap;
  final ValueChanged<Recommendation>? onActionPressed;
  final Future<void> Function()? onRefresh;
  final bool showSummaryCard;
  final String? initialPriorityFilter;

  const RecommendationList({
    super.key,
    required this.recommendations,
    this.onRecommendationTap,
    this.onActionPressed,
    this.onRefresh,
    this.showSummaryCard = true,
    this.initialPriorityFilter,
  });

  @override
  State<RecommendationList> createState() => _RecommendationListState();
}

class _RecommendationListState extends State<RecommendationList> {
  late String _selectedPriority;

  final List<String> _priorityFilters = const [
    'All',
    'Urgent',
    'High',
    'Medium',
    'Low',
  ];

  @override
  void initState() {
    super.initState();
    _selectedPriority = widget.initialPriorityFilter ?? 'All';
  }

  List<Recommendation> get _filteredRecommendations {
    if (_selectedPriority == 'All') return widget.recommendations;
    return widget.recommendations
        .where(
            (r) => r.priority.toLowerCase() == _selectedPriority.toLowerCase())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final filtered = _filteredRecommendations;

    Widget content = CustomScrollView(
      slivers: [
        if (widget.showSummaryCard)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: RecommendationSummaryCard(
                recommendations: widget.recommendations,
              ),
            ),
          ),

        // Priority Filter ChoiceChips Bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _priorityFilters.map((priority) {
                  final isSelected = _selectedPriority == priority;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(priority),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedPriority = priority;
                          });
                        }
                      },
                      selectedColor: colorScheme.primaryContainer,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),

        // Empty state or list items
        if (filtered.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 64.0,
                      color: colorScheme.primary.withAlpha(128),
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      'No Recommendations Found',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      _selectedPriority == 'All'
                          ? 'You are all caught up! Keep up the great study streak.'
                          : 'No recommendations for priority "$_selectedPriority".',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final rec = filtered[index];
                return RecommendationCard(
                  recommendation: rec,
                  onTap: widget.onRecommendationTap != null
                      ? () => widget.onRecommendationTap!(rec)
                      : null,
                  onActionPressed: widget.onActionPressed != null
                      ? () => widget.onActionPressed!(rec)
                      : null,
                );
              },
              childCount: filtered.length,
            ),
          ),
      ],
    );

    if (widget.onRefresh != null) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh!,
        child: content,
      );
    }

    return content;
  }
}
