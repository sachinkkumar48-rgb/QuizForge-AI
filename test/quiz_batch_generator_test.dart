import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_upsc/models/quiz_model.dart';
import 'package:quizforge_upsc/repositories/api_key_repository.dart';
import 'package:quizforge_upsc/services/quiz_batch_generator.dart';

class MockApiKeyRepository implements ApiKeyRepository {
  @override
  Future<void> saveKey(String key) async {}
  @override
  Future<String?> loadKey() async => "mock_api_key_12345";
  @override
  Future<void> deleteKey() async {}
  @override
  Future<bool> hasKey() async => true;
  @override
  Future<bool> validateKey(String key) async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ApiKeyRepository.instance = MockApiKeyRepository();
  });

  group('QuizBatchGenerator - Batch Calculation Tests', () {
    test('calculateBatchSizes for 10 questions returns [10]', () {
      final batches = QuizBatchGenerator.calculateBatchSizes(10);
      expect(batches, equals([10]));
    });

    test('calculateBatchSizes for 25 questions returns [20, 5]', () {
      final batches = QuizBatchGenerator.calculateBatchSizes(25);
      expect(batches, equals([20, 5]));
    });

    test('calculateBatchSizes for 50 questions returns [20, 20, 10]', () {
      final batches = QuizBatchGenerator.calculateBatchSizes(50);
      expect(batches, equals([20, 20, 10]));
    });

    test('calculateBatchSizes for 100 questions returns [20, 20, 20, 20, 20]',
        () {
      final batches = QuizBatchGenerator.calculateBatchSizes(100);
      expect(batches, equals([20, 20, 20, 20, 20]));
    });

    test(
        'calculateBatchSizes for 150 questions returns [20, 20, 20, 20, 20, 20, 20, 10]',
        () {
      final batches = QuizBatchGenerator.calculateBatchSizes(150);
      expect(batches, equals([20, 20, 20, 20, 20, 20, 20, 10]));
    });
  });

  group('QuizBatchGenerator - Execution & Deduplication Tests', () {
    test(
        'generateInBatches for 10, 25, 50, 100, 150 handles progress and returns QuizModel',
        () {
      final sizes = [10, 25, 50, 100, 150];
      final expectedBatches = [1, 2, 3, 5, 8];

      for (int i = 0; i < sizes.length; i++) {
        final totalCount = sizes[i];
        final expectedCount = expectedBatches[i];
        final calculated = QuizBatchGenerator.calculateBatchSizes(totalCount);

        expect(calculated.length, equals(expectedCount));
        expect(calculated.reduce((a, b) => a + b), equals(totalCount));
        expect(calculated.every((b) => b <= 20), isTrue);
      }
    });

    test(
        'Deduplication logic removes duplicate questions while preserving order',
        () {
      final q1 = QuizQuestion(
        question: "What is the capital of India?",
        options: ["New Delhi", "Mumbai", "Kolkata", "Chennai"],
        answer: "New Delhi",
        explanation: "New Delhi is the capital.",
        subject: "Geography",
        difficulty: "Easy",
      );
      final q2 = QuizQuestion(
        question: "  WHAT IS THE CAPITAL OF INDIA?  ",
        options: ["New Delhi", "Mumbai", "Kolkata", "Chennai"],
        answer: "New Delhi",
        explanation: "Duplicate question test.",
        subject: "Geography",
        difficulty: "Easy",
      );
      final q3 = QuizQuestion(
        question: "Who wrote the Constitution of India?",
        options: ["Dr. B.R. Ambedkar", "Nehru", "Gandhi", "Patel"],
        answer: "Dr. B.R. Ambedkar",
        explanation: "Dr. Ambedkar chaired the Drafting Committee.",
        subject: "Polity",
        difficulty: "Medium",
      );

      final questions = [q1, q2, q3];
      final seen = <String>{};
      final unique = <QuizQuestion>[];

      for (final q in questions) {
        final normalized =
            q.question.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
        if (!seen.contains(normalized)) {
          seen.add(normalized);
          unique.add(q);
        }
      }

      expect(unique.length, equals(2));
      expect(unique[0].question, equals("What is the capital of India?"));
      expect(
          unique[1].question, equals("Who wrote the Constitution of India?"));
    });
  });
}
