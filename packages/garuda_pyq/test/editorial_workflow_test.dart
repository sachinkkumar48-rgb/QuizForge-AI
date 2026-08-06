import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  group('EditorialWorkflowService Tests', () {
    late OfflinePYQRepository repo;
    late EditorialWorkflowService service;

    setUp(() async {
      repo = OfflinePYQRepository();
      service = EditorialWorkflowService(repo);

      final source = QuestionSource(
        sourceType: SourceType.officialPdf,
        publisher: 'UPSC',
        retrievedDate: DateTime.now(),
        checksum: 'checksum_100',
      );

      final q = Question(
        id: 'Q_WORKFLOW_1',
        examId: 'upsc_cse',
        year: 2024,
        stage: 'Prelims',
        paper: 'GS1',
        subject: 'Polity',
        topic: 'Preamble',
        originalQuestion: 'Sample Question',
        options: const [],
        officialAnswer: const Answer(correctOptionKeys: ['A']),
        source: source,
        conceptsTested: const ['C_PREAMBLE'],
        editorialStatus: EditorialStatus.imported,
      );

      await repo.saveQuestion(q);
    });

    test('advanceStage progresses question through editorial stages', () async {
      final v1 = await service.advanceStage('Q_WORKFLOW_1', EditorialStatus.verified);
      expect(v1!.editorialStatus, equals(EditorialStatus.verified));

      final v2 = await service.advanceStage('Q_WORKFLOW_1', EditorialStatus.answerVerified);
      expect(v2!.editorialStatus, equals(EditorialStatus.answerVerified));

      final v3 = await service.advanceStage('Q_WORKFLOW_1', EditorialStatus.readyForPublication);
      expect(v3!.editorialStatus, equals(EditorialStatus.readyForPublication));
    });

    test('advanceStage enforces quality rule for missing answer key', () async {
      final source = QuestionSource(
        sourceType: SourceType.officialPdf,
        publisher: 'UPSC',
        retrievedDate: DateTime.now(),
        checksum: 'checksum_200',
      );

      final unverifiedQ = Question(
        id: 'Q_NO_ANSWER_KEY',
        examId: 'upsc_cse',
        year: 2024,
        stage: 'Prelims',
        paper: 'GS1',
        subject: 'Polity',
        topic: 'Preamble',
        originalQuestion: 'Question without key',
        options: const [],
        officialAnswer: const Answer(correctOptionKeys: []), // Missing key
        source: source,
        editorialStatus: EditorialStatus.imported,
      );

      await repo.saveQuestion(unverifiedQ);

      expect(
        () => service.advanceStage('Q_NO_ANSWER_KEY', EditorialStatus.answerVerified),
        throwsA(isA<StateError>()),
      );
    });
  });
}
