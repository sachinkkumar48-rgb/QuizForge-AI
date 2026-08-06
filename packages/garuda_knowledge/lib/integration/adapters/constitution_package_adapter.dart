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

class ConstitutionPackageAdapter implements KnowledgePackageAdapter {
  @override
  String get packageName => 'garuda_constitution';

  @override
  String get version => '0.1.0';

  @override
  List<KnowledgeCapability> get capabilities => const [
        KnowledgeCapability(
          id: 'cap_constitution_articles',
          name: 'Constitutional Articles',
          description: 'Provides Articles, Parts, and Schedules of the Constitution of India.',
        ),
      ];

  @override
  Future<List<KnowledgeObject>> extractObjects() async {
    return [
      KnowledgeObject(
        id: const KnowledgeObjectId('CONST-ART-14'),
        type: KnowledgeObjectType.constitutionArticle,
        title: 'Article 14 - Equality before Law',
        content: 'The State shall not deny to any person equality before the law...',
        currentVersion: KnowledgeVersion(
          versionNumber: 1,
          commitMessage: 'Initial extract',
          author: 'garuda_constitution',
          timestamp: DateTime.now(),
        ),
        metadata: KnowledgeMetadata(
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'garuda_constitution',
        ),
      ),
      KnowledgeObject(
        id: const KnowledgeObjectId('CONST-ART-21'),
        type: KnowledgeObjectType.constitutionArticle,
        title: 'Article 21 - Protection of Life and Personal Liberty',
        content: 'No person shall be deprived of his life or personal liberty except according to procedure established by law.',
        currentVersion: KnowledgeVersion(
          versionNumber: 1,
          commitMessage: 'Initial extract',
          author: 'garuda_constitution',
          timestamp: DateTime.now(),
        ),
        metadata: KnowledgeMetadata(
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'garuda_constitution',
        ),
      ),
    ];
  }

  @override
  Future<List<KnowledgeRelationship>> extractRelationships() async {
    return [
      const KnowledgeRelationship(
        id: 'CONST-REL-14-21',
        sourceId: KnowledgeObjectId('CONST-ART-14'),
        targetId: KnowledgeObjectId('CONST-ART-21'),
        type: RelationshipType.relatedTo,
        description: 'Golden Triangle relationship (Article 14, 19, 21)',
      ),
    ];
  }

  @override
  Future<Map<String, dynamic>> extractMetadata() async {
    return {
      'package': packageName,
      'version': version,
      'domain': 'Constitutional Law',
    };
  }

  @override
  Future<List<KnowledgeEvidenceReference>> extractEvidenceReferences() async {
    return const [];
  }
}
