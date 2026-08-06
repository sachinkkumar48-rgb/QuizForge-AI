import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_editor/dashboard/coverage/garuda_coverage_dashboard.dart';
import 'package:garuda_pyq/garuda_pyq.dart' hide CoverageReport;

void main() {
  group('CoverageCalculator Unit Tests', () {
    late List<Question> sampleQuestions;

    setUp(() {
      sampleQuestions = [
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
            Option(key: 'B', text: 'Article 21', isCorrect: false),
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
        Question(
          id: 'Q002',
          examId: 'bpsc',
          year: 2023,
          stage: 'Prelims',
          paper: 'GS1',
          subject: 'History',
          topic: 'Ancient India',
          originalQuestion: 'Where was Buddha born?',
          options: const [
            Option(key: 'A', text: 'Lumbini', isCorrect: true),
            Option(key: 'B', text: 'Sarnath', isCorrect: false),
          ],
          officialAnswer: const Answer(correctOptionKeys: ['A']),
          source: QuestionSource(
            sourceType: SourceType.editorialEntry,
            publisher: 'BPSC 2023',
            retrievedDate: DateTime(2023),
            checksum: 'chk2',
          ),
          verificationStatus: 'Pending',
          editorialStatus: EditorialStatus.imported,
        ),
        Question(
          id: 'Q003',
          examId: 'cds',
          year: 2022,
          stage: 'Written',
          paper: 'GS',
          subject: 'Geography',
          topic: 'Physical Geography',
          originalQuestion: 'What is the capital of India?',
          options: const [
            Option(key: 'A', text: 'New Delhi', isCorrect: true),
          ],
          officialAnswer: const Answer(correctOptionKeys: ['A']),
          source: QuestionSource(
            sourceType: SourceType.officialPdf,
            publisher: 'CDS 2022',
            retrievedDate: DateTime(2022),
            checksum: 'chk3',
          ),
          verificationStatus: 'Verified',
          editorialStatus: EditorialStatus.verified,
          conceptsTested: const ['Indian Geography'],
        ),
      ];
    });

    test('calculateReport generates accurate National Overview metrics', () {
      final report = CoverageCalculator.calculateReport(sampleQuestions);
      final n = report.nationalOverview;

      expect(n.totalQuestions, equals(3));
      expect(n.verifiedQuestions, equals(2)); // Q001 and Q003 are verified
      expect(n.publishedQuestions, equals(1)); // Q001 is published
      expect(n.goldQuestions, equals(1)); // Q001 is Gold
      expect(n.silverQuestions, equals(1)); // Q003 is Silver
      expect(n.draftQuestions, equals(1)); // Q002 is Draft
      expect(n.coveragePercentage, equals(66.7));
    });

    test('calculateReport computes Exam Coverage accurately', () {
      final report = CoverageCalculator.calculateReport(sampleQuestions);
      final upscItem = report.examCoverage.firstWhere((e) => e.examId == 'upsc_cse');
      final bpscItem = report.examCoverage.firstWhere((e) => e.examId == 'bpsc');

      expect(upscItem.questionsImported, equals(1));
      expect(upscItem.questionsVerified, equals(1));
      expect(upscItem.yearsCovered, equals(1));

      expect(bpscItem.questionsImported, equals(1));
      expect(bpscItem.questionsVerified, equals(0));
    });

    test('calculateReport computes Subject Coverage accurately', () {
      final report = CoverageCalculator.calculateReport(sampleQuestions);
      final polity = report.subjectCoverage.firstWhere((s) => s.subject == 'Polity');
      final history = report.subjectCoverage.firstWhere((s) => s.subject == 'History');

      expect(polity.imported, equals(1));
      expect(polity.verified, equals(1));
      expect(polity.published, equals(1));
      expect(polity.coveragePercentage, equals(100.0));

      expect(history.imported, equals(1));
      expect(history.verified, equals(0));
      expect(history.coveragePercentage, equals(0.0));
    });

    test('calculateReport computes Topic Coverage accurately', () {
      final report = CoverageCalculator.calculateReport(sampleQuestions);
      final frTopic = report.topicCoverage.firstWhere((t) => t.topic == 'Fundamental Rights');

      expect(frTopic.questions, equals(1));
      expect(frTopic.coveragePercentage, equals(100.0));
      expect(frTopic.missing, equals(0));
    });

    test('calculateReport computes Year Matrix accurately (1995-2026)', () {
      final report = CoverageCalculator.calculateReport(sampleQuestions);
      expect(report.yearMatrix.length, equals(32));

      final year2024 = report.yearMatrix.firstWhere((y) => y.year == 2024);
      final year2023 = report.yearMatrix.firstWhere((y) => y.year == 2023);
      final year2000 = report.yearMatrix.firstWhere((y) => y.year == 2000);

      expect(year2024.status, equals(YearCoverageStatus.complete));
      expect(year2023.status, equals(YearCoverageStatus.partial));
      expect(year2000.status, equals(YearCoverageStatus.missing));
    });

    test('calculateReport calculates Knowledge Graph Status metrics', () {
      final report = CoverageCalculator.calculateReport(sampleQuestions);
      final kg = report.knowledgeGraph;

      expect(kg.questionsLinked, equals(2));
      expect(kg.articlesLinked, equals(1));
      expect(kg.knowledgeObjectsLinked, equals(1));
      expect(kg.conceptsLinked, equals(2));
    });

    test('calculateReport computes Quality Dashboard percentages accurately', () {
      final report = CoverageCalculator.calculateReport(sampleQuestions);
      final qd = report.qualityDashboard;

      expect(qd.trapAnalysisPercentage, equals(33.3));
      expect(qd.learningObjectivesPercentage, equals(33.3));
      expect(qd.conceptMappingPercentage, equals(66.7));
    });

    test('calculateReport handles empty question list gracefully', () {
      final report = CoverageCalculator.calculateReport([]);
      expect(report.nationalOverview.totalQuestions, equals(0));
      expect(report.nationalOverview.coveragePercentage, equals(0.0));
      expect(report.qualityDashboard.trapAnalysisPercentage, equals(0.0));
    });
  });
}
