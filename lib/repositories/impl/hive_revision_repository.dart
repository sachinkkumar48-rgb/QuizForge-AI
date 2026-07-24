import 'dart:convert';
import 'package:hive/hive.dart';
import '../../models/revision_schedule.dart';
import '../../services/spaced_repetition_scheduler.dart';
import '../revision_repository.dart';

class HiveRevisionRepository implements RevisionRepository {
  static const String _boxName = 'engine_revisions';
  Box<String>? _box;

  Future<Box<String>> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<String>(_boxName);
    return _box!;
  }

  @override
  Future<RevisionSchedule?> getSchedule(String questionId) async {
    final box = await _getBox();
    final jsonStr = box.get(questionId);
    if (jsonStr == null) return null;
    try {
      return RevisionSchedule.fromJson(jsonDecode(jsonStr));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Map<String, RevisionSchedule>> getAllSchedules() async {
    final box = await _getBox();
    final Map<String, RevisionSchedule> map = {};
    for (final key in box.keys) {
      final jsonStr = box.get(key);
      if (jsonStr != null) {
        try {
          final sched = RevisionSchedule.fromJson(jsonDecode(jsonStr));
          map[sched.questionId] = sched;
        } catch (_) {}
      }
    }
    return map;
  }

  @override
  Future<List<RevisionSchedule>> getDueRevisions() async {
    final box = await _getBox();
    final List<RevisionSchedule> list = [];
    final now = DateTime.now();
    for (final key in box.keys) {
      final jsonStr = box.get(key);
      if (jsonStr != null) {
        try {
          final sched = RevisionSchedule.fromJson(jsonDecode(jsonStr));
          if (sched.nextReviewDue.isBefore(now) ||
              sched.nextReviewDue.isAtSameMomentAs(now)) {
            list.add(sched);
          }
        } catch (_) {}
      }
    }
    list.sort((a, b) => a.nextReviewDue.compareTo(b.nextReviewDue));
    return list;
  }

  @override
  Future<void> updateSchedule(RevisionSchedule schedule) async {
    final box = await _getBox();
    await box.put(schedule.questionId, jsonEncode(schedule.toJson()));
  }

  @override
  Future<void> recordRevisionResult({
    required String questionId,
    required bool isCorrect,
    int confidenceRating = 3,
    String difficulty = 'Medium',
    bool isBookmarked = false,
  }) async {
    final existing = await getSchedule(questionId);
    final updated = SpacedRepetitionScheduler.computeNextSchedule(
      questionId: questionId,
      existingSchedule: existing,
      isCorrect: isCorrect,
      confidenceRating: confidenceRating,
      difficulty: difficulty,
      isBookmarked: isBookmarked,
    );

    await updateSchedule(updated);
  }

  @override
  Future<void> clear() async {
    final box = await _getBox();
    await box.clear();
  }
}
