import 'package:flutter_test/flutter_test.dart';
import 'package:titan_ai_tutor/titan_ai_tutor.dart';

void main() {
  group('Tutor Models Unit Tests', () {
    test('TutorConcept serialization and copyWith', () {
      const concept = TutorConcept(
        id: 'c1',
        title: 'Fundamental Rights',
        description: 'Part III of Indian Constitution',
        subjectCategory: 'Polity',
        prerequisiteConceptIds: ['p1'],
        relatedTopicIds: ['r1'],
        userMasteryScore: 75.0,
      );

      final json = concept.toJson();
      final restored = TutorConcept.fromJson(json);

      expect(restored.id, equals('c1'));
      expect(restored.title, equals('Fundamental Rights'));
      expect(restored.userMasteryScore, equals(75.0));
      expect(restored, equals(concept));

      final updated = concept.copyWith(userMasteryScore: 90.0);
      expect(updated.userMasteryScore, equals(90.0));
      expect(updated.id, equals('c1'));
    });

    test('TutorSession serialization and copyWith', () {
      final now = DateTime.now();
      final session = TutorSession(
        id: 's1',
        learnerId: 'u1',
        conceptId: 'c1',
        status: TutorSessionStatus.active,
        persona: TutorPersona.upscMode,
        startedAt: now,
        updatedAt: now,
      );

      final json = session.toJson();
      final restored = TutorSession.fromJson(json);

      expect(restored.id, equals('s1'));
      expect(restored.persona, equals(TutorPersona.upscMode));
      expect(restored.status, equals(TutorSessionStatus.active));

      final completed = session.copyWith(status: TutorSessionStatus.completed);
      expect(completed.status, equals(TutorSessionStatus.completed));
    });

    test('TutorQuestion and TutorExercise models', () {
      const question = TutorQuestion(
        id: 'q1',
        conceptId: 'c1',
        questionText: 'What is Article 21?',
        type: TutorQuestionType.openEnded,
        correctAnswer: 'Right to Life and Personal Liberty',
        explanation: 'Guarantees protection of life.',
      );

      expect(question.id, equals('q1'));
      expect(question.type, equals(TutorQuestionType.openEnded));

      const exercise = TutorExercise(
        id: 'e1',
        conceptId: 'c1',
        title: 'Exercise 1',
        prompt: 'Analyze Article 21',
      );

      expect(exercise.id, equals('e1'));
      expect(exercise.status, equals(TutorExerciseStatus.pending));
    });

    test('TutorHint, TutorFeedback, TutorEvaluation, TutorMemory, TutorGoal',
        () {
      const hint = TutorHint(
        id: 'h1',
        exerciseId: 'e1',
        hintText: 'Think about personal liberty',
        hintLevel: 1,
      );
      expect(hint.hintLevel, equals(1));

      final feedback = TutorFeedback(
        id: 'f1',
        isPositive: true,
        rating: 5,
        comment: 'Excellent answer',
        timestamp: DateTime.now(),
      );
      expect(feedback.rating, equals(5));

      final eval = TutorEvaluation(
        id: 'ev1',
        targetId: 'e1',
        score: 88.0,
        grade: EvaluationGrade.excellent,
        feedbackText: 'Strong response',
        evaluatedAt: DateTime.now(),
      );
      expect(eval.score, equals(88.0));

      final memory = TutorMemory(
        id: 'm1',
        userId: 'u1',
        conceptId: 'c1',
        strengths: const ['Analytical Depth'],
        lastInteractedAt: DateTime.now(),
      );
      expect(memory.strengths, contains('Analytical Depth'));

      final goal = TutorGoal(
        id: 'g1',
        userId: 'u1',
        title: 'Master Polity',
        description: 'Complete all Polity concepts',
        targetConceptIds: const ['c1'],
        targetDate: DateTime.now().add(const Duration(days: 7)),
      );
      expect(goal.title, equals('Master Polity'));
    });
  });
}
