import 'package:flutter_test/flutter_test.dart';
import 'package:titan_ai_tutor/titan_ai_tutor.dart';

void main() {
  group('Misconception Detection Tests', () {
    late TutorEngine engine;
    late TutorConcept concept;

    setUp(() {
      engine = const TutorEngine();
      concept = const TutorConcept(
        id: 'c1',
        title: 'Emergency Provisions',
        description: 'Articles 352, 356, 360',
        subjectCategory: 'Polity',
        prerequisiteConceptIds: [],
        relatedTopicIds: [],
      );
    });

    test('Detects absolutist overgeneralization misconception', () {
      final misconceptions = engine.detectMisconceptions(
        studentResponse:
            'Emergency always suspends all fundamental rights automatically.',
        concept: concept,
      );

      expect(misconceptions, hasLength(greaterThanOrEqualTo(1)));
      expect(misconceptions.first, contains('Absolutist assumption'));
    });

    test('Detects incomplete reasoning when answer is too brief', () {
      final misconceptions = engine.detectMisconceptions(
        studentResponse: 'Short',
        concept: concept,
      );

      expect(misconceptions.any((m) => m.contains('Incomplete reasoning')),
          isTrue);
    });

    test('Returns empty misconception list for thorough correct response', () {
      final misconceptions = engine.detectMisconceptions(
        studentResponse:
            'Articles 20 and 21 remain enforceable even during a National Emergency under Article 352 as amended by 44th Amendment.',
        concept: concept,
      );

      expect(misconceptions, isEmpty);
    });
  });
}
