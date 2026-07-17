import 'dart:convert';
import 'package:hive/hive.dart';
import '../../models/quiz_source.dart';
import '../quiz_source_repository.dart';

class HiveQuizSourceRepository implements QuizSourceRepository {
  static const String _boxName = 'quiz_sources';

  Future<Box<String>> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<String>(_boxName);
    }
    return Hive.box<String>(_boxName);
  }

  @override
  Future<void> saveSource(QuizSource source) async {
    final box = await _getBox();
    await box.put(source.id, jsonEncode(source.toJson()));
  }

  @override
  Future<List<QuizSource>> getSources() async {
    final box = await _getBox();
    final List<QuizSource> sources = [];
    for (final key in box.keys) {
      final jsonString = box.get(key);
      if (jsonString != null) {
        try {
          sources.add(QuizSource.fromJson(jsonDecode(jsonString)));
        } catch (e) {
          // Skip corrupt or invalid items
        }
      }
    }
    return sources;
  }

  @override
  Future<void> updateSource(QuizSource source) async {
    await saveSource(source);
  }

  @override
  Future<void> deleteSource(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }

  @override
  Future<void> toggleFavorite(String id) async {
    final box = await _getBox();
    final jsonString = box.get(id);
    if (jsonString != null) {
      final source = QuizSource.fromJson(jsonDecode(jsonString));
      final updated = source.copyWith(favorite: !source.favorite);
      await saveSource(updated);
    }
  }
}
