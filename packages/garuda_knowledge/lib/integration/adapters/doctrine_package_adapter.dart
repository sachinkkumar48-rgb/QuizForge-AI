import '../../domain/entities/knowledge_evidence_reference.dart';
import '../../domain/entities/knowledge_metadata.dart';
import '../../domain/entities/knowledge_object.dart';
import '../../domain/entities/knowledge_relationship.dart';
import '../../domain/entities/knowledge_version.dart';
import '../../domain/enums/knowledge_object_type.dart';
import '../../domain/enums/relationship_type.dart';
import '../../domain/value_objects/knowledge_object_id.dart';
import '../registry/knowledge_capability.dart';
import 'knowledge_package_adapter.dart';

class DoctrinePackageAdapter implements KnowledgePackageAdapter {
  @override
  String get packageName => 'garuda_doctrine';

  @override
  String get version => '0.1.0';

  @override
  List<KnowledgeCapability> get capabilities => const [
        KnowledgeCapability(
          id: 'cap_doctrines',
          name: 'Legal and Constitutional Doctrines',
          description: 'Provides jurisprudence doctrines like Basic Structure, Severability, Pith and Substance.',
        ),
      ];

  @override
  Future<List<KnowledgeObject>> extractObjects() async {
    return [
      KnowledgeObject(
        id: const KnowledgeObjectId('DOC-BASIC-STRUCTURE'),
        type: KnowledgeObjectType.doctrine,
        title: 'Doctrine of Basic Structure',
        content: 'Judicial principle that certain fundamental features of the Constitution cannot be altered by parliamentary amendments.',
        currentVersion: KnowledgeVersion(
          versionNumber: 1,
          commitMessage: 'Initial extract',
          author: 'garuda_doctrine',
          timestamp: DateTime.now(),
        ),
        metadata: KnowledgeMetadata(
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'garuda_doctrine',
        ),
      ),
    ];
  }

  @override
  Future<List<KnowledgeRelationship>> extractRelationships() async {
    return [
      const KnowledgeRelationship(
        id: 'DOC-REL-BS-KB',
        sourceId: KnowledgeObjectId('DOC-BASIC-STRUCTURE'),
        targetId: KnowledgeObjectId('CASE-KB-1973'),
        type: RelationshipType.derivedFrom,
        description: 'Formulated in Kesavananda Bharati case',
      ),
    ];
  }

  @override
  Future<Map<String, dynamic>> extractMetadata() async {
    return {'package': packageName, 'version': version, 'domain': 'Jurisprudence'};
  }

  @override
  Future<List<KnowledgeEvidenceReference>> extractEvidenceReferences() async {
    return const [];
  }
}
