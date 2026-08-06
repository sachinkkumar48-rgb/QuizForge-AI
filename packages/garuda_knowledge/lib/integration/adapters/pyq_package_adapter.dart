import '../../domain/entities/knowledge_evidence_reference.dart';
import '../../domain/entities/knowledge_metadata.dart';
import '../../domain/entities/knowledge_object.dart';
import '../../domain/entities/knowledge_relationship.dart';
import '../../domain/entities/knowledge_tag.dart';
import '../../domain/entities/knowledge_version.dart';
import '../../domain/enums/knowledge_object_type.dart';
import '../../domain/enums/relationship_type.dart';
import '../../domain/value_objects/knowledge_object_id.dart';
import '../registry/knowledge_capability.dart';
import 'knowledge_package_adapter.dart';

class PyqPackageAdapter implements KnowledgePackageAdapter {
  @override
  String get packageName => 'garuda_pyq';

  @override
  String get version => '0.1.0';

  @override
  List<KnowledgeCapability> get capabilities => const [
        KnowledgeCapability(
          id: 'cap_pyq_questions',
          name: 'Previous Years Questions (PYQ)',
          description: 'Provides categorized UPSC and State PSC previous year examination questions.',
        ),
      ];

  @override
  Future<List<KnowledgeObject>> extractObjects() async {
    return [
      KnowledgeObject(
        id: const KnowledgeObjectId('PYQ-UPSC-2024-Q10'),
        type: KnowledgeObjectType.pyq,
        title: 'UPSC Prelims 2024 Question 10',
        content: 'Consider the following statements regarding the Right to Privacy under Article 21...',
        tags: const [KnowledgeTag('UPSC'), KnowledgeTag('Article 21'), KnowledgeTag('Privacy')],
        currentVersion: KnowledgeVersion(
          versionNumber: 1,
          commitMessage: 'Initial extract',
          author: 'garuda_pyq',
          timestamp: DateTime.now(),
        ),
        metadata: KnowledgeMetadata(
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'garuda_pyq',
        ),
      ),
    ];
  }

  @override
  Future<List<KnowledgeRelationship>> extractRelationships() async {
    return [
      const KnowledgeRelationship(
        id: 'PYQ-REL-Q10-ART21',
        sourceId: KnowledgeObjectId('PYQ-UPSC-2024-Q10'),
        targetId: KnowledgeObjectId('CONST-ART-21'),
        type: RelationshipType.questionOn,
        description: 'Question tests understanding of Article 21',
      ),
    ];
  }

  @override
  Future<Map<String, dynamic>> extractMetadata() async {
    return {'package': packageName, 'version': version, 'domain': 'Assessment'};
  }

  @override
  Future<List<KnowledgeEvidenceReference>> extractEvidenceReferences() async {
    return const [];
  }
}
