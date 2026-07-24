import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_upsc/controllers/analytics_controller.dart';
import 'package:quizforge_upsc/models/analytics_engine_models.dart';
import 'package:quizforge_upsc/models/pyq_question_model.dart';
import 'package:quizforge_upsc/pages/analytics_dashboard_page.dart';
import 'package:quizforge_upsc/repositories/analytics_repository.dart';
import 'package:quizforge_upsc/services/analytics_exporter.dart';
import 'package:quizforge_upsc/services/analytics_service.dart';

class MemoryAnalyticsRepository implements AnalyticsRepository {
  final Map<String, AnalyticsSnapshot> _map = {};

  @override
  Future<void> saveSnapshot(AnalyticsSnapshot snapshot) async {
    _map[snapshot.snapshotId] = snapshot;
  }

  @override
  Future<List<AnalyticsSnapshot>> getSnapshots() async {
    final list = _map.values.toList();
    list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return list;
  }

  @override
  Future<AnalyticsSnapshot?> getLatestSnapshot() async {
    final list = await getSnapshots();
    return list.isNotEmpty ? list.last : null;
  }

  @override
  Future<void> deleteSnapshot(String snapshotId) async {
    _map.remove(snapshotId);
  }

  @override
  Future<void> clear() async {
    _map.clear();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AnalyticsService service;
  late MemoryAnalyticsRepository repository;
  late List<PyqQuestionModel> sampleQuestions;

  setUp(() {
    service = AnalyticsService();
    repository = MemoryAnalyticsRepository();

    sampleQuestions = [
      PyqQuestionModel(
        id: 'q1',
        year: 2024,
        exam: 'UPSC CSE',
        paper: 'GS Paper 1',
        subject: 'Polity',
        topic: 'Preamble',
        difficulty: 'Easy',
        question: 'Which word was added by 42nd Amendment?',
        options: ['Secular', 'Federal', 'Monarchy', 'Republic'],
        correctAnswer: 'Secular',
        officialAnswer: 'Secular',
        explanation: PyqExplanation(official: 'Official Explanation'),
        reference: 'Laxmikanth',
        timesAttempted: 10,
        timesCorrect: 8,
        isBookmarked: true,
        lastAttempted: DateTime.now(),
        userSelectedAnswer: 'Secular',
      ),
      PyqQuestionModel(
        id: 'q2',
        year: 2023,
        exam: 'UPSC CSE',
        paper: 'GS Paper 1',
        subject: 'History',
        topic: 'Ancient India',
        difficulty: 'Hard',
        question: 'Harappan script details',
        options: ['A', 'B', 'C', 'D'],
        correctAnswer: 'A',
        officialAnswer: 'A',
        explanation: PyqExplanation(official: 'Official Explanation'),
        reference: 'RS Sharma',
        timesAttempted: 4,
        timesCorrect:
            1, // 25% accuracy -> Weak Area with Low Confidence (<5 attempts)
        isBookmarked: false,
        lastAttempted: DateTime.now().subtract(const Duration(days: 1)),
        userSelectedAnswer: 'B',
      ),
      PyqQuestionModel(
        id: 'q3',
        year: 2022,
        exam: 'UPSC CSE',
        paper: 'GS Paper 1',
        subject: 'Economy',
        topic: 'Inflation',
        difficulty: 'Medium',
        question: 'CPI vs WPI',
        options: ['A', 'B', 'C', 'D'],
        correctAnswer: 'A',
        officialAnswer: 'A',
        explanation: PyqExplanation(official: 'Official Explanation'),
        reference: 'Ramesh Singh',
        timesAttempted: 18,
        timesCorrect:
            6, // ~33% accuracy -> Weak Area with High Confidence (>15 attempts)
        isBookmarked: true,
        lastAttempted: DateTime.now().subtract(const Duration(days: 2)),
        userSelectedAnswer: 'B',
      ),
    ];
  });

  group('Analytics Calculations - All 16 Tracking Metrics', () {
    test(
        'Computes overall, subject, topic, year, and difficulty metrics correctly',
        () {
      final insights = service.computeLearningInsights(sampleQuestions);

      expect(insights.overallAccuracy, greaterThan(0.0));
      expect(insights.subjectAccuracy.containsKey('Polity'), isTrue);
      expect(insights.subjectAccuracy['Polity']?.accuracyPercent, equals(80.0));

      expect(insights.topicAccuracy.containsKey('Ancient India'), isTrue);
      expect(insights.yearAccuracy.containsKey(2024), isTrue);
      expect(insights.difficultyAccuracy.containsKey('Hard'), isTrue);

      expect(insights.bookmarkCount, equals(2));
      expect(insights.incorrectQuestionCount, equals(2));
      expect(insights.questionAttemptFrequency['q1'], equals(10));
      expect(insights.dailyQuestionsSolved, equals(1));
    });

    test('Computes streaks and questions solved time windows', () {
      final insights = service.computeLearningInsights(sampleQuestions);
      expect(insights.currentStreak, greaterThanOrEqualTo(1));
      expect(insights.weeklyQuestionsSolved, equals(3));
      expect(insights.monthlyQuestionsSolved, equals(3));
    });
  });

  group('Weak Area Detection & Confidence Ratings', () {
    test(
        'Categorizes weak subjects, topics, difficulties, years with confidence levels',
        () {
      final insights = service.computeLearningInsights(sampleQuestions);

      final weakInsights = insights.weakAreaInsights;
      expect(weakInsights.isNotEmpty, isTrue);

      final lowConfWeak = weakInsights
          .firstWhere((w) => w.name == 'Ancient India' || w.name == 'History');
      expect(lowConfWeak.confidenceLevel, equals(ConfidenceLevel.low));

      final highConfWeak = weakInsights
          .firstWhere((w) => w.name == 'Economy' || w.name == 'Inflation');
      expect(highConfWeak.confidenceLevel, equals(ConfidenceLevel.high));
    });
  });

  group('Historical Performance Snapshots & Exporters', () {
    test('Generates and persists performance trend snapshots', () async {
      final insights = service.computeLearningInsights(sampleQuestions);
      final snapshot = service.createSnapshot(insights);

      await repository.saveSnapshot(snapshot);

      final retrieved = await repository.getSnapshots();
      expect(retrieved.length, equals(1));
      expect(retrieved.first.overallAccuracy, equals(insights.overallAccuracy));
    });

    test('AnalyticsExporter exports to JSON, CSV, and PDF Text Summary', () {
      final insights = service.computeLearningInsights(sampleQuestions);

      final jsonStr = AnalyticsExporter.exportToJson(insights);
      expect(jsonStr.contains('overallAccuracy'), isTrue);

      final csvStr = AnalyticsExporter.exportToCsv(insights);
      expect(csvStr.contains('Dimension,Name'), isTrue);

      final pdfStr = AnalyticsExporter.exportToPdfTextReport(insights);
      expect(pdfStr.contains('QUIZFORGE AI LEARNING INSIGHTS'), isTrue);
    });
  });

  group('AnalyticsController Integration & UI Widget Test', () {
    test('AnalyticsController loads analytics and manages state', () async {
      final controller = AnalyticsController(
        repository: repository,
        service: service,
      );

      await controller.loadAnalytics(sampleQuestions);

      expect(controller.hasData, isTrue);
      expect(controller.insights, isNotNull);
      expect(controller.historicalSnapshots.isNotEmpty, isTrue);
    });

    testWidgets(
        'AnalyticsDashboardPage renders dashboard cards and weak areas cleanly',
        (tester) async {
      final testController = AnalyticsController(
        repository: repository,
        service: service,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AnalyticsDashboardPage(
            questions: sampleQuestions,
            controller: testController,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Learning Analytics Engine'), findsOneWidget);
      expect(find.text('Performance Overview'), findsOneWidget);
      expect(find.text('Overall Accuracy'), findsOneWidget);
      expect(find.text("Today's Progress"), findsOneWidget);
      expect(find.text('Current Streak'), findsOneWidget);
    });
  });
}
