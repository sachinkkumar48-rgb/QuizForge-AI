import 'package:flutter_test/flutter_test.dart';
import 'package:titan_ingestion_pipeline/titan_ingestion_pipeline.dart';

void main() {
  group('SummaryEngine Tests', () {
    late SummaryEngine summaryEngine;

    setUp(() {
      summaryEngine = SummaryEngine();
    });

    test('Generates 30s, 5m, and detailed summaries from KnowledgeObject',
        () async {
      final obj = KnowledgeObject(
        id: 'k_polity_01',
        title: 'Fundamental Rights',
        source: 'polity.md',
        concepts: [
          KnowledgeConcept(
            id: 'c1',
            name: 'Article 21',
            type: ConceptType.article,
            description: 'Right to Life and Personal Liberty',
          ),
        ],
        contentBlocks: const [
          ParagraphBlock(
              id: 'b1', text: 'Article 21 guarantees protection of life.')
        ],
      );

      final bundle = await summaryEngine.generate(obj);

      expect(bundle.summary30s, contains('Fundamental Rights'));
      expect(bundle.summary5m, contains('Executive Summary'));
      expect(bundle.detailedSummary, contains('Detailed Analysis'));
    });
  });
}
