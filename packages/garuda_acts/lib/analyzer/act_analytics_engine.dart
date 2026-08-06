library;

import '../repositories/act_repository.dart';

/// Analytics Metrics summary report for GARUDA Central Acts Library.
class ActAnalyticsReport {
  final int totalActsCovered;
  final int totalSectionsCovered;
  final int totalRulesCovered;
  final int totalNotificationsCovered;
  final int totalRelationshipsCount;
  final int totalChaptersCovered;
  final int totalSchedulesCovered;
  final double coveragePercentage;

  const ActAnalyticsReport({
    required this.totalActsCovered,
    required this.totalSectionsCovered,
    required this.totalRulesCovered,
    required this.totalNotificationsCovered,
    required this.totalRelationshipsCount,
    required this.totalChaptersCovered,
    required this.totalSchedulesCovered,
    required this.coveragePercentage,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalActsCovered': totalActsCovered,
      'totalSectionsCovered': totalSectionsCovered,
      'totalRulesCovered': totalRulesCovered,
      'totalNotificationsCovered': totalNotificationsCovered,
      'totalRelationshipsCount': totalRelationshipsCount,
      'totalChaptersCovered': totalChaptersCovered,
      'totalSchedulesCovered': totalSchedulesCovered,
      'coveragePercentage': coveragePercentage,
    };
  }
}

/// Analytics Engine calculating Central Acts coverage and relationship metrics.
class ActAnalyticsEngine {
  final ActRepository repository;

  ActAnalyticsEngine(this.repository);

  /// Generate analytics report for the current repository state.
  ActAnalyticsReport generateReport({int phase1TargetCount = 30}) {
    final acts = repository.getAllActs();

    int sectionsCount = 0;
    int rulesCount = 0;
    int notificationsCount = 0;
    int relationshipsCount = 0;
    int chaptersCount = 0;
    int schedulesCount = 0;

    for (final act in acts) {
      sectionsCount += act.sections.length;
      rulesCount += act.rules.length;
      notificationsCount += act.notifications.length;
      relationshipsCount += act.relationships.length;
      chaptersCount += act.chapters.length;
      schedulesCount += act.schedules.length;

      // Count section-embedded inter-domain links as relationships too
      for (final sec in act.sections) {
        relationshipsCount += sec.relatedArticles.length;
        relationshipsCount += sec.landmarkCases.length;
        relationshipsCount += sec.relatedDoctrines.length;
        relationshipsCount += sec.pyqIds.length;
        relationshipsCount += sec.currentAffairsIds.length;
      }
    }

    final coveragePct = (acts.length / phase1TargetCount) * 100.0;

    return ActAnalyticsReport(
      totalActsCovered: acts.length,
      totalSectionsCovered: sectionsCount,
      totalRulesCovered: rulesCount,
      totalNotificationsCovered: notificationsCount,
      totalRelationshipsCount: relationshipsCount,
      totalChaptersCovered: chaptersCount,
      totalSchedulesCovered: schedulesCount,
      coveragePercentage: coveragePct > 100.0 ? 100.0 : coveragePct,
    );
  }
}
