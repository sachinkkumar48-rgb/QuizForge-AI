import '../../domain/entities/knowledge_object.dart';
import '../../domain/value_objects/knowledge_type.dart';
import 'previous_year_question.dart';
import 'pyq_metadata_extractor.dart';
import 'pyq_parser.dart';

/// Component responsible for mapping [PreviousYearQuestion] entities into existing
/// canonical [KnowledgeObject] entities without introducing parallel question models.
class PYQMapper {
  final PYQParser _parser;
  final PYQMetadataExtractor _extractor;

  /// Constructs a [PYQMapper] with optional dependencies.
  PYQMapper({
    PYQParser? parser,
    PYQMetadataExtractor? extractor,
  })  : _parser = parser ?? PYQParser(),
        _extractor = extractor ?? PYQMetadataExtractor();

  /// Converts a [PreviousYearQuestion] into a canonical [KnowledgeObject].
  KnowledgeObject mapToKnowledge(PreviousYearQuestion question) {
    final normalized = _parser.normalize(question);
    final metadata = _extractor.extractMetadata(normalized);

    final subject = metadata['subject'] as String? ?? normalized.subject;
    final topics =
        List<String>.from(metadata['topics'] as List? ?? normalized.topics);
    final tags =
        List<String>.from(metadata['tags'] as List? ?? normalized.tags);

    final titleText =
        '[${normalized.exam} ${normalized.year} - ${normalized.paper}] '
        '${normalized.question.length > 80 ? '${normalized.question.substring(0, 80)}...' : normalized.question}';

    final summaryText = normalized.explanation.isNotEmpty
        ? normalized.explanation
        : normalized.question;

    final sourceText =
        '${normalized.exam} ${normalized.year} ${normalized.paper}'.trim();

    final keywordsSet = <String>{
      ...tags,
      ...topics,
      if (subject.isNotEmpty) subject,
      normalized.exam,
      '${normalized.year}',
      'PYQ',
    };

    return KnowledgeObject(
      id: normalized.id,
      type: KnowledgeType.pyq,
      title: titleText,
      summary: summaryText,
      source: sourceText,
      language: 'en',
      subjects: [if (subject.isNotEmpty && subject != 'General') subject],
      topics: topics,
      keywords: keywordsSet.toList(),
      metadata: metadata,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
