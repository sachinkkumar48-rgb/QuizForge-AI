import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/quiz_model.dart';

class CacheService {
  CacheService._();

  static const String _boxName = 'quiz_cache';

  static Future<Box<String>> _box() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<String>(_boxName);
    }

    return Hive.box<String>(_boxName);
  }

  static String generateKey(String text) {
    return sha256.convert(utf8.encode(text)).toString();
  }

  static Future<List<QuizQuestion>?> loadQuiz(
    String key,
  ) async {
    final box = await _box();

    final jsonString = box.get(key);

    if (jsonString == null) {
      return null;
    }

    final List<dynamic> decoded = jsonDecode(jsonString);

    return decoded
        .map(
          (e) => QuizQuestion.fromJson(e),
        )
        .toList();
  }

  static Future<void> saveQuiz(
    String key,
    List<QuizQuestion> questions,
  ) async {
    final box = await _box();

    final jsonString = jsonEncode(
      questions
          .map(
            (e) => e.toJson(),
          )
          .toList(),
    );

    await box.put(
      key,
      jsonString,
    );
  }

  static Future<void> clearCache() async {
    final box = await _box();

    await box.clear();
  }

  static Future<bool> contains(
    String key,
  ) async {
    final box = await _box();

    return box.containsKey(key);
  }

  static Future<int> cacheCount() async {
    final box = await _box();

    return box.length;
  }
}
