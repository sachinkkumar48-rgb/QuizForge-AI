import '../../domain/entities/knowledge_evidence_reference.dart';
import '../../domain/entities/knowledge_metadata.dart';
import '../../domain/entities/knowledge_object.dart';
import '../../domain/entities/knowledge_relationship.dart';
import '../../domain/entities/knowledge_version.dart';
import '../../domain/enums/knowledge_object_type.dart';
import '../../domain/value_objects/knowledge_object_id.dart';
import '../registry/knowledge_capability.dart';
import 'knowledge_package_adapter.dart';

class GraphPackageAdapter implements KnowledgePackageAdapter {
  @override
  String get packageName => 'garuda_graph';

  @override
  String get version => '0.1.0';

  @override
  List<KnowledgeCapability> get capabilities => const [
        KnowledgeCapability(
          id: 'cap_graph_linking',
          name: 'Knowledge Graph & Ontology Linking',
          description: 'Provides node/edge ontology graphs and automated linking models.',
        ),
      ];

  @override
  Future<List<KnowledgeObject>> extractObjects() async {
    return [
      KnowledgeObject(
        id: const KnowledgeObjectId('GRAPH-NODE-POLITY'),
        type: KnowledgeObjectType.map,
        title: 'Polity Ontology Master Node',
        content: 'Root knowledge graph node for Indian Polity taxonomy.',
        currentVersion: KnowledgeVersion(
          versionNumber: 1,
          commitMessage: 'Initial extract',
          author: 'garuda_graph',
          timestamp: DateTime.now(),
        ),
        metadata: KnowledgeMetadata(
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'garuda_graph',
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
    return {'package': packageName, 'version': version, 'domain': 'Graph Ontology'};
  }

  @override
  Future<List<KnowledgeEvidenceReference>> extractEvidenceReferences() async {
    return const [];
  }
}
