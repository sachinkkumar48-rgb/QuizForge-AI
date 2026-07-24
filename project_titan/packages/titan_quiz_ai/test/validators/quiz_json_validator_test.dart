import 'package:test/test.dart';
import 'package:titan_quiz_ai/titan_quiz_ai.dart';

void main() {
  group('QuizJsonValidator Schema Rules Tests', () {
    const validator = QuizJsonValidator();

    Map<String, dynamic> validJsonMap() {
      return {
        'title': 'Polity Mock Quiz',
        'description': 'Test description',
        'questions': [
          {
            'question': 'What is Article 14?',
            'options': [
              'Equality before law',
              'Right to freedom',
              'Right to religion',
              'Right to remedies'
            ],
            'correctAnswer': 0,
            'explanation': 'Article 14 guarantees equality before law.',
            'topic': 'Fundamental Rights',
            'difficulty': 'medium'
          }
        ]
      };
    }

    test('Passes validation for a valid JSON map', () {
      final errors = validator.validateQuizJson(validJsonMap());
      expect(errors, isEmpty);
      expect(() => validator.validateQuizJsonOrThrow(validJsonMap()),
          returnsNormally);
    });

    test('Fails when top-level title is missing or empty', () {
      final invalid = validJsonMap()..remove('title');
      final errors = validator.validateQuizJson(invalid);
      expect(
          errors,
          contains(
              contains('missing required non-empty string field "title"')));
    });

    test('Fails when questions list is empty or missing', () {
      final invalid = validJsonMap()..['questions'] = <dynamic>[];
      final errors = validator.validateQuizJson(invalid);
      expect(
          errors,
          contains(
              contains('missing required non-empty list field "questions"')));
    });

    test('Fails when a question has fewer than 2 options', () {
      final invalid = validJsonMap();
      invalid['questions'] = <dynamic>[
        {
          'question': 'Sample Q',
          'options': <String>['Single Option'],
          'correctAnswer': 0,
        }
      ];

      final errors = validator.validateQuizJson(invalid);
      expect(errors, contains(contains('Must contain at least 2 options')));
    });

    test('Fails when duplicate options are present in a question', () {
      final invalid = validJsonMap();
      invalid['questions'] = <dynamic>[
        {
          'question': 'Sample Q',
          'options': <String>['Option A', 'Option A'],
          'correctAnswer': 0,
        }
      ];

      final errors = validator.validateQuizJson(invalid);
      expect(errors, contains(contains('Duplicate option found: "Option A"')));
    });

    test('Fails when correctAnswer index is out of bounds', () {
      final invalid = validJsonMap();
      (invalid['questions'] as List<dynamic>)[0]['correctAnswer'] = 10;

      final errors = validator.validateQuizJson(invalid);
      expect(errors,
          contains(contains('correctAnswer index (10) is out of bounds')));
    });

    test(
        'Throws JsonValidationException when calling validateQuizJsonOrThrow on bad map',
        () {
      final invalid = validJsonMap()..remove('title');
      expect(
        () => validator.validateQuizJsonOrThrow(invalid),
        throwsA(isA<JsonValidationException>()),
      );
    });
  });
}
