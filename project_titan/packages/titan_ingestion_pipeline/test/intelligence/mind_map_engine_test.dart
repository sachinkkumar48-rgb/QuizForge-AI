import 'package:flutter_test/flutter_test.dart';
import 'package:titan_ingestion_pipeline/titan_ingestion_pipeline.dart';

void main() {
  group('MindMapEngine Tests', () {
    late MindMapEngine mindMapEngine;

    setUp(() {
      mindMapEngine = MindMapEngine();
    });

    test('Generates hierarchical MindMapStructure from KnowledgeObject', () {
      final obj = KnowledgeObject(
        id: 'k_polity_04',
        title: 'Emergency Provisions',
        source: 'emergency.md',
        concepts: [
          KnowledgeConcept(
              id: 'c1',
              name: 'National Emergency',
              type: ConceptType.article,
              description: 'Article 352'),
          KnowledgeConcept(
              id: 'c2',
              name: 'Presidents Rule',
              type: ConceptType.article,
              description: 'Article 356'),
        ],
        contentBlocks: const [
          HeadingBlock(id: 'b1', level: 2, text: 'Financial Emergency'),
        ],
      );

      final mindMap = mindMapEngine.generate(obj);

      expect(mindMap.title, equals('Emergency Provisions'));
      expect(mindMap.rootNode.label, equals('Emergency Provisions'));
      expect(mindMap.branches, contains('National Emergency'));
      expect(mindMap.branches, contains('Financial Emergency'));
    });
  });
}
