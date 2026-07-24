import 'package:flutter/material.dart';
import '../core/module_analytics.dart';
import '../core/module_importer.dart';
import '../core/module_repository.dart';
import '../core/module_ui.dart';
import '../core/quiz_module.dart';
import '../../models/exam.dart';
import '../../models/question.dart';
import '../../models/quiz_analytics.dart';
import '../../models/quiz_attempt.dart';
import '../../models/validation_report.dart';

/// Default in-memory & delegation implementation of [ModuleRepository].
class BaseModuleRepository implements ModuleRepository {
  final String moduleId;
  final List<Question> _questions = [];
  final List<Exam> _exams = [];
  final List<Paper> _papers = [];
  final Map<String, dynamic> _metadata = {};

  BaseModuleRepository({required this.moduleId});

  @override
  Future<List<Question>> getQuestions({
    String? subject,
    String? topic,
    int? year,
    String? difficulty,
    int? limit,
  }) async {
    Iterable<Question> result = _questions;
    if (subject != null && subject.isNotEmpty) {
      result =
          result.where((q) => q.subject.toLowerCase() == subject.toLowerCase());
    }
    if (topic != null && topic.isNotEmpty) {
      result =
          result.where((q) => q.topic.toLowerCase() == topic.toLowerCase());
    }
    if (year != null) {
      result = result.where((q) => q.year == year);
    }
    if (difficulty != null && difficulty.isNotEmpty) {
      result = result
          .where((q) => q.difficulty.toLowerCase() == difficulty.toLowerCase());
    }
    if (limit != null && limit > 0) {
      result = result.take(limit);
    }
    return result.toList();
  }

  @override
  Future<List<Exam>> getExams() async => List.unmodifiable(_exams);

  @override
  Future<List<Paper>> getPapers(String examId) async {
    return _papers.where((p) => p.examId == examId).toList();
  }

  @override
  Future<void> saveQuestions(List<Question> questions) async {
    _questions.addAll(questions);
  }

  @override
  Future<dynamic> getModuleData(String key) async => _metadata[key];

  @override
  Future<void> setModuleData(String key, dynamic value) async {
    _metadata[key] = value;
  }

  @override
  Future<int> getQuestionCount() async => _questions.length;
}

/// Default implementation of [ModuleUI].
class BaseModuleUI implements ModuleUI {
  final QuizModule module;

  BaseModuleUI({required this.module});

  @override
  Widget buildDashboard(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(module.icon, size: 32, color: module.themeColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        module.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Category: ${module.category} • v${module.version}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(module.description),
          ],
        ),
      ),
    );
  }

  @override
  Widget buildPracticeView(BuildContext context,
      {Map<String, dynamic>? params}) {
    return Center(
      child: Text('${module.name} Practice Session'),
    );
  }

  @override
  Widget buildAnalyticsView(BuildContext context) {
    return Center(
      child: Text('${module.name} Analytics Overview'),
    );
  }

  @override
  Widget buildImporterView(BuildContext context) {
    return Center(
      child: Text(
          '${module.name} Dataset Importer (${module.importer.supportedFormat})'),
    );
  }

  @override
  List<Widget> getQuickActions(BuildContext context) {
    return [
      ElevatedButton.icon(
        onPressed: () {},
        icon: Icon(module.icon),
        label: Text('Start ${module.name}'),
      ),
    ];
  }
}

/// Default implementation of [ModuleImporter].
class BaseModuleImporter implements ModuleImporter {
  final String moduleId;

  BaseModuleImporter({required this.moduleId});

  @override
  String get supportedFormat => 'JSON Dataset (*.json)';

  @override
  Future<ValidationReport> validateDataset(String content) async {
    if (content.trim().isEmpty) {
      return ValidationReport(
        totalQuestions: 0,
        validQuestionsCount: 0,
        invalidQuestionsCount: 0,
        issues: [
          ValidationIssue(
            field: 'content',
            message: 'Empty dataset content provided',
          ),
        ],
      );
    }
    return ValidationReport(
      totalQuestions: 1,
      validQuestionsCount: 1,
      invalidQuestionsCount: 0,
      issues: [],
    );
  }

