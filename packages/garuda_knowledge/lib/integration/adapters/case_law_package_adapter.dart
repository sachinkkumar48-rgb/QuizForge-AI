import '../../domain/entities/knowledge_evidence_reference.dart';
import '../../domain/entities/knowledge_metadata.dart';
import '../../domain/entities/knowledge_object.dart';
import '../../domain/entities/knowledge_relationship.dart';
import '../../domain/entities/knowledge_source.dart';
import '../../domain/entities/knowledge_version.dart';
import '../../domain/enums/knowledge_object_type.dart';
import '../../domain/enums/relationship_type.dart';
import '../../domain/value_objects/knowledge_object_id.dart';
import '../registry/knowledge_capability.dart';
import 'knowledge_package_adapter.dart';

class CaseLawPackageAdapter implements KnowledgePackageAdapter {
  @override
  String get packageName => 'garuda_case_law';

  @override
  String get version => '0.1.0';

  @override
  List<KnowledgeCapability> get capabilities => const [
        KnowledgeCapability(
          id: 'cap_case_law',
          name: 'Supreme Court & High Court Judgments',
          description: 'Provides landmark case law precedents and holdings.',
        ),
      ];

  @override
  Future<List<KnowledgeObject>> extractObjects() async {
    return [
      KnowledgeObject(
        id: const KnowledgeObjectId('CASE-KB-1973'),
        type: KnowledgeObjectType.caseLaw,
        title: 'Kesavananda Bharati v. State of Kerala (1973)',
        content: 'Landmark 13-judge bench ruling establishing the Basic Structure Doctrine.',
        sources: const [KnowledgeSource(sourceId: 'AIR-1973-SC-1461', title: 'AIR 1973 SC 1461')],
        currentVersion: KnowledgeVersion(
          versionNumber: 1,
          commitMessage: 'Initial extract',
          author: 'garuda_case_law',
          timestamp: DateTime.now(),
        ),
        metadata: KnowledgeMetadata(
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'garuda_case_law',
        ),
      ),
    ];
  }

  @override
  Future<List<KnowledgeRelationship>> extractRelationships() async {
    return [
      const KnowledgeRelationship(
        id: 'CASE-REL-KB-CONST',
        sourceId: KnowledgeObjectId('CASE-KB-1973'),
        targetId: KnowledgeObjectId('CONST-ART-368'),
        type: RelationshipType.interprets,
        description: 'Limits constituent power of Parliament under Article 368',
      ),
    ];
  }

  @override
  Future<Map<String, dynamic>> extractMetadata() async {
    return {'package': packageName, 'version': version, 'domain': 'Judiciary'};
  }

  @override
  Future<List<KnowledgeEvidenceReference>> extractEvidenceReferences() async {
    return [
      const KnowledgeEvidenceReference(
        evidenceId: 'EVD-JUDGMENT-1973',
        evidenceType: 'JudgmentText',
        confidenceScore: 1.0,
      ),
    ];
  }
}
