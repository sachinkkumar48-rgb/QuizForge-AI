import 'dart:convert';
import 'package:hive/hive.dart';

import '../../database/migrations/migration_manager.dart';
import '../../models/bookmark.dart';
import '../../models/daily_revision_queue.dart';
import '../../models/explanation.dart';
import '../../models/pyq_analytics_model.dart';
import '../../models/pyq_question_model.dart';
import '../../models/question.dart';
import '../../models/view/question_with_details.dart';
import '../../services/generic_dataset_importer.dart';
import '../../services/pyq_analytics_service.dart';
import '../../services/pyq_importer_service.dart';
import '../../services/search/inverted_index.dart';
import '../../services/search/search_query.dart';
import '../../services/spaced_repetition_scheduler.dart';
import '../pyq_repository.dart';
import 'hive_dataset_repository.dart';
import 'hive_exam_repository.dart';
import 'hive_explanation_repository.dart';
import 'hive_question_repository.dart';
import 'hive_revision_repository.dart';

class HivePyqRepository implements PyqRepository {
  static const String _boxName = 'pyq_questions';
  Box<String>? _box;

  final InvertedIndex _searchIndex = InvertedIndex();
  bool _isIndexBuilt = false;

  Future<void> _ensureIndexBuilt() async {
    if (_isIndexBuilt) return;
    _searchIndex.clear();
    final all = await getAllQuestions();
    for (final pyq in all) {
      final detail = _toQuestionWithDetails(pyq);
      _searchIndex.index(detail);
    }
    _isIndexBuilt = true;
  }

  QuestionWithDetails _toQuestionWithDetails(PyqQuestionModel q) {
    final question = Question(
      id: q.id,
      exam: q.exam,
      year: q.year,
      paper: q.paper,
      subject: q.subject,
      topic: q.topic,
      difficulty: q.difficulty,
      question: q.question,
      options: q.options,
      correctAnswer: q.correctAnswer,
      tags: q.tags,
    );

    final explanations = <Explanation>[];
    if (q.explanation.official.isNotEmpty) {
      explanations.add(Explanation(
        explanationId: 'exp_off_${q.id}',
        questionId: q.id,
        explanationType: 'Official',
        content: q.explanation.official,
        source: q.reference,
      ));
    }
    if (q.explanation.ai != null && q.explanation.ai!.isNotEmpty) {
      explanations.add(Explanation(
        explanationId: 'exp_ai_${q.id}',
        questionId: q.id,
        explanationType: 'AI_Generated',
        content: q.explanation.ai!,
        source: 'Gemini AI',
      ));
    }

    return QuestionWithDetails(
      question: question,
      explanations: explanations,
      bookmark: q.isBookmarked
          ? Bookmark(bookmarkId: 'bm_${q.id}', questionId: q.id)
          : null,
    );
  }

  Future<Box<String>> _getBox() async {
    if (_box != null && _box!.isOpen) {
      return _box!;
    }
    _box = await Hive.openBox<String>(_boxName);
    return _box!;
  }

  @override
  Future<void> init() async {
    // Run DB Schema Migrations first
    final migrationManager = MigrationManager();
    await migrationManager.runMigrations();

    final box = await _getBox();
    if (box.isEmpty) {
      final seedQuestions = await PyqImporterService.loadAssetDataset();
      for (final q in seedQuestions) {
        await box.put(q.id, jsonEncode(q.toJson()));
      }
    }

    // Initialize generic engine storage
    final importer = GenericDatasetImporter(
      examRepository: HiveExamRepository(),
      questionRepository: HiveQuestionRepository(),
      explanationRepository: HiveExplanationRepository(),
      datasetRepository: HiveDatasetRepository(),
    );
    await importer.seedFromAssets();
  }

