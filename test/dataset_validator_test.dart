import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_upsc/models/validation_report.dart';
import 'package:quizforge_upsc/services/dataset_validator.dart';
import 'package:quizforge_upsc/services/generic_dataset_importer.dart';

import 'dataset_importer_test.dart'; // Re-use in-memory repository implementations

void main() {
  group('DatasetValidator Rules Unit Tests', () {
    test('Validates complete valid question payload with 0 errors', () {
      final questions = [
        {
          "id": "UPSC_PRE_GS1_2024_Q001",
          "exam": "UPSC CSE Prelims",
          "paper": "GS Paper 1",
          "year": 2024,
          "subject": "Polity",
          "topic": "Preamble",
          "difficulty": "Medium",
          "question": "Which statement regarding Preamble is correct?",
          "options": ["Statement A", "Statement B"],
          "correctAnswer": "Statement A",
          "explanations": [
            {
              "explanationId": "exp1",
              "explanationType": "Official",
              "content": "Preamble is integral part"
            }
          ]
        }
      ];

      final report = DatasetValidator.validateQuestions(questions);
      expect(report.totalQuestions, equals(1));
      expect(report.validQuestionsCount, equals(1));
      expect(report.invalidQuestionsCount, equals(0));
      expect(report.isValid, isTrue);
      expect(report.hasErrors, isFalse);
      expect(report.warnings, isEmpty);
    });

    test('Detects duplicate Question IDs', () {
      final questions = [
        {
          "id": "dup_q1",
          "question": "Question 1",
          "options": ["A", "B"],
          "correctAnswer": "A"
        },
        {
          "id": "dup_q1", // Duplicate ID
          "question": "Question 2",
          "options": ["A", "B"],
          "correctAnswer": "A"
        }
      ];

      final report = DatasetValidator.validateQuestions(questions);
      expect(report.invalidQuestionsCount, equals(1));
      expect(report.hasErrors, isTrue);
      expect(
        report.errors.any((e) => e.message.contains('Duplicate question ID')),
        isTrue,
      );
    });

    test('Detects empty question text and empty options', () {
      final questions = [
        {
          "id": "q_empty_text",
          "question": "   ", // Empty question text
          "options": ["A", ""], // Option 2 is empty
          "correctAnswer": "A"
        }
      ];

      final report = DatasetValidator.validateQuestions(questions);
      expect(report.invalidQuestionsCount, equals(1));
      expect(report.errors.any((e) => e.field == 'question'), isTrue);
      expect(report.errors.any((e) => e.field.startsWith('options')), isTrue);
    });

    test('Detects non-existent correct answer', () {
      final questions = [
        {
          "id": "q_bad_answer",
          "question": "What is 2+2?",
          "options": ["3", "5"],
          "correctAnswer": "4" // Not in options
        }
      ];

      final report = DatasetValidator.validateQuestions(questions);
      expect(report.invalidQuestionsCount, equals(1));
      expect(
        report.errors.any(
            (e) => e.message.contains('does not match any available option')),
        isTrue,
      );
    });

    test('Detects invalid year range', () {
      final questions = [
        {
          "id": "q_bad_year",
          "year": 1800, // Year too early (< 1950)
          "question": "Sample question",
          "options": ["A", "B"],
          "correctAnswer": "A"
        }
      ];

      final report = DatasetValidator.validateQuestions(questions);
      expect(report.invalidQuestionsCount, equals(1));
      expect(report.errors.any((e) => e.field == 'year'), isTrue);
    });

    test('Generates warning when explanation is missing', () {
      final questions = [
        {
          "id": "q_no_exp",
          "year": 2024,
          "question": "Question text",
          "options": ["Option 1", "Option 2"],
          "correctAnswer": "Option 1"
          // No explanation provided
        }
      ];

      final report = DatasetValidator.validateQuestions(questions);
      expect(report.validQuestionsCount,
          equals(1)); // Valid for import, but has warning
      expect(report.hasWarnings, isTrue);
      expect(
        report.warnings.any((w) => w.message.contains('missing explanation')),
        isTrue,
      );
    });

    test('Generates structured ValidationReport summary text', () {
      final questions = [
        {
          "id": "valid_1",
          "question": "Valid Q",
          "options": ["A", "B"],
          "correctAnswer": "A",
          "explanations": [
            {"content": "exp"}
          ]
        },
        {
          "id": "invalid_1",
          "question": "", // Error
          "options": ["A"], // Error < 2 options
          "correctAnswer": "Z" // Error bad answer
        }
      ];

      final report = DatasetValidator.validateQuestions(questions);
      final summaryText = report.generateSummaryText();

      expect(summaryText, contains('Import Summary'));
      expect(summaryText, contains('2 Questions'));
      expect(summaryText, contains('1 Valid'));
      expect(summaryText, contains('1 Invalid'));
      expect(summaryText, contains('Errors:'));
    });
  });

  group('Importer Failure Handling Modes (Strict vs Safe)', () {
    late InMemoryExamRepository examRepo;
    late InMemoryQuestionRepository questionRepo;
    late InMemoryExplanationRepository explanationRepo;
    late InMemoryDatasetRepository datasetRepo;
    late GenericDatasetImporter importer;

    setUp(() {
      examRepo = InMemoryExamRepository();
      questionRepo = InMemoryQuestionRepository();
      explanationRepo = InMemoryExplanationRepository();
      datasetRepo = InMemoryDatasetRepository();

      importer = GenericDatasetImporter(
        examRepository: examRepo,
        questionRepository: questionRepo,
        explanationRepository: explanationRepo,
        datasetRepository: datasetRepo,
      );
    });

    final mixedQuestionsPayload = [
      {
        "id": "q_valid_1",
        "question": "Valid Question 1",
        "options": ["A", "B"],
        "correctAnswer": "A"
      },
      {
        "id": "q_invalid_2",
        "question": "", // Invalid empty question
        "options": ["A", "B"],
        "correctAnswer": "A"
      },
      {
        "id": "q_valid_3",
        "question": "Valid Question 3",
        "options": ["Option 1", "Option 2"],
        "correctAnswer": "Option 1"
      }
    ];

    test('Strict Mode stops and throws exception when errors exist', () async {
      final jsonStr = jsonEncode(mixedQuestionsPayload);

      expect(
        () =>
            importer.importDatasetJson(jsonStr, importMode: ImportMode.strict),
        throwsA(isA<DatasetValidationException>().having(
          (e) => e.message,
          'message',
          contains('Strict Import Mode failed'),
        )),
      );

      // Verify zero questions were imported into repository
      final saved = await questionRepo.getAllQuestions();
      expect(saved, isEmpty);
    });

    test('Safe Mode skips invalid questions and imports valid questions only',
        () async {
      final jsonStr = jsonEncode(mixedQuestionsPayload);

      final importedCount = await importer.importDatasetJson(
        jsonStr,
        importMode: ImportMode.safe,
      );

      expect(importedCount, equals(2)); // Only the 2 valid questions imported

      final saved = await questionRepo.getAllQuestions();
      expect(saved.length, equals(2));
      expect(saved.any((q) => q.id == 'q_valid_1'), isTrue);
      expect(saved.any((q) => q.id == 'q_valid_3'), isTrue);
      expect(saved.any((q) => q.id == 'q_invalid_2'), isFalse); // Skipped!

      // Verify validation report is accessible
      expect(importer.lastValidationReport, isNotNull);
      expect(importer.lastValidationReport!.invalidQuestionsCount, equals(1));
    });
  });
}
