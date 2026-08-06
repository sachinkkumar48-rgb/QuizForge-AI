import '../../domain/entities/knowledge_category.dart';
import '../../domain/entities/knowledge_citation.dart';
import '../../domain/entities/knowledge_metadata.dart';
import '../../domain/entities/knowledge_object.dart';
import '../../domain/entities/knowledge_relationship.dart';
import '../../domain/entities/knowledge_tag.dart';
import '../../domain/entities/knowledge_version.dart';
import '../../domain/enums/knowledge_object_type.dart';
import '../../domain/enums/relationship_type.dart';
import '../../domain/value_objects/knowledge_object_id.dart';
import '../extractors/knowledge_extractor.dart';
import '../models/knowledge_document.dart';
import '../models/knowledge_document_type.dart';
import 'knowledge_mapper.dart';

/// Default Mapper implementing conversion from ExtractionResult to GARUDA KnowledgeObject.
class DefaultKnowledgeMapper implements KnowledgeMapper {
  @override
  KnowledgeMappingResult map({
    required KnowledgeDocument document,
    required ExtractionResult extraction,
  }) {
    final objectId = KnowledgeObjectId('OBJ-${document.documentId}');
    final objectType = _mapDocumentTypeToObjectType(document.type);

    final tags = extraction.tags.map((t) => KnowledgeTag(t)).toList();

    final citations = extraction.evidenceReferences.map((e) {
      return KnowledgeCitation(
        id: 'CIT-${e.evidenceId}',
        text: 'Official Source Citation: ${document.source.title}',
        sourceReference: document.officialUrl,
      );
    }).toList();

    final relationships = <KnowledgeRelationship>[];
    for (int i = 0; i < extraction.extractedRelationships.length; i++) {
      final rel = extraction.extractedRelationships[i];
      if (rel.containsKey('targetId') && rel.containsKey('relationshipType')) {
        relationships.add(KnowledgeRelationship(
          id: 'REL-${document.documentId}-$i',
          sourceId: objectId,
          targetId: KnowledgeObjectId(rel['targetId'] as String),
          type: RelationshipType.fromJson(rel['relationshipType'] as String),
          metadata: Map<String, dynamic>.from(rel['metadata'] as Map? ?? {}),
        ));
      }
    }

    final category = KnowledgeCategory(
      id: document.type.name,
      name: document.type.displayName,
    );

    final metadata = KnowledgeMetadata(
      createdAt: document.retrievedDate,
      updatedAt: DateTime.now(),
      createdBy: document.source.title.isNotEmpty ? document.source.title : 'GARUDA_Ingestion_Engine',
      locale: document.language == 'en' ? 'en_IN' : document.language,
      customAttributes: {
        ...document.metadata,
        ...extraction.metadata,
        'documentId': document.documentId,
        'parserVersion': document.parserVersion,
        'language': document.language,
        'checksum': document.checksum,
        'editorialStatus': document.editorialStatus.name,
      },
    );

    final knowledgeObject = KnowledgeObject(
      id: objectId,
      type: objectType,
      title: extraction.title,
      content: extraction.content,
      summary: extraction.content.length > 200
          ? '${extraction.content.substring(0, 197)}...'
          : extraction.content,
      category: category,
      tags: tags,
      sources: [document.source],
      citations: citations,
      evidenceReferences: extraction.evidenceReferences,
      relationships: relationships,
      currentVersion: KnowledgeVersion(
        versionNumber: 1,
        commitMessage: 'Initial Ingestion from ${document.source.title}',
        author: 'GARUDA_Ingestion_Engine',
        timestamp: document.publicationDate,
      ),
      metadata: metadata,
    );

    return KnowledgeMappingResult(
      knowledgeObject: knowledgeObject,
      relationships: relationships,
    );
  }

  KnowledgeObjectType _mapDocumentTypeToObjectType(KnowledgeDocumentType docType) {
    switch (docType) {
      case KnowledgeDocumentType.constitution:
        return KnowledgeObjectType.constitutionArticle;
      case KnowledgeDocumentType.gazetteNotification:
        return KnowledgeObjectType.act;
      case KnowledgeDocumentType.upscQuestionPaper:
      case KnowledgeDocumentType.upscAnswerKey:
        return KnowledgeObjectType.pyq;
      case KnowledgeDocumentType.pibRelease:
      case KnowledgeDocumentType.prsReport:
      case KnowledgeDocumentType.ministryReport:
      case KnowledgeDocumentType.economicSurvey:
      case KnowledgeDocumentType.unionBudget:
        return KnowledgeObjectType.report;
      case KnowledgeDocumentType.supremeCourtJudgment:
        return KnowledgeObjectType.caseLaw;
      case KnowledgeDocumentType.generic:
        return KnowledgeObjectType.custom;
    }
  }
}
