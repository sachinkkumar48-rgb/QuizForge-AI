library;

import '../domain/entities/current_affairs_knowledge_object.dart';
import '../domain/entities/news_event.dart';
import '../services/current_affairs_scoring_engine.dart';
import 'current_affairs_relationship_builder.dart';

/// Mapper transforming ingested NewsEvents into fully linked CurrentAffairsKnowledgeObjects.
class CurrentAffairsMapper {
  static CurrentAffairsKnowledgeObject mapToKnowledgeObject(NewsEvent event) {
    final links = CurrentAffairsRelationshipBuilder.buildLinks(event);
    final intelligence = CurrentAffairsScoringEngine.calculateIntelligence(
      event: event,
      links: links,
    );

    final date = event.publicationDate;
    final timelinePos = '${date.year}-Q${((date.month - 1) ~/ 3) + 1}';

    return CurrentAffairsKnowledgeObject(
      id: event.id,
      headline: event.headline,
      summary: event.summary,
      content: event.content,
      officialSource: event.officialSource,
      sourceUrl: event.sourceUrl,
      publicationDate: event.publicationDate,
      retrievedDate: event.retrievedDate,
      category: event.category,
      subcategory: event.subcategory,
      country: event.country,
      state: event.state,
      ministry: event.ministry,
      importance: event.importance,
      keywords: event.keywords,
      tags: event.tags,
      timelinePosition: timelinePos,
      evidenceIds: event.evidenceIds,
      intelligence: intelligence,
      links: links,
      metadata: event.rawMetadata,
    );
  }
}
