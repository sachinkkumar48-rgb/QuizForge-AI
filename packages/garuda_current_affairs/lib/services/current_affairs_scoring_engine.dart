library;

import '../domain/entities/current_affairs_enums.dart';
import '../domain/entities/current_affairs_knowledge_object.dart';
import '../domain/entities/news_event.dart';

/// UPSC Intelligence Scoring Engine computing relevance, prelims/mains weight, and interview applicability.
class CurrentAffairsScoringEngine {
  static UpscIntelligence calculateIntelligence({
    required NewsEvent event,
    required KnowledgeLinkSet links,
  }) {
    double score = 50.0;
    double prelimsWeight = 20.0;
    double mainsWeight = 25.0;
    double interviewRel = 30.0;

    // Importance boost
    switch (event.importance) {
      case CurrentAffairsImportance.critical:
        score += 35.0;
        prelimsWeight += 30.0;
        mainsWeight += 35.0;
        interviewRel += 40.0;
        break;
      case CurrentAffairsImportance.high:
        score += 25.0;
        prelimsWeight += 20.0;
        mainsWeight += 25.0;
        interviewRel += 25.0;
        break;
      case CurrentAffairsImportance.medium:
        score += 10.0;
        prelimsWeight += 10.0;
        mainsWeight += 10.0;
        interviewRel += 10.0;
        break;
      case CurrentAffairsImportance.low:
        score += 0.0;
        break;
    }

    // Knowledge Links boost
    if (!links.isEmpty) {
      score += (links.totalLinksCount * 5.0).clamp(5.0, 20.0);
      mainsWeight += (links.articleIds.length + links.caseLawIds.length) * 5.0;
      prelimsWeight += (links.actIds.length + links.schemeNames.length) * 5.0;
    }

    // Category specific adjustments
    if (event.category == CurrentAffairsCategory.polity ||
        event.category == CurrentAffairsCategory.economy ||
        event.category == CurrentAffairsCategory.environment) {
      score += 10.0;
      prelimsWeight += 15.0;
      mainsWeight += 15.0;
    }

    final finalScore = score.clamp(10.0, 100.0);
    final finalPrelims = prelimsWeight.clamp(5.0, 95.0);
    final finalMains = mainsWeight.clamp(5.0, 95.0);
    final finalInterview = interviewRel.clamp(5.0, 95.0);

    final staticTopics = <String>[];
    if (event.category == CurrentAffairsCategory.polity) staticTopics.add('Indian Polity & Governance');
    if (event.category == CurrentAffairsCategory.economy) staticTopics.add('Indian Economy & Development');
    if (event.category == CurrentAffairsCategory.environment) staticTopics.add('Environmental Ecology & Climate Change');
    if (event.category == CurrentAffairsCategory.scienceAndTechnology) staticTopics.add('Science & Technology Developments');

    final revisionAreas = <String>[];
    if (links.articleIds.isNotEmpty) revisionAreas.add('Constitutional Provisions (${links.articleIds.join(", ")})');
    if (links.actIds.isNotEmpty) revisionAreas.add('Statutory Acts (${links.actIds.join(", ")})');
    if (links.caseLawIds.isNotEmpty) revisionAreas.add('Landmark Judgments (${links.caseLawIds.join(", ")})');

    return UpscIntelligence(
      relevanceScore: double.parse(finalScore.toStringAsFixed(1)),
      prelimsWeight: double.parse(finalPrelims.toStringAsFixed(1)),
      mainsWeight: double.parse(finalMains.toStringAsFixed(1)),
      interviewRelevance: double.parse(finalInterview.toStringAsFixed(1)),
      relatedPyqIds: links.pyqIds,
      relatedStaticTopics: staticTopics,
      likelyRevisionAreas: revisionAreas,
    );
  }
}
