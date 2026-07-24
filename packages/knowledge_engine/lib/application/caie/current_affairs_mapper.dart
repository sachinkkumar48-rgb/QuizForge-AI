import '../../domain/entities/knowledge_object.dart';
import '../../domain/value_objects/knowledge_type.dart';
import 'current_affairs_item.dart';
import 'current_affairs_parser.dart';

/// Component responsible for mapping [CurrentAffairsItem] entities into existing
/// canonical [KnowledgeObject] entities without introducing parallel domain models.
class CurrentAffairsMapper {
  final CurrentAffairsParser _parser;

  /// Constructs a [CurrentAffairsMapper] with optional [CurrentAffairsParser].
  CurrentAffairsMapper({CurrentAffairsParser? parser})
      : _parser = parser ?? CurrentAffairsParser();

  /// Converts a [CurrentAffairsItem] into a canonical [KnowledgeObject].
  KnowledgeObject mapToKnowledge(CurrentAffairsItem item) {
    final normalized = _parser.normalize(item);
    final metadata = _parser.extractMetadata(normalized);

    final summaryText = normalized.summary.isNotEmpty
        ? normalized.summary
        : (normalized.content.length > 200
            ? '${normalized.content.substring(0, 200)}...'
            : normalized.content);

    final keywordsSet = <String>{
      ...normalized.tags,
      ...normalized.relatedSubjects,
      if (normalized.category.isNotEmpty) normalized.category,
    };

    return KnowledgeObject(
      id: normalized.id,
      type: KnowledgeType.article,
      title: normalized.title,
      summary: summaryText,
      source: normalized.source,
      language: 'en',
      subjects: normalized.relatedSubjects,
      topics: normalized.tags,
      keywords: keywordsSet.toList(),
      metadata: metadata,
      createdAt: normalized.publicationDate,
      updatedAt: DateTime.now(),
    );
  }
}
