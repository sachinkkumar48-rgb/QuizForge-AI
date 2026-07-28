import 'package:flutter_test/flutter_test.dart';
import 'package:titan_ai_tutor/titan_ai_tutor.dart';

void main() {
  group('TutorEngine Pure Dart Core Tests', () {
    late TutorEngine engine;
    late TutorConcept sampleConcept;

    setUp(() {
      engine = const TutorEngine();
      sampleConcept = const TutorConcept(
        id: 'c_polity_21',
        title: 'Right to Life & Personal Liberty',
        description:
            'Article 21 guarantees protection of life and personal liberty.',
        subjectCategory: 'Indian Polity',
        prerequisiteConceptIds: ['c_polity_fundamental_rights'],
        relatedTopicIds: ['c_polity_judicial_review'],
      );
    });

    test('explainConcept generates persona-tailored lesson', () {
      final eli5Lesson = engine.explainConcept(
        concept: sampleConcept,
        persona: TutorPersona.eli5,
      );
      expect(eli5Lesson.explanation, contains('game'));
      expect(eli5Lesson.estimatedDurationMinutes, equals(10));

      final upscLesson = engine.explainConcept(
        concept: sampleConcept,
        persona: TutorPersona.upscMode,
      );
      expect(upscLesson.explanation, contains('UPSC Mains'));
    });

    test('generateSocraticQuestion formulates guided questions', () {
      final question = engine.generateSocraticQuestion(
        concept: sampleConcept,
        difficulty: TutorDifficultyLevel.advanced,
      );

      expect(question.type, equals(TutorQuestionType.socratic));
      expect(question.questionText, contains('Right to Life'));
    });

    test('evaluateAnswer computes score and grade correctly', () {
      final exercise = TutorExercise(
        id: 'ex1',
        conceptId: sampleConcept.id,
        title: 'Exercise 1',
        prompt: 'Explain Article 21',
      );

      final eval = engine.evaluateAnswer(
        exercise: exercise,
        studentResponse:
            'Article 21 covers judicial review and fundamental freedom.',
        concept: sampleConcept,
      );

      expect(eval.score, greaterThanOrEqualTo(60.0));
      expect(eval.grade, isNot(equals(EvaluationGrade.needsImprovement)));
    });

    test('estimateMastery EWMA calculation', () {
      final updated = engine.estimateMastery(
        currentMastery: 50.0,
        newScore: 100.0,
      );
      // (50 * 0.7) + (100 * 0.3) = 35 + 30 = 65
      expect(updated, equals(65.0));
    });

    test('checkPrerequisites identifies missing concept prerequisites', () {
      final missing = engine.checkPrerequisites(
        concept: sampleConcept,
        userMasteries: {'c_polity_fundamental_rights': 40.0},
        requiredThreshold: 60.0,
      );

      expect(missing, contains('c_polity_fundamental_rights'));
    });
  });
}
