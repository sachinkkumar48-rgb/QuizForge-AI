library;

import '../domain/entities/current_affairs_enums.dart';
import '../domain/entities/current_affairs_knowledge_object.dart';

class TrendAnalysis {
  final CurrentAffairsCategory topCategory;
  final double topCategoryPercentage;
  final List<String> emergingKeywords;
  final Map<CurrentAffairsCategory, double> weightDistribution;

  const TrendAnalysis({
    required this.topCategory,
    required this.topCategoryPercentage,
    required this.emergingKeywords,
    required this.weightDistribution,
  });
}

class CurrentAffairsTrendEngine {
  static TrendAnalysis analyzeTrends(List<CurrentAffairsKnowledgeObject> objects) {
    if (objects.isEmpty) {
      return const TrendAnalysis(
        topCategory: CurrentAffairsCategory.miscellaneous,
        topCategoryPercentage: 0.0,
        emergingKeywords: [],
        weightDistribution: {},
      );
    }

    final catCounts = <CurrentAffairsCategory, int>{};
    final kwCounts = <String, int>{};

    for (final obj in objects) {
      catCounts[obj.category] = (catCounts[obj.category] ?? 0) + 1;
      for (final kw in obj.keywords) {
        final lower = kw.toLowerCase().trim();
        if (lower.isNotEmpty) {
          kwCounts[lower] = (kwCounts[lower] ?? 0) + 1;
        }
      }
    }

    var topCat = CurrentAffairsCategory.miscellaneous;
    var maxCatCount = 0;

    catCounts.forEach((cat, count) {
      if (count > maxCatCount) {
        maxCatCount = count;
        topCat = cat;
      }
    });

    final total = objects.length;
    final topPct = (maxCatCount / total) * 100.0;

    final weightDist = <CurrentAffairsCategory, double>{};
    catCounts.forEach((cat, count) {
      weightDist[cat] = double.parse(((count / total) * 100.0).toStringAsFixed(1));
    });

    final sortedKeywords = kwCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final emerging = sortedKeywords.take(10).map((e) => e.key).toList();

    return TrendAnalysis(
      topCategory: topCat,
      topCategoryPercentage: double.parse(topPct.toStringAsFixed(1)),
      emergingKeywords: emerging,
      weightDistribution: Map.unmodifiable(weightDist),
    );
  }
}
