import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_knowledge/garuda_knowledge.dart';

void main() {
  group('Source Adapters Test Suite', () {
    final adapters = <KnowledgeSourceAdapter>[
      ConstitutionSourceAdapter(),
      GazetteNotificationAdapter(),
      UpscQuestionPaperAdapter(),
      UpscAnswerKeyAdapter(),
      PibReleaseAdapter(),
      PrsReportAdapter(),
      SupremeCourtJudgmentAdapter(),
      MinistryReportAdapter(),
      EconomicSurveyAdapter(),
      UnionBudgetAdapter(),
    ];

    test('All 10 source adapters are instantiated with correct unique source IDs', () {
      expect(adapters.length, equals(10));
      final sourceIds = adapters.map((a) => a.sourceId).toSet();
      expect(sourceIds.length, equals(10));
    });

    test('ConstitutionSourceAdapter resolves constitution documents', () {
      final adapter = ConstitutionSourceAdapter();
      final doc = KnowledgeDocument.create(
        documentId: 'CONST-1',
        source: const KnowledgeSource(sourceId: 'CONSTITUTION_INDIA', title: 'Constitution'),
        type: KnowledgeDocumentType.constitution,
        title: 'Preamble',
        content: 'WE, THE PEOPLE OF INDIA...',
        publicationDate: DateTime(1950, 1, 26),
      );

      expect(adapter.supports(doc), isTrue);
      expect(adapter.parser, isA<TextKnowledgeParser>());
    });

    test('UpscQuestionPaperAdapter resolves upsc question paper documents', () {
      final adapter = UpscQuestionPaperAdapter();
      final doc = KnowledgeDocument.create(
        documentId: 'UPSC-2024-GS1',
        source: const KnowledgeSource(sourceId: 'UPSC_QP', title: 'UPSC QP'),
        type: KnowledgeDocumentType.upscQuestionPaper,
        title: 'UPSC Prelims GS-1 2024',
        content: '{"title": "Question 1", "body": "Consider the following statements..."}',
        publicationDate: DateTime(2024, 6, 16),
      );

      expect(adapter.supports(doc), isTrue);
      expect(adapter.parser, isA<JsonKnowledgeParser>());
    });
  });
}
