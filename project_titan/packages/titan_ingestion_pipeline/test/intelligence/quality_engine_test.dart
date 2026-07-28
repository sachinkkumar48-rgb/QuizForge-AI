import 'package:flutter_test/flutter_test.dart';
import 'package:titan_ingestion_pipeline/titan_ingestion_pipeline.dart';
import 'package:titan_question_bank/titan_question_bank.dart';

void main() {
  group('KnowledgeQualityEngine Tests', () {
    late KnowledgeQualityEngine qualityEngine;

    setUp(() {
      qualityEngine = KnowledgeQualityEngine();
    });

    test('Evaluates KnowledgeQualityReport and assigns score between 0 and 100',
        () {
      final obj = KnowledgeObject(
        id: 'k_polity_05',
        title: 'Amendment Process',
        chapter: 'Chapter 20',
        source: 'amendment.md',
        concepts: [
          KnowledgeConcept(
              id: 'c1',
              name: 'Article 368',
              type: ConceptType.article,
              description: 'Power of parliament'),
        ],
        contentBlocks: const [
          ParagraphBlock(id: 'b1', text: 'Special majority required.')
        ],
      );

      final report = qualityEngine.evaluate(
        obj: obj,
        questions: [
          KmpQuestionItem(
            id: 'q1',
            topicId: 't1',
            topicName: 'Amendment Process',
            type: KmpQuestionType.mcq,
            stem: 'Stem text',
            solutionExplanation: 'Exp',
            createdAt: DateTime.now(),
          ),
        ],
        flashcards: [
          GeneratedFlashcard(
              id: 'fc1',
              sourceKnowledgeObjectId: 'k_polity_05',
              front: 'F',
              back: 'B'),
        ],
        summary: const SummaryBundle(
            summary30s: '30s', summary5m: '5m', detailedSummary: 'Det'),
      );

      expect(report.score, greaterThan(70.0));
      expect(report.score, lessThanOrEqualTo(100.0));
      expect(report.sourceKnowledgeObjectId, equals('k_polity_05'));
    });
  });
}
