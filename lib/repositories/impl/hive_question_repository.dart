import 'dart:convert';
import 'package:hive/hive.dart';
import '../../models/question.dart';
import '../question_repository.dart';

class HiveQuestionRepository implements QuestionRepository {
  static const String _boxName = 'engine_questions';
  Box<String>? _box;

  Future<Box<String>> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<String>(_boxName);
    return _box!;
  }

  @override
  Future<List<Question>> getAllQuestions() async {
    final box = await _getBox();
    final List<Question> list = [];
    for (final key in box.keys) {
      final jsonStr = box.get(key);
      if (jsonStr != null) {
        try {
          list.add(Question.fromJson(jsonDecode(jsonStr)));
        } catch (_) {}
      }
    }
    list.sort((a, b) {
      final cmp = b.year.compareTo(a.year);
      if (cmp != 0) return cmp;
      return a.id.compareTo(b.id);
    });
    return list;
  }

  @override
  Future<Question?> getQuestionById(String id) async {
    final box = await _getBox();
    final jsonStr = box.get(id);
    if (jsonStr == null) return null;
    try {
      return Question.fromJson(jsonDecode(jsonStr));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Question>> getQuestionsByPaper(String paperId) async {
    final all = await getAllQuestions();
    return all
        .where((q) => q.paper.toLowerCase() == paperId.toLowerCase())
        .toList();
  }

  @override
  Future<List<Question>> getQuestionsByYear(int year, {String? exam}) async {
    final all = await getAllQuestions();
    return all.where((q) {
      if (q.year != year) return false;
      if (exam != null &&
          exam.isNotEmpty &&
          q.exam.toLowerCase() != exam.toLowerCase()) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<List<Question>> getQuestionsBySubject(String subject,
      {String? exam}) async {
    final all = await getAllQuestions();
    return all.where((q) {
      if (q.subject.toLowerCase() != subject.toLowerCase()) return false;
      if (exam != null &&
          exam.isNotEmpty &&
          q.exam.toLowerCase() != exam.toLowerCase()) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<List<Question>> getQuestionsByTopic(String topic,
      {String? exam}) async {
    final all = await getAllQuestions();
    return all.where((q) {
      if (q.topic.toLowerCase() != topic.toLowerCase()) return false;
      if (exam != null &&
          exam.isNotEmpty &&
          q.exam.toLowerCase() != exam.toLowerCase()) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<List<String>> getSubjects({String? exam}) async {
    final all = await getAllQuestions();
    final subjects = all
        .where((q) =>
            exam == null ||
            exam.isEmpty ||
            q.exam.toLowerCase() == exam.toLowerCase())
        .map((q) => q.subject)
        .toSet()
        .toList();
    subjects.sort();
    return subjects;
  }

  @override
  Future<List<String>> getTopics({String? exam, String? subject}) async {
    final all = await getAllQuestions();
    final topics = all
        .where((q) {
          if (exam != null &&
              exam.isNotEmpty &&
              q.exam.toLowerCase() != exam.toLowerCase()) {
            return false;
          }
          if (subject != null &&
              subject.isNotEmpty &&
              q.subject.toLowerCase() != subject.toLowerCase()) {
            return false;
          }
          return true;
        })
        .map((q) => q.topic)
        .toSet()
        .toList();
    topics.sort();
    return topics;
  }

  @override
  Future<List<Question>> searchQuestions({
    String? query,
    int? year,
    String? subject,
    String? topic,
    String? difficulty,
    String? exam,
  }) async {
    final all = await getAllQuestions();
    return all.where((q) {
      if (year != null && q.year != year) return false;
      if (exam != null &&
          exam.isNotEmpty &&
          q.exam.toLowerCase() != exam.toLowerCase()) {
        return false;
      }
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
      if (difficulty != null &&
          difficulty.isNotEmpty &&
          q.difficulty.toLowerCase() != difficulty.toLowerCase()) {
        return false;
      }

      if (query != null && query.trim().isNotEmpty) {
        final qLower = query.trim().toLowerCase();
        final matchText = q.question.toLowerCase().contains(qLower);
        final matchSub = q.subject.toLowerCase().contains(qLower);
        final matchTop = q.topic.toLowerCase().contains(qLower);
        final matchTags = q.tags.any((t) => t.toLowerCase().contains(qLower));
        if (!matchText && !matchSub && !matchTop && !matchTags) return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<void> saveQuestion(Question question) async {
    final box = await _getBox();
    await box.put(question.id, jsonEncode(question.toJson()));
  }

  @override
  Future<void> saveQuestionsBatch(List<Question> questions) async {
    final box = await _getBox();
    final Map<String, String> map = {};
    for (final q in questions) {
      map[q.id] = jsonEncode(q.toJson());
    }
    await box.putAll(map);
  }

  @override
  Future<void> clear() async {
    final box = await _getBox();
    await box.clear();
  }
}
