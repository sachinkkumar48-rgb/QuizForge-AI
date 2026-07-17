import 'dart:convert';
import 'package:hive/hive.dart';
import '../../models/quiz_session.dart';
import '../quiz_session_repository.dart';

class HiveQuizSessionRepository implements QuizSessionRepository {
  static const String _boxName = 'quiz_session';
  static const String _key = 'active_session';

  Future<Box<String>> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<String>(_boxName);
    }
    return Hive.box<String>(_boxName);
  }

  @override
  Future<void> saveSession(QuizSession session) async {
    final box = await _getBox();
    final jsonString = jsonEncode(session.toJson());
    await box.put(_key, jsonString);
  }

  @override
  Future<QuizSession?> loadSession() async {
    final box = await _getBox();
    final jsonString = box.get(_key);
    if (jsonString == null) return null;
    try {
      final Map<String, dynamic> decoded = jsonDecode(jsonString);
      return QuizSession.fromJson(decoded);
    } catch (e) {
      await deleteSession();
      return null;
    }
  }

  @override
  Future<void> deleteSession() async {
    final box = await _getBox();
    await box.delete(_key);
  }

  @override
  Future<bool> hasActiveSession() async {
    final box = await _getBox();
    return box.containsKey(_key);
  }
}
