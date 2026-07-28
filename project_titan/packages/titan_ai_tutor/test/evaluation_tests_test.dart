import 'package:flutter_test/flutter_test.dart';
import 'package:titan_ai_tutor/titan_ai_tutor.dart';

void main() {
  group('Evaluation Core Tests', () {
    late TutorEngine engine;
    late TutorConcept concept;
    late TutorExercise exercise;

    setUp(() {
      engine = const TutorEngine();
      concept = const TutorConcept(
        id: 'c1',
        title: 'Preamble of the Constitution',
        description: 'Key objectives and ideals',
        subjectCategory: 'Polity',
        prerequisiteConceptIds: [],
        relatedTopicIds: [],
      );

      exercise = const TutorExercise(
        id: 'ex1',
        conceptId: 'c1',
        title: 'Preamble Analysis',
        prompt: 'Explain the term Sovereign in the Preamble.',
      );
    });

    test('Evaluates strong response with high score and mastered grade', () {
      final eval = engine.evaluateAnswer(
        exercise: exercise,
        studentResponse:
            'Sovereign means India is internally supreme and externally independent, free from foreign control.',
        concept: concept,
      );

      expect(eval.score, greaterThanOrEqualTo(85.0));
      expect(eval.masteredConcepts, contains('c1'));
      expect(eval.feedbackText, contains('Great job'));
    });

    test('Evaluates flawed response with lower score and recommendations', () {
      final eval = engine.evaluateAnswer(
        exercise: exercise,
        studentResponse: 'Sovereign means always obeying international bodies.',
        concept: concept,
      );

      expect(eval.score, lessThan(85.0));
      expect(eval.detectedMisconceptions, isNotEmpty);
      expect(eval.recommendations, isNotEmpty);
    });
  });
}
