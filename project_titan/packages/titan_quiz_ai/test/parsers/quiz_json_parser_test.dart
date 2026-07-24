import 'package:test/test.dart';
import 'package:titan_quiz/titan_quiz.dart';
import 'package:titan_quiz_ai/titan_quiz_ai.dart';

void main() {
  group('QuizJsonParser Extraction and Mapping Tests', () {
    const parser = QuizJsonParser();

    test('extractJsonMap extracts JSON object from raw markdown codeblock', () {
      const rawText = '''
Here is the generated quiz:
```json
{
  "title": "History Quiz",
  "questions": [
    {
      "question": "When was the Battle of Plassey fought?",
      "options": ["1757", "1764", "1857", "1947"],
      "correctAnswer": 0
    }
  ]
}
```
Hope this helps!
''';

      final map = parser.extractJsonMap(rawText);
      expect(map['title'], equals('History Quiz'));
      expect((map['questions'] as List).length, equals(1));
    });

    test('extractJsonMap throws JsonParsingException on invalid JSON string',
        () {
      const badJson = 'This is not JSON at all';
      expect(() => parser.extractJsonMap(badJson),
          throwsA(isA<JsonParsingException>()));
    });

    test('parseQuiz converts decoded map to canonical Quiz entity', () {
      final request = QuizGenerationRequest(
        documentId: 'doc_history_1',
        category: QuizCategory.upsc,
        difficulty: QuizDifficulty.medium,
        language: QuizLanguage.english,
      );

      final map = {
        'title': 'Modern Indian History Mock',
        'description': 'Covering freedom struggle',
        'questions': [
          {
            'question': 'Who founded the Brahmo Samaj?',
            'options': [
              'Raja Ram Mohan Roy',
              'Swami Vivekananda',
              'Dayananda Saraswati',
              'Ishwar Chandra Vidyasagar'
            ],
            'correctAnswer': 0,
            'explanation': 'Raja Ram Mohan Roy founded Brahmo Samaj in 1828.',
            'topic': 'Social Reform Movements',
            'difficulty': 'medium',
          }
        ]
      };

      final quiz = parser.parseQuiz(map: map, request: request);

      expect(quiz.title, equals('Modern Indian History Mock'));
      expect(quiz.sourceDocumentId, equals('doc_history_1'));
      expect(quiz.category, equals(QuizCategory.upsc));
      expect(quiz.difficulty, equals(QuizDifficulty.medium));
      expect(quiz.questions.length, equals(1));

      final q = quiz.questions.first;
      expect(q.question, equals('Who founded the Brahmo Samaj?'));
      expect(q.options.length, equals(4));
      expect(q.correctAnswerIndex, equals(0));
      expect(q.options[0].isCorrect, isTrue);
      expect(q.options[1].isCorrect, isFalse);
      expect(q.marks, equals(2.0)); // UPSC default marks
      expect(q.negativeMarks, equals(0.66)); // UPSC default negative marks
    });
  });
}
