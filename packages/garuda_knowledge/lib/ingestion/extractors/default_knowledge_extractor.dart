import '../../domain/entities/knowledge_evidence_reference.dart';
import '../models/knowledge_document.dart';
import '../parsers/knowledge_parser.dart';
import 'knowledge_extractor.dart';

/// Default Extractor for metadata, tags, evidence, and concepts.
class DefaultKnowledgeExtractor implements KnowledgeExtractor {
  @override
  ExtractionResult extract({
    required KnowledgeDocument document,
    required ParseResult parseResult,
  }) {
    final tags = <String>{document.type.name, document.language};
    final concepts = <String>{};
    final evidenceList = <KnowledgeEvidenceReference>[];

    // Extract tags from metadata
    if (document.metadata.containsKey('tags') && document.metadata['tags'] is List) {
      for (final t in document.metadata['tags'] as List) {
        tags.add(t.toString().toLowerCase().trim());
      }
    }

    // Extract evidence reference if officialUrl is present
    if (document.officialUrl != null && document.officialUrl!.isNotEmpty) {
      evidenceList.add(KnowledgeEvidenceReference(
        evidenceId: 'EVI-${document.documentId}',
        evidenceType: 'official_document',
        verifiedBy: document.source.title,
        verifiedAt: document.retrievedDate,
      ));
    }

    // Extract concepts and domain tags from content keywords
    final lowerContent = parseResult.content.toLowerCase();
    if (lowerContent.contains('constitution') || lowerContent.contains('article')) {
      concepts.add('constitutional_law');
    }
    if (lowerContent.contains('judgment') || lowerContent.contains('supreme court')) {
      concepts.add('jurisprudence');
    }
    if (lowerContent.contains('upsc') || lowerContent.contains('question')) {
      concepts.add('examination_standards');
    }
    if (lowerContent.contains('budget') || lowerContent.contains('economic survey')) {
      concepts.add('macroeconomics');
    }

    return ExtractionResult(
      title: parseResult.title,
      content: parseResult.content,
      metadata: {
        ...document.metadata,
        ...parseResult.parsedMetadata,
        'documentId': document.documentId,
        'sourceId': document.source.sourceId,
        'checksum': document.checksum,
        'publicationDate': document.publicationDate.toIso8601String(),
      },
      tags: tags.toList(),
      concepts: concepts.toList(),
      evidenceReferences: evidenceList,
    );
  }
}
