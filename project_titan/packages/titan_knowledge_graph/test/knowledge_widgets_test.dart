import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_knowledge_graph/titan_knowledge_graph.dart';

void main() {
  group('Knowledge Graph Material 3 Widget Tests', () {
    late KnowledgeGraph sampleGraph;
    late KnowledgeNode nodeConcept;

    setUp(() {
      nodeConcept = KnowledgeNode(
        id: 'c1',
        title: 'Article 21: Right to Life',
        type: KnowledgeNodeType.concept,
      );

      sampleGraph = KnowledgeGraph(
        nodes: {
          'c1': nodeConcept,
          't1': KnowledgeNode(
            id: 't1',
            title: 'Fundamental Rights',
            type: KnowledgeNodeType.topic,
          ),
        },
        edges: [
          KnowledgeEdge(
            id: 'e1',
            sourceId: 't1',
            targetId: 'c1',
            relationType: KnowledgeRelationType.contains,
          ),
        ],
      );
    });

    testWidgets('GraphNodeChip renders title, icon, and responds to tap',
        (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GraphNodeChip(
              node: nodeConcept,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Article 21: Right to Life'), findsOneWidget);
      await tester.tap(find.byType(FilterChip));
      expect(tapped, isTrue);
    });

    testWidgets('KnowledgeGraphCard renders node and edge statistics',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KnowledgeGraphCard(graph: sampleGraph),
          ),
        ),
      );

      expect(find.text('TITAN Knowledge Graph'), findsOneWidget);
      expect(find.textContaining('2 Nodes'), findsOneWidget);
    });

    testWidgets('RelatedTopicsCard renders title and topic list',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RelatedTopicsCard(
              rootTitle: 'Article 21',
              relatedTopics: [nodeConcept],
            ),
          ),
        ),
      );

      expect(find.textContaining('Related Topics for "Article 21"'),
          findsOneWidget);
      expect(find.text('Article 21: Right to Life'), findsOneWidget);
    });

    testWidgets('LearningPathCard renders ordered step timeline',
        (tester) async {
      final path = KnowledgePath(
        nodes: [
          sampleGraph.getNode('t1')!,
          sampleGraph.getNode('c1')!,
        ],
        edges: sampleGraph.edges,
        totalDistance: 1.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LearningPathCard(path: path),
          ),
        ),
      );

      expect(find.text('Shortest Learning Path'), findsOneWidget);
      expect(find.text('Fundamental Rights'), findsOneWidget);
      expect(find.text('Article 21: Right to Life'), findsOneWidget);
    });

    testWidgets('KnowledgeExplorerPanel renders node list and filter controls',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: KnowledgeExplorerPanel(graph: sampleGraph),
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Article 21: Right to Life'), findsOneWidget);
    });
  });
}