  @override
  Future<List<PyqQuestionModel>> getAllQuestions() async {
    final box = await _getBox();
    final List<PyqQuestionModel> list = [];
    for (final key in box.keys) {
      final jsonString = box.get(key);
      if (jsonString != null) {
        try {
          list.add(PyqQuestionModel.fromJson(jsonDecode(jsonString)));
        } catch (_) {}
      }
    }
    // Sort descending by year, then by id
    list.sort((a, b) {
      final cmp = b.year.compareTo(a.year);
      if (cmp != 0) return cmp;
      return a.id.compareTo(b.id);
    });
    return list;
  }

  @override
  Future<List<PyqQuestionModel>> getQuestionsByYear(int year) async {
    final all = await getAllQuestions();
    return all.where((q) => q.year == year).toList();
  }

  @override
  Future<List<PyqQuestionModel>> getQuestionsBySubject(String subject) async {
    final all = await getAllQuestions();
    return all
        .where((q) => q.subject.toLowerCase() == subject.toLowerCase())
        .toList();
  }

  @override
  Future<List<PyqQuestionModel>> getQuestionsByTopic(String topic) async {
    final all = await getAllQuestions();
    return all
        .where((q) => q.topic.toLowerCase() == topic.toLowerCase())
        .toList();
  }

  @override
  Future<List<PyqQuestionModel>> getBookmarkedQuestions() async {
    final all = await getAllQuestions();
    return all.where((q) => q.isBookmarked).toList();
  }

  @override
  Future<List<PyqQuestionModel>> getIncorrectQuestions() async {
    final all = await getAllQuestions();
    return all.where((q) => q.isAttempted && !q.isLastAttemptCorrect).toList();
  }

  @override
  Future<List<PyqQuestionModel>> searchQuestions({
    String? query,
    int? year,
    String? subject,
    String? topic,
    String? difficulty,
    bool? onlyBookmarked,
    bool? onlyIncorrect,
    bool? unattempted,
  }) async {
    await _ensureIndexBuilt();

    final searchQuery = SearchQuery(
      queryText: query ?? '',
      year: year,
      subject: subject,
      topic: topic,
      difficulty: difficulty,
      onlyBookmarked: onlyBookmarked ?? false,
      limit: 10000,
    );

    final searchResult = _searchIndex.query(searchQuery);
    final allQuestionsMap = {for (final q in await getAllQuestions()) q.id: q};

    final List<PyqQuestionModel> results = [];
    for (final item in searchResult.items) {
      final pyq = allQuestionsMap[item.questionDetails.question.id];
      if (pyq != null) {
        if (onlyIncorrect == true &&
            (!pyq.isAttempted || pyq.isLastAttemptCorrect)) {
          continue;
        }
        if (unattempted == true && pyq.isAttempted) {
          continue;
        }
        results.add(pyq);
      }
    }

    return results;
  }

  @override
  Future<void> toggleBookmark(String questionId) async {
    final box = await _getBox();
    final jsonString = box.get(questionId);
    if (jsonString != null) {
      final q = PyqQuestionModel.fromJson(jsonDecode(jsonString));
      final updated = q.copyWith(isBookmarked: !q.isBookmarked);
      await box.put(questionId, jsonEncode(updated.toJson()));
      _isIndexBuilt = false;
    }
  }

  @override
  Future<void> recordAttempt({
    required String questionId,
    required String selectedAnswer,
  }) async {
    final box = await _getBox();
    final jsonString = box.get(questionId);
    if (jsonString != null) {
      final q = PyqQuestionModel.fromJson(jsonDecode(jsonString));
      final isCorrect = (selectedAnswer.trim().toLowerCase() ==
              q.correctAnswer.trim().toLowerCase()) ||
          (selectedAnswer.trim().toUpperCase() ==
              q.officialAnswer.trim().toUpperCase());

      final updated = q.copyWith(
        timesAttempted: q.timesAttempted + 1,
        timesCorrect: isCorrect ? q.timesCorrect + 1 : q.timesCorrect,
        lastAttempted: DateTime.now(),
        userSelectedAnswer: selectedAnswer,
      );

      await box.put(questionId, jsonEncode(updated.toJson()));
      _isIndexBuilt = false;
    }
  }

