import 'dart:convert';
import 'package:hive/hive.dart';
import '../../models/quiz_attempt.dart';
import '../quiz_history_repository.dart';

class HiveQuizHistoryRepository implements QuizHistoryRepository {
  static const String _boxName = 'quiz_history';
  Box<String>? _box;

  Future<Box<String>> _getBox() async {
    if (_box != null && _box!.isOpen) {
      return _box!;
    }
    _box = await Hive.openBox<String>(_boxName);
    return _box!;
  }

  @override
  Future<void> saveAttempt(QuizAttempt attempt) async {
    final box = await _getBox();
    final jsonString = jsonEncode(attempt.toJson());
    await box.put(attempt.id, jsonString);
  }

  @override
  Future<List<QuizAttempt>> getAttempts() async {
    final box = await _getBox();
    final List<QuizAttempt> attempts = [];
    for (final key in box.keys) {
      final jsonString = box.get(key);
      if (jsonString != null) {
        try {
          final Map<String, dynamic> decoded = jsonDecode(jsonString);
          attempts.add(QuizAttempt.fromJson(decoded));
        } catch (e) {
          // Skip corrupt or invalid entries for robust future-proofing
        }
      }
    }
    // Default sort: newest attempt first
    attempts.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return attempts;
  }

  @override
  Future<void> deleteAttempt(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }

  @override
  Future<void> clearHistory() async {
    final box = await _getBox();
    await box.clear();
  }
}
