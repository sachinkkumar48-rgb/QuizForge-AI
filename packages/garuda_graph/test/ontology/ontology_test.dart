import 'package:garuda_graph/garuda_graph.dart';
import 'package:test/test.dart';

void main() {
  group('KnowledgeOntology Tests', () {
    late KnowledgeOntology ontology;

    setUp(() {
      ontology = KnowledgeOntology();

      // Hierarchy: Subject (Polity) -> Module (Fundamental Rights) -> Topic (Article 19) -> Subtopic (Speech) -> Concept (Press Freedom) -> KO -> Evidence
      const nSubject = KnowledgeOntologyNode(id: 'polity', title: 'Indian Polity', type: NodeType.subject, depth: 0);
      const nModule = KnowledgeOntologyNode(id: 'fr', title: 'Fundamental Rights', type: NodeType.module, parentId: 'polity', depth: 1);
      const nTopic = KnowledgeOntologyNode(id: 'art19', title: 'Article 19', type: NodeType.topic, parentId: 'fr', depth: 2);
      const nConcept = KnowledgeOntologyNode(id: 'speech', title: 'Freedom of Speech', type: NodeType.concept, parentId: 'art19', depth: 3);

      ontology.addNode(nSubject);
      ontology.addNode(nModule);
      ontology.addNode(nTopic);
      ontology.addNode(nConcept);
    });

    test('getAncestors should traverse hierarchy up to root', () {
      final ancestors = ontology.getAncestors('speech');
      expect(ancestors.length, equals(3));
      expect(ancestors.map((n) => n.id), containsAll(['art19', 'fr', 'polity']));
    });

    test('getDescendants should traverse hierarchy downwards', () {
      final descendants = ontology.getDescendants('polity');
      expect(descendants.length, equals(3));
      expect(descendants.map((n) => n.id), containsAll(['fr', 'art19', 'speech']));
    });

    test('isSameBranch should verify branch relationship', () {
      expect(ontology.isSameBranch('speech', 'polity'), isTrue);
    });
  });
}
