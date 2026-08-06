import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  group('PYQValidator Tests', () {
    test('validateQuestion detects invalid exam and year', () {
      final invalidQuestion = Question(
        id: 'V1',
        examId: 'invalid_exam_code',
        year: 1800, // Invalid year
        stage: 'Prelims',
        paper: 'GS1',
        subject: 'Polity',
        topic: 'Preamble',
        originalQuestion: 'Test question?',
        options: const [],
        officialAnswer: const Answer(correctOptionKeys: ['A']),
        garudaExplanation: 'Test explanation',
        source: QuestionSource(
          sourceType: SourceType.editorialEntry,
          publisher: 'Test',
          retrievedDate: DateTime.now(),
          checksum: '111',
        ),
      );

      final errors = PYQValidator.validateQuestion(invalidQuestion);
      expect(errors.any((e) => e.code == ValidationErrorCode.invalidExam), isTrue);
      expect(errors.any((e) => e.code == ValidationErrorCode.invalidYear), isTrue);
    });

    test('validateQuestion detects missing metadata', () {
      final emptyMetadataQuestion = Question(
        id: '  ',
        examId: 'upsc_cse',
        year: 2024,
        stage: 'Prelims',
        paper: 'GS1',
        subject: '',
        topic: '',
        originalQuestion: '',
        options: const [],
        officialAnswer: const Answer(correctOptionKeys: []),
        garudaExplanation: '',
        source: QuestionSource(
          sourceType: SourceType.editorialEntry,
          publisher: 'Test',
          retrievedDate: DateTime.now(),
          checksum: '111',
        ),
      );

      final errors = PYQValidator.validateQuestion(emptyMetadataQuestion);
      expect(errors.any((e) => e.code == ValidationErrorCode.missingMetadata), isTrue);
    });

    test('validateBatch detects duplicate questions', () {
      final q1 = Question(
        id: 'B1',
        examId: 'upsc_cse',
        year: 2024,
        stage: 'Prelims',
        paper: 'GS1',
        subject: 'Polity',
        topic: 'Rights',
        originalQuestion: 'Identical question text?',
        options: const [],
        officialAnswer: const Answer(correctOptionKeys: ['A']),
        garudaExplanation: 'Exp',
        source: QuestionSource(
          sourceType: SourceType.editorialEntry,
          publisher: 'Test',
          retrievedDate: DateTime.now(),
          checksum: '111',
        ),
      );

      final q2 = Question(
        id: 'B2',
        examId: 'upsc_cse',
        year: 2024,
        stage: 'Prelims',
        paper: 'GS1',
        subject: 'Polity',
        topic: 'Rights',
        originalQuestion: 'Identical question text?',
        options: const [],
        officialAnswer: const Answer(correctOptionKeys: ['A']),
        garudaExplanation: 'Exp',
        source: QuestionSource(
          sourceType: SourceType.editorialEntry,
          publisher: 'Test',
          retrievedDate: DateTime.now(),
          checksum: '222',
        ),
      );

      final batchErrors = PYQValidator.validateBatch([q1, q2]);
      expect(batchErrors.any((e) => e.code == ValidationErrorCode.duplicateQuestion), isTrue);
    });
  });
}
