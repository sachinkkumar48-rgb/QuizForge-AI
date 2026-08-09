import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';
import 'package:garuda_graph/garuda_graph.dart'
    show
        InMemoryKnowledgeGraphRepository,
        KnowledgeLink,
        KnowledgeRelationshipType,
        LinkStatus;

/// P5 integration — the legal graph maps onto the generic GARUDA Knowledge
/// Graph infrastructure without losing its evidence (TITAN-KO-015.0 P5).
void main() {
  final graph = LegalGraphSeed.fromCorpus().build();

  test('exportLinks projects every legal edge onto a KnowledgeLink', () {
    final links = GarudaKnowledgeGraphBridge.exportLinks(graph);
    expect(links.length, graph.edgeCount);
    for (final link in links) {
      expect(link, isA<KnowledgeLink>());
      expect(link.id, startsWith('gkg:'));
      expect(link.status, LinkStatus.approved);
      expect(link.evidenceReferences, isNotEmpty);
      expect(link.reason, isNotEmpty);
      expect(link.sourceObject.id, isNotEmpty);
      expect(link.targetObject.id, isNotEmpty);
    }
  });

  test('precedent semantics map onto the generic vocabulary', () {
    final links = GarudaKnowledgeGraphBridge.exportLinks(graph);
    final overruled = links.firstWhere((l) => l.id == 'gkg:KESAVANANDA|overruled|GOLAKNATH');
    expect(overruled.relationshipType, KnowledgeRelationshipType.overrules);
    final followed = links.firstWhere((l) => l.id == 'gkg:MINERVA_MILLS|followed|KESAVANANDA');
    expect(followed.relationshipType, KnowledgeRelationshipType.references);
    final doctrine = links.firstWhere((l) => l.id == 'gkg:IR_COELHO|expands|BASIC_STRUCTURE');
    expect(doctrine.relationshipType, KnowledgeRelationshipType.affects);
    expect(doctrine.targetObject.id, 'BASIC_STRUCTURE');
  });

  test('exportToRepository persists the full graph', () async {
    final repository = InMemoryKnowledgeGraphRepository();
    final saved = await GarudaKnowledgeGraphBridge.exportToRepository(graph, repository);
    expect(saved, graph.edgeCount);
    // A doctine link and a case link both resolve through the repository.
    final byNode = await repository.findLinksByNode('KESAVANANDA');
    expect(byNode, isNotEmpty);
    final doctrine = await repository.findLinksByNode('BASIC_STRUCTURE');
    expect(doctrine, isNotEmpty);
  });
}
