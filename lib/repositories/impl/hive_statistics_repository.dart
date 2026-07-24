import 'dart:convert';
import 'package:hive/hive.dart';
import '../../models/question_statistics.dart';
import '../statistics_repository.dart';

class HiveStatisticsRepository implements StatisticsRepository {
  static const String _boxName = 'engine_statistics';
  Box<String>? _box;

  Future<Box<String>> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<String>(_boxName);
    return _box!;
  }

  @override
  Future<QuestionStatistics?> getQuestionStats(String questionId) async {
    final box = await _getBox();
    final jsonStr = box.get(questionId);
    if (jsonStr == null) return null;
    try {
      return QuestionStatistics.fromJson(jsonDecode(jsonStr));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> updateQuestionStats({
    required String questionId,
    required bool isCorrect,
    required int timeSpentSeconds,
  }) async {
    final box = await _getBox();
    final existing = await getQuestionStats(questionId);

    final currentTotal = existing?.totalAttempts ?? 0;
    final currentCorrect = existing?.correctAttempts ?? 0;
    final currentIncorrect = existing?.incorrectAttempts ?? 0;
    final currentAvgTime = existing?.averageTimeSeconds ?? 0;

    final newTotal = currentTotal + 1;
    final newCorrect = isCorrect ? currentCorrect + 1 : currentCorrect;
    final newIncorrect = isCorrect ? currentIncorrect : currentIncorrect + 1;
    final newAvgTime =
        ((currentAvgTime * currentTotal) + timeSpentSeconds) ~/ newTotal;
    final accuracy = newTotal == 0 ? 0.0 : (newCorrect / newTotal) * 100.0;

    final updated = QuestionStatistics(
      questionId: questionId,
      totalAttempts: newTotal,
      correctAttempts: newCorrect,
      incorrectAttempts: newIncorrect,
      accuracyPercentage: accuracy,
      averageTimeSeconds: newAvgTime,
      lastAttemptedAt: DateTime.now(),
    );

    await box.put(questionId, jsonEncode(updated.toJson()));
  }

  @override
  Future<List<QuestionStatistics>> getAllStats() async {
    final box = await _getBox();
    final List<QuestionStatistics> list = [];
    for (final key in box.keys) {
      final jsonStr = box.get(key);
      if (jsonStr != null) {
        try {
          list.add(QuestionStatistics.fromJson(jsonDecode(jsonStr)));
        } catch (_) {}
      }
    }
    return list;
  }

  @override
  Future<void> clear() async {
    final box = await _getBox();
    await box.clear();
  }
}
