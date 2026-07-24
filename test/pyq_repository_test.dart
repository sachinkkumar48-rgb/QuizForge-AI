import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_upsc/models/pyq_question_model.dart';
import 'package:quizforge_upsc/services/pyq_analytics_service.dart';
import 'package:quizforge_upsc/services/pyq_importer_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleJson = '''
  [
    {
      "id": "test_q1",
      "year": 2024,
      "exam": "UPSC CSE Prelims",
      "paper": "GS Paper 1",
      "subject": "Polity",
      "topic": "Preamble",
      "difficulty": "Easy",
      "question": "Preamble is part of Constitution?",
      "options": ["Yes", "No", "Maybe", "None"],
      "correctAnswer": "Yes",
      "officialAnswer": "A",
      "explanation": {
        "official": "Kesavananda Bharati case established this."
      },
      "reference": "NCERT Class 11",
      "isBookmarked": false,
      "timesAttempted": 0,
      "timesCorrect": 0,
      "tags": ["Polity"]
    },
    {
      "id": "test_q2",
      "year": 2023,
      "exam": "UPSC CSE Prelims",
      "paper": "GS Paper 1",
      "subject": "Economy",
      "topic": "Banking",
      "difficulty": "Medium",
      "question": "What is Repo Rate?",
      "options": ["Rate RBI lends to banks", "Rate banks lend to RBI", "Tax rate", "Interest on savings"],
      "correctAnswer": "Rate RBI lends to banks",
      "officialAnswer": "A",
      "explanation": {
        "official": "Repo rate is key policy rate."
      },
      "reference": "RBI Website",
      "isBookmarked": true,
      "timesAttempted": 1,
      "timesCorrect": 0,
      "tags": ["Economy"]
    }
  ]
  ''';

  group('PyqImporterService Tests', () {
    test('parseDatasetJson correctly parses valid JSON array', () {
      final questions = PyqImporterService.parseDatasetJson(sampleJson);
      expect(questions.length, equals(2));
      expect(questions[0].id, equals("test_q1"));
      expect(questions[0].subject, equals("Polity"));
      expect(questions[1].isBookmarked, isTrue);
    });

    test('parseDatasetJson throws FormatException for invalid JSON', () {
      expect(
        () => PyqImporterService.parseDatasetJson('{"key": "value"}'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('PyqAnalyticsService Tests', () {
    test('computeAnalytics correctly aggregates statistics', () {
      final questions = PyqImporterService.parseDatasetJson(sampleJson);
      final analytics = PyqAnalyticsService.computeAnalytics(questions);

      expect(analytics.totalQuestions, equals(2));
      expect(analytics.totalAttempted, equals(1));
      expect(analytics.totalCorrect, equals(0));
      expect(analytics.totalBookmarked, equals(1));
      expect(analytics.totalIncorrectBank, equals(1));
      expect(analytics.overallAccuracyPercent, equals(0.0));

      expect(analytics.weakSubjects.contains("Economy"), isTrue);
    });
  });

  group('PyqQuestionModel Serialization Tests', () {
    test('PyqQuestionModel copyWith updates fields correctly', () {
      final q = PyqQuestionModel(
        id: "q1",
        year: 2024,
        exam: "UPSC CSE Prelims",
        paper: "GS Paper 1",
        subject: "Polity",
        topic: "Preamble",
        difficulty: "Easy",
        question: "Sample Question",
        options: ["A", "B", "C", "D"],
        correctAnswer: "A",
        officialAnswer: "A",
        explanation: PyqExplanation(official: "Official test explanation"),
        reference: "NCERT",
      );

      final bookmarked = q.copyWith(isBookmarked: true);
      expect(bookmarked.isBookmarked, isTrue);
      expect(bookmarked.id, equals("q1"));

      final attempted = q.copyWith(
        timesAttempted: 1,
        timesCorrect: 1,
        userSelectedAnswer: "A",
      );
      expect(attempted.isAttempted, isTrue);
      expect(attempted.isLastAttemptCorrect, isTrue);
      expect(attempted.accuracy, equals(100.0));
    });
  });
}
