import '../../domain/entities/knowledge_evidence_reference.dart';
import '../../domain/entities/knowledge_metadata.dart';
import '../../domain/entities/knowledge_object.dart';
import '../../domain/entities/knowledge_relationship.dart';
import '../../domain/entities/knowledge_version.dart';
import '../../domain/enums/knowledge_object_type.dart';
import '../../domain/value_objects/knowledge_object_id.dart';
import '../registry/knowledge_capability.dart';
import 'knowledge_package_adapter.dart';

class EvidencePackageAdapter implements KnowledgePackageAdapter {
  @override
  String get packageName => 'garuda_evidence';

  @override
  String get version => '0.1.0';

  @override
  List<KnowledgeCapability> get capabilities => const [
        KnowledgeCapability(
          id: 'cap_evidence_collector',
          name: 'Official Publications & Evidence Ingestion',
          description: 'Ingests, validates, and stores external evidence assets.',
        ),
      ];

  @override
  Future<List<KnowledgeObject>> extractObjects() async {
    return [
      KnowledgeObject(
        id: const KnowledgeObjectId('EVD-OBJ-PIB-2026'),
        type: KnowledgeObjectType.currentAffair,
        title: 'PIB Notification on Electoral Reforms',
        content: 'Official Gazette publication regarding election commission guidelines.',
        evidenceReferences: const [
          KnowledgeEvidenceReference(
            evidenceId: 'EVD-PIB-10092',
            evidenceType: 'PIB_Release',
            confidenceScore: 0.98,
          )
        ],
        currentVersion: KnowledgeVersion(
          versionNumber: 1,
          commitMessage: 'Initial extract',
          author: 'garuda_evidence',
          timestamp: DateTime.now(),
        ),
        metadata: KnowledgeMetadata(
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'garuda_evidence',
        ),
      ),
    ];
  }

  @override
  Future<List<KnowledgeRelationship>> extractRelationships() async {
    return const [];
  }

  @override
  Future<Map<String, dynamic>> extractMetadata() async {
    return {'package': packageName, 'version': version, 'domain': 'Current Affairs & Evidence'};
  }

  @override
  Future<List<KnowledgeEvidenceReference>> extractEvidenceReferences() async {
    return const [
      KnowledgeEvidenceReference(
        evidenceId: 'EVD-PIB-10092',
        evidenceType: 'PIB_Release',
        confidenceScore: 0.98,
      ),
    ];
  }
}