  @override
  Future<int> importDataset(
    String content, {
    ImportMode importMode = ImportMode.safe,
  }) async {
    final report = await validateDataset(content);
    return report.validQuestionsCount;
  }

  @override
  List<String> getSampleTemplates() {
    return ['assets/templates/${moduleId}_sample.json'];
  }
}

/// Default implementation of [ModuleAnalytics].
class BaseModuleAnalytics implements ModuleAnalytics {
  final String moduleId;

  BaseModuleAnalytics({required this.moduleId});

  @override
  Future<QuizAnalytics> calculateAnalytics(List<QuizAttempt> attempts) async {
    if (attempts.isEmpty) {
      return QuizAnalytics(
        score: 0,
        totalQuestions: 0,
        attempted: 0,
        skipped: 0,
        incorrect: 0,
        accuracy: 0.0,
        performanceLevel: PerformanceLevel.average,
        timeSpent: Duration.zero,
        remainingTime: Duration.zero,
        totalDuration: Duration.zero,
        statusCounts: const {},
      );
    }

    int totalQuestions = 0;
    int attemptedCount = 0;
    int skippedCount = 0;
    int incorrectCount = 0;
    int totalScore = 0;

    for (final attempt in attempts) {
      totalQuestions += attempt.analytics.totalQuestions;
      attemptedCount += attempt.analytics.attempted;
      skippedCount += attempt.analytics.skipped;
      incorrectCount += attempt.analytics.incorrect;
      totalScore += attempt.analytics.score;
    }

    final accuracy = totalQuestions > 0
        ? (attemptedCount - incorrectCount) / totalQuestions * 100
        : 0.0;

    return QuizAnalytics(
      score: totalScore,
      totalQuestions: totalQuestions,
      attempted: attemptedCount,
      skipped: skippedCount,
      incorrect: incorrectCount,
      accuracy: accuracy,
      performanceLevel: accuracy >= 75
          ? PerformanceLevel.excellent
          : accuracy >= 50
              ? PerformanceLevel.good
              : PerformanceLevel.average,
      timeSpent: Duration(seconds: attempts.length * 60),
      remainingTime: Duration.zero,
      totalDuration: Duration(seconds: attempts.length * 60),
      statusCounts: const {},
    );
  }

  @override
  Future<Map<String, double>> getTopicWeaknessScores(
      List<QuizAttempt> attempts) async {
    return {'General Knowledge': 0.3};
  }

  @override
  Future<List<String>> getRecommendedFocusAreas(
      List<QuizAttempt> attempts) async {
    return ['Core Concepts', 'Previous Year Questions'];
  }

  @override
  Future<double> estimateCutoffProbability(List<QuizAttempt> attempts) async {
    if (attempts.isEmpty) return 0.0;
    final latest = attempts.last.analytics.accuracy;
    return (latest / 100.0).clamp(0.0, 1.0);
  }
}

/// Base class implementation of [QuizModule] to simplify creating custom modules.
class BaseQuizModule implements QuizModule {
  @override
  final String id;

  @override
  final String name;

  @override
  final String description;

  @override
  final String version;

  @override
  final String category;

  @override
  final IconData icon;

  @override
  final Color themeColor;

  late final ModuleRepository _repository;
  late final ModuleUI _ui;
  late final ModuleImporter _importer;
  late final ModuleAnalytics _analytics;

  BaseQuizModule({
    required this.id,
    required this.name,
    required this.description,
    this.version = '1.0.0',
    this.category = 'General',
    this.icon = Icons.extension,
    this.themeColor = Colors.indigo,
    ModuleRepository? repository,
    ModuleUI? ui,
    ModuleImporter? importer,
    ModuleAnalytics? analytics,
  }) {
    _repository = repository ?? BaseModuleRepository(moduleId: id);
    _ui = ui ?? BaseModuleUI(module: this);
    _importer = importer ?? BaseModuleImporter(moduleId: id);
    _analytics = analytics ?? BaseModuleAnalytics(moduleId: id);
  }

  @override
  ModuleRepository get repository => _repository;

  @override
  ModuleUI get ui => _ui;

  @override
  ModuleImporter get importer => _importer;

  @override
  ModuleAnalytics get analytics => _analytics;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> onEnable() async {}

  @override
  Future<void> onDisable() async {}
}