  @override
  Future<List<PyqQuestionModel>> generateMockTest({
    required int count,
    String? subject,
    String? topic,
    List<int>? years,
  }) async {
    final all = await getAllQuestions();

    var filtered = all.where((q) {
      if (subject != null &&
          subject.isNotEmpty &&
          q.subject.toLowerCase() != subject.toLowerCase()) {
        return false;
      }
      if (topic != null &&
          topic.isNotEmpty &&
          q.topic.toLowerCase() != topic.toLowerCase()) {
        return false;
      }
      if (years != null && years.isNotEmpty && !years.contains(q.year)) {
        return false;
      }
      return true;
    }).toList();

    filtered.shuffle();
    return filtered.take(count).toList();
  }

  @override
  Future<List<PyqQuestionModel>> generateSmartRevision({
    int count = 20,
    bool includeIncorrect = true,
    bool includeBookmarked = true,
    bool includeWeak = true,
  }) async {
    final all = await getAllQuestions();
    final analytics = PyqAnalyticsService.computeAnalytics(all);
    final Set<String> targetIds = {};
    final List<PyqQuestionModel> selected = [];

    if (includeIncorrect) {
      for (final q in all) {
        if (q.isAttempted && !q.isLastAttemptCorrect) {
          targetIds.add(q.id);
          selected.add(q);
        }
      }
    }

    if (includeBookmarked) {
      for (final q in all) {
        if (q.isBookmarked && !targetIds.contains(q.id)) {
          targetIds.add(q.id);
          selected.add(q);
        }
      }
    }

    if (includeWeak && analytics.weakSubjects.isNotEmpty) {
      for (final q in all) {
        if (analytics.weakSubjects.contains(q.subject) &&
            !targetIds.contains(q.id)) {
          targetIds.add(q.id);
          selected.add(q);
        }
      }
    }

    // Fill remaining if needed
    if (selected.length < count) {
      for (final q in all) {
        if (!targetIds.contains(q.id)) {
          targetIds.add(q.id);
          selected.add(q);
          if (selected.length >= count) break;
        }
      }
    }

    selected.shuffle();
    return selected.take(count).toList();
  }

  final HiveRevisionRepository _revisionRepository = HiveRevisionRepository();

  @override
  Future<DailyRevisionQueue> getDailyRevisionQueue() async {
    final questions = await getAllQuestions();
    final scheduleMap = await _revisionRepository.getAllSchedules();
    return SpacedRepetitionScheduler.buildDailyQueue(
      questions: questions,
      scheduleMap: scheduleMap,
    );
  }

  @override
  Future<void> recordSpacedRevisionResult({
    required String questionId,
    required bool isCorrect,
    required int confidenceRating,
  }) async {
    final box = await _getBox();
    final jsonStr = box.get(questionId);
    String diff = 'Medium';
    bool isBm = false;
    if (jsonStr != null) {
      try {
        final q = PyqQuestionModel.fromJson(jsonDecode(jsonStr));
        diff = q.difficulty;
        isBm = q.isBookmarked;
      } catch (_) {}
    }

    await _revisionRepository.recordRevisionResult(
      questionId: questionId,
      isCorrect: isCorrect,
      confidenceRating: confidenceRating,
      difficulty: diff,
      isBookmarked: isBm,
    );
  }

  @override
  Future<int> importDataset(String jsonString) async {
    final box = await _getBox();
    final imported = PyqImporterService.parseDatasetJson(jsonString);
    int count = 0;
    for (final q in imported) {
      await box.put(q.id, jsonEncode(q.toJson()));
      count++;
    }
    if (count > 0) _isIndexBuilt = false;
    return count;
  }

  @override
  Future<PyqAnalyticsModel> getAnalytics() async {
    final all = await getAllQuestions();
    return PyqAnalyticsService.computeAnalytics(all);
  }

  @override
  Future<void> clear() async {
    final box = await _getBox();
    await box.clear();
    _searchIndex.clear();
    _isIndexBuilt = false;
  }
}
