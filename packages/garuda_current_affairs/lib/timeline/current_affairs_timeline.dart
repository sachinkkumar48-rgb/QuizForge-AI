library;

import '../domain/entities/current_affairs_enums.dart';
import '../domain/entities/current_affairs_knowledge_object.dart';

class TimelineBucket {
  final String label;
  final DateTime startDate;
  final DateTime endDate;
  final List<CurrentAffairsKnowledgeObject> items;

  const TimelineBucket({
    required this.label,
    required this.startDate,
    required this.endDate,
    required this.items,
  });
}

class CurrentAffairsTimeline {
  static List<TimelineBucket> generateTimeline({
    required List<CurrentAffairsKnowledgeObject> objects,
    required DigestFrequency frequency,
    CurrentAffairsCategory? categoryFilter,
    String? topicFilter,
  }) {
    var filtered = objects;
    if (categoryFilter != null) {
      filtered = filtered.where((o) => o.category == categoryFilter).toList();
    }
    if (topicFilter != null && topicFilter.isNotEmpty) {
      filtered = filtered
          .where((o) =>
              o.subcategory.toLowerCase().contains(topicFilter.toLowerCase()) ||
              o.headline.toLowerCase().contains(topicFilter.toLowerCase()))
          .toList();
    }

    filtered.sort((a, b) => b.publicationDate.compareTo(a.publicationDate));

    final Map<String, List<CurrentAffairsKnowledgeObject>> grouped = {};

    for (final obj in filtered) {
      final date = obj.publicationDate;
      String key;
      switch (frequency) {
        case DigestFrequency.daily:
          key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          break;
        case DigestFrequency.weekly:
          final weekOfYear = ((date.dayOfYear - 1) ~/ 7) + 1;
          key = '${date.year}-W${weekOfYear.toString().padLeft(2, '0')}';
          break;
        case DigestFrequency.monthly:
          key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
          break;
        case DigestFrequency.yearly:
          key = '${date.year}';
          break;
        case DigestFrequency.themeWise:
          key = obj.category.displayName;
          break;
        case DigestFrequency.topicWise:
          key = obj.subcategory.isNotEmpty ? obj.subcategory : obj.category.displayName;
          break;
      }

      grouped.putIfAbsent(key, () => []).add(obj);
    }

    return grouped.entries.map((entry) {
      final items = entry.value;
      final startDate = items.last.publicationDate;
      final endDate = items.first.publicationDate;
      return TimelineBucket(
        label: entry.key,
        startDate: startDate,
        endDate: endDate,
        items: items,
      );
    }).toList();
  }
}

extension _DateTimeExtensions on DateTime {
  int get dayOfYear {
    final firstDayOfYear = DateTime(year, 1, 1);
    return difference(firstDayOfYear).inDays + 1;
  }
}
