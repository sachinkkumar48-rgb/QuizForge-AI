import 'dart:convert';
import 'package:hive/hive.dart';
import '../../models/attempt.dart';
import '../attempt_repository.dart';

class HiveAttemptRepository implements AttemptRepository {
  static const String _boxName = 'engine_attempts';
  Box<String>? _box;

  Future<Box<String>> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<String>(_boxName);
    return _box!;
  }

  @override
  Future<void> recordAttempt(QuestionAttempt attempt) async {
    final box = await _getBox();
    await box.put(attempt.attemptId, jsonEncode(attempt.toJson()));
  }

  @override
  Future<List<QuestionAttempt>> getAttemptsForQuestion(
      String questionId) async {
    final box = await _getBox();
    final List<QuestionAttempt> list = [];
    for (final key in box.keys) {
      final jsonStr = box.get(key);
      if (jsonStr != null) {
        try {
          final att = QuestionAttempt.fromJson(jsonDecode(jsonStr));
          if (att.questionId == questionId) {
            list.add(att);
          }
        } catch (_) {}
      }
    }
    list.sort((a, b) => b.attemptedAt.compareTo(a.attemptedAt));
    return list;
  }

  @override
  Future<QuestionAttempt?> getLatestAttempt(String questionId) async {
    final attempts = await getAttemptsForQuestion(questionId);
    return attempts.isNotEmpty ? attempts.first : null;
  }

  @override
  Future<List<QuestionAttempt>> getAllAttempts() async {
    final box = await _getBox();
    final List<QuestionAttempt> list = [];
    for (final key in box.keys) {
      final jsonStr = box.get(key);
      if (jsonStr != null) {
        try {
          list.add(QuestionAttempt.fromJson(jsonDecode(jsonStr)));
        } catch (_) {}
      }
    }
    list.sort((a, b) => b.attemptedAt.compareTo(a.attemptedAt));
    return list;
  }

  @override
  Future<List<String>> getIncorrectQuestionIds() async {
    final all = await getAllAttempts();
    final Map<String, QuestionAttempt> latestMap = {};
    for (final att in all) {
      if (!latestMap.containsKey(att.questionId)) {
        latestMap[att.questionId] = att;
      }
    }
    final List<String> incorrectIds = [];
    latestMap.forEach((questionId, att) {
      if (!att.isCorrect) {
        incorrectIds.add(questionId);
      }
    });
    return incorrectIds;
  }

  @override
  Future<void> clear() async {
    final box = await _getBox();
    await box.clear();
  }
}
