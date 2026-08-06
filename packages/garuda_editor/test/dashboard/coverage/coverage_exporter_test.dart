import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_editor/dashboard/coverage/garuda_coverage_dashboard.dart';
import 'package:garuda_pyq/garuda_pyq.dart' hide CoverageReport;

void main() {
  group('CoverageExporter Unit Tests', () {
    late CoverageReport testReport;

    setUp(() {
      final sampleQuestions = [
        Question(
          id: 'Q001',
          examId: 'upsc_cse',
          year: 2024,
          stage: 'Prelims',
          paper: 'GS1',
          subject: 'Polity',
          topic: 'Fundamental Rights',
          originalQuestion: 'Which article guarantees freedom of speech?',
          options: const [
            Option(key: 'A', text: 'Article 19', isCorrect: true),
          ],
          officialAnswer: const Answer(correctOptionKeys: ['A']),
          source: QuestionSource(
            sourceType: SourceType.officialWebsite,
            publisher: 'UPSC CSE 2024',
            retrievedDate: DateTime(2024),
            checksum: 'chk1',
          ),
          verificationStatus: 'Verified',
          editorialStatus: EditorialStatus.published,
          trap: const QuestionTrap(
            id: 't1',
            questionId: 'Q001',
            trapType: 'Tricky Wording',
            commonMistake: 'Conflating 19 and 21',
            expectedThinking: '',
            wrongEliminationStrategy: '',
            correctEliminationStrategy: '',
          ),
          learningObjectives: const LearningObjectives(studentShouldBeAbleTo: ['Understand Article 19']),
          knowledgeObjectLinks: const ['KO_POLITY_001'],
          articleLinks: const ['Article 19'],
          conceptsTested: const ['Freedom of Speech'],
        ),
      ];

      testReport = CoverageCalculator.calculateReport(sampleQuestions);
    });

    test('exportToCsv produces valid CSV string with all section headers', () {
      final csv = CoverageExporter.exportToCsv(testReport);

      expect(csv, contains('# GARUDA EDITORIAL COVERAGE REPORT'));
      expect(csv, contains('--- NATIONAL OVERVIEW ---'));
      expect(csv, contains('--- EXAM COVERAGE ---'));
      expect(csv, contains('--- SUBJECT COVERAGE ---'));
      expect(csv, contains('--- TOPIC COVERAGE ---'));
      expect(csv, contains('--- YEAR MATRIX ---'));
      expect(csv, contains('--- EDITORIAL QUEUE ---'));
      expect(csv, contains('--- KNOWLEDGE GRAPH STATUS ---'));
      expect(csv, contains('--- QUALITY DASHBOARD ---'));
      expect(csv, contains('UPSC_CSE'));
      expect(csv, contains('Polity'));
    });

    test('exportToJson produces valid formatted JSON string', () {
      final jsonStr = CoverageExporter.exportToJson(testReport);

      expect(jsonStr, contains('"nationalOverview"'));
      expect(jsonStr, contains('"examCoverage"'));
      expect(jsonStr, contains('"subjectCoverage"'));
      expect(jsonStr, contains('"qualityDashboard"'));
      expect(jsonStr, contains('"coveragePercentage"'));
    });

    test('exportToMarkdown produces clean GitHub Flavored Markdown summary', () {
      final md = CoverageExporter.exportToMarkdown(testReport);

      expect(md, contains('# 🛡️ GARUDA Editorial Coverage Dashboard Summary'));
      expect(md, contains('## 1. National Overview'));
      expect(md, contains('## 2. Exam Coverage'));
      expect(md, contains('## 3. Subject Coverage'));
      expect(md, contains('## 4. Topic Coverage'));
      expect(md, contains('## 5. Year Matrix Overview'));
      expect(md, contains('## 6. Editorial Queue'));
      expect(md, contains('## 7. Knowledge Graph Status'));
      expect(md, contains('## 8. Quality Dashboard'));
    });
  });
}
