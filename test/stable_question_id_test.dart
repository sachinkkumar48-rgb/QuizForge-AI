import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_upsc/models/attempt.dart';
import 'package:quizforge_upsc/models/bookmark.dart';
import 'package:quizforge_upsc/models/explanation.dart';
import 'package:quizforge_upsc/models/question.dart';
import 'package:quizforge_upsc/models/question_statistics.dart';
import 'package:quizforge_upsc/models/user_note.dart';
import 'package:quizforge_upsc/services/dataset_validator.dart';
import 'package:quizforge_upsc/utils/question_id_generator.dart';

import 'dataset_importer_test.dart'; // Re-use in-memory repository implementations

void main() {
  group('Stable Question ID Generator & Validation Tests', () {
    test('Generates structured stable ID matching EXAM_PAPER_YEAR_Q001 format',
        () {
      final generatedId = QuestionIdGenerator.generateId(
        examCode: 'UPSC CSE Prelims',
        paperCode: 'GS Paper 1',
        year: 2025,
        questionIndex: 1,
      );

      expect(generatedId, equals('UPSC_PRE_GS1_2025_Q001'));
      expect(QuestionIdGenerator.isStableFormat(generatedId), isTrue);
    });

    test('Rejects plain numeric IDs (e.g. "1", "42") in DatasetValidator', () {
      final numericIdPayload = [
        {
          "id": "42", // Plain numeric ID
          "question": "Sample Question",
          "options": ["Option A", "Option B"],
          "correctAnswer": "Option A"
        }
      ];

      final report = DatasetValidator.validateQuestions(numericIdPayload);
      expect(report.hasErrors, isTrue);
      expect(
        report.errors.any((e) => e.message.contains('Plain numeric ID')),
        isTrue,
      );
    });

    test('Validates stable structured IDs in DatasetValidator', () {
      final stableIdPayload = [
        {
          "id": "UPSC_PRE_GS1_2025_Q001",
          "question": "Sample Question",
          "options": ["Option A", "Option B"],
          "correctAnswer": "Option A",
          "explanations": [
            {"content": "Exp text"}
          ]
        }
      ];

      final report = DatasetValidator.validateQuestions(stableIdPayload);
      expect(report.hasErrors, isFalse);
      expect(report.isValid, isTrue);
    });
  });

  group('Cross-Entity Reference Stability & Search Tests', () {
    late InMemoryQuestionRepository questionRepo;

    setUp(() {
      questionRepo = InMemoryQuestionRepository();
    });

    test('Cross-entity models consistently reference stable Question ID', () {
      const stableQuestionId = 'UPSC_PRE_GS1_2025_Q005';

      final question = Question(
        id: stableQuestionId,
        exam: 'UPSC CSE Prelims',
        year: 2025,
        paper: 'GS Paper 1',
        subject: 'Polity',
        topic: 'Preamble',
        difficulty: 'Medium',
        question: 'Preamble question',
        options: ['A', 'B'],
        correctAnswer: 'A',
      );

      final explanation = Explanation(
        explanationId: '${stableQuestionId}_exp_official',
        questionId: stableQuestionId,
        explanationType: 'Official',
        content: 'Explanation text',
        source: 'Key',
      );

      final attempt = QuestionAttempt(
        attemptId: 'att_101',
        questionId: stableQuestionId,
        userSelectedAnswer: 'A',
        isCorrect: true,
      );

      final bookmark = Bookmark(
        bookmarkId: stableQuestionId,
        questionId: stableQuestionId,
      );

      final userNote = UserNote(
        noteId: 'note_101',
        questionId: stableQuestionId,
        content: 'My personal polity note',
      );

      final statistics = QuestionStatistics(
        questionId: stableQuestionId,
        totalAttempts: 1,
        correctAttempts: 1,
      );

      // Verify all entities maintain references to the exact stable ID
      expect(question.id, equals(stableQuestionId));
      expect(explanation.questionId, equals(stableQuestionId));
      expect(attempt.questionId, equals(stableQuestionId));
      expect(bookmark.questionId, equals(stableQuestionId));
      expect(userNote.questionId, equals(stableQuestionId));
      expect(statistics.questionId, equals(stableQuestionId));
    });

    test('Lookup by stable Question ID in QuestionRepository', () async {
      const targetId = 'UPSC_PRE_GS1_2024_Q012';

      await questionRepo.saveQuestion(Question(
        id: targetId,
        exam: 'UPSC CSE Prelims',
        year: 2024,
        paper: 'GS Paper 1',
        subject: 'Economy',
        topic: 'Banking',
        difficulty: 'Hard',
        question: 'RBI Inflation Targeting',
        options: ['Price stability', 'Exchange rate'],
        correctAnswer: 'Price stability',
      ));

      final retrieved = await questionRepo.getQuestionById(targetId);
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals(targetId));
      expect(retrieved.subject, equals('Economy'));
    });
  });
}
