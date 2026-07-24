import 'dart:convert';
import 'package:hive/hive.dart';
import '../../models/explanation.dart';
import '../explanation_repository.dart';

class HiveExplanationRepository implements ExplanationRepository {
  static const String _boxName = 'engine_explanations';
  Box<String>? _box;

  Future<Box<String>> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<String>(_boxName);
    return _box!;
  }

  @override
  Future<List<Explanation>> getExplanations(String questionId) async {
    final box = await _getBox();
    final List<Explanation> list = [];
    for (final key in box.keys) {
      final jsonStr = box.get(key);
      if (jsonStr != null) {
        try {
          final exp = Explanation.fromJson(jsonDecode(jsonStr));
          if (exp.questionId == questionId) {
            list.add(exp);
          }
        } catch (_) {}
      }
    }
    return list;
  }

  @override
  Future<Explanation?> getExplanationByType(
      String questionId, String explanationType) async {
    final list = await getExplanations(questionId);
    try {
      return list.firstWhere(
        (e) => e.explanationType.toLowerCase() == explanationType.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveExplanation(Explanation explanation) async {
    final box = await _getBox();
    await box.put(explanation.explanationId, jsonEncode(explanation.toJson()));
  }

  @override
  Future<void> saveExplanationsBatch(List<Explanation> explanations) async {
    final box = await _getBox();
    final Map<String, String> map = {};
    for (final exp in explanations) {
      map[exp.explanationId] = jsonEncode(exp.toJson());
    }
    await box.putAll(map);
  }

  @override
  Future<void> deleteExplanation(String explanationId) async {
    final box = await _getBox();
    await box.delete(explanationId);
  }

  @override
  Future<void> clear() async {
    final box = await _getBox();
    await box.clear();
  }
}
