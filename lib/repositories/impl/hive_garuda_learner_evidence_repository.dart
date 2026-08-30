/// Persistent Learner Evidence & Longitudinal Learning State (TITAN-KO-028.0 P28).
///
/// Authoritative persistence infrastructure for P18 Attempt evidence, Progress evidence,
/// Learner profiles, and P19 Assessment sessions backed by Hive.
///
/// Architectural Guarantees:
/// - Write-through in-memory caching for zero-latency synchronous reads.
/// - Deterministic restart survival across application terminations.
/// - Strict learner isolation (records from learner-A never appear in learner-B's state).
/// - Safe against corrupted or malformed disk records.
/// - Idempotent writes.
/// - Pure backward-compatibility fallback when running in headless environments.
library;

import 'dart:convert';

import 'package:garuda_learning/garuda_learning.dart';
import 'package:hive/hive.dart';

/// Hive-backed persistent implementation of [AttemptRepository].
class HiveGarudaAttemptRepository implements AttemptRepository {
  static const String attemptsBoxName = 'garuda_attempts';
  static const String resultsBoxName = 'garuda_attempt_results';

  final Box<String>? _attemptsBox;
  final Box<String>? _resultsBox;

  final Map<String, QuestionAttempt> _attempts = {};
  final Map<String, AttemptResult> _results = {};

  HiveGarudaAttemptRepository({
    Box<String>? attemptsBox,
    Box<String>? resultsBox,
  })  : _attemptsBox = attemptsBox ??
            (Hive.isBoxOpen(attemptsBoxName)
                ? Hive.box<String>(attemptsBoxName)
                : null),
        _resultsBox = resultsBox ??
            (Hive.isBoxOpen(resultsBoxName)
                ? Hive.box<String>(resultsBoxName)
                : null) {
    _loadFromStorage();
  }

  void _loadFromStorage() {
    final attemptsBox = _attemptsBox;
    if (attemptsBox != null && attemptsBox.isOpen) {
      for (final key in attemptsBox.keys) {
        final raw = attemptsBox.get(key);
        if (raw != null) {
          try {
            final decoded = jsonDecode(raw);
            if (decoded is Map<String, dynamic>) {
              final learnerId = decoded['learnerId'] as String?;
              final questionId = decoded['questionId'] as String?;
              final objectiveId = decoded['objectiveId'] as String?;
              final attemptId = decoded['attemptId'] as String?;
              if (learnerId != null &&
                  learnerId.trim().isNotEmpty &&
                  questionId != null &&
                  questionId.trim().isNotEmpty &&
                  objectiveId != null &&
                  objectiveId.trim().isNotEmpty &&
                  attemptId != null &&
                  attemptId.trim().isNotEmpty) {
                final attempt = QuestionAttempt.fromJson(decoded);
                _attempts[attempt.attemptId] = attempt;
              }
            }
          } catch (_) {
            // Malformed data safely skipped
          }
        }
      }
    }

    final resultsBox = _resultsBox;
    if (resultsBox != null && resultsBox.isOpen) {
      for (final key in resultsBox.keys) {
        final raw = resultsBox.get(key);
        if (raw != null) {
          try {
            final decoded = jsonDecode(raw);
            if (decoded is Map<String, dynamic>) {
              final attemptId = decoded['attemptId'] as String?;
              final score = decoded['score'];
              if (attemptId != null &&
                  attemptId.trim().isNotEmpty &&
                  score is num &&
                  score >= 0.0 &&
                  score <= 1.0) {
                final result = AttemptResult.fromJson(decoded);
                _results[result.attemptId] = result;
              }
            }
          } catch (_) {
            // Malformed data safely skipped
          }
        }
      }
    }
  }

  @override
  void saveAttempt(QuestionAttempt attempt) {
    if (attempt.attemptId.trim().isEmpty || attempt.learnerId.trim().isEmpty) {
      throw ArgumentError(
          'Attempt must have non-empty attemptId and learnerId');
    }
    _attempts[attempt.attemptId] = attempt;
    final box = _attemptsBox;
    if (box != null && box.isOpen) {
      box.put(attempt.attemptId, jsonEncode(attempt.toJson()));
    }
  }

  @override
  void saveResult(AttemptResult result) {
    if (result.attemptId.trim().isEmpty) {
      throw ArgumentError('Result must have non-empty attemptId');
    }
    _results[result.attemptId] = result;
    final box = _resultsBox;
    if (box != null && box.isOpen) {
      box.put(result.attemptId, jsonEncode(result.toJson()));
    }
  }

  @override
  QuestionAttempt? getAttemptById(String attemptId) => _attempts[attemptId];

  @override
  AttemptResult? getResultForAttempt(String attemptId) => _results[attemptId];

  @override
  List<QuestionAttempt> getAttemptsForLearner(String learnerId) {
    final list = _attempts.values
        .where((a) => a.learnerId == learnerId)
        .toList()
      ..sort((a, b) => a.attemptedAt.compareTo(b.attemptedAt));
    return List.unmodifiable(list);
  }

  @override
  List<QuestionAttempt> getAttemptsForLearnerAndObjective(
    String learnerId,
    String objectiveId,
  ) {
    final list = _attempts.values
        .where((a) => a.learnerId == learnerId && a.objectiveId == objectiveId)
        .toList()
      ..sort((a, b) => a.attemptedAt.compareTo(b.attemptedAt));
    return List.unmodifiable(list);
  }

  @override
  List<AttemptResult> getResultsForLearnerAndObjective(
    String learnerId,
    String objectiveId,
  ) {
    final attempts = getAttemptsForLearnerAndObjective(learnerId, objectiveId);
    final results = <AttemptResult>[];
    for (final att in attempts) {
      final res = _results[att.attemptId];
      if (res != null) {
        results.add(res);
      }
    }
    return List.unmodifiable(results);
  }

  @override
  List<QuestionAttempt> getAttemptsForSession(String sessionId) {
    final list = _attempts.values
        .where((a) => a.sessionId == sessionId)
        .toList()
      ..sort((a, b) => a.attemptedAt.compareTo(b.attemptedAt));
    return List.unmodifiable(list);
  }

  @override
  void clear() {
    _attempts.clear();
    _results.clear();
    final attemptsBox = _attemptsBox;
    if (attemptsBox != null && attemptsBox.isOpen) {
      attemptsBox.clear();
    }
    final resultsBox = _resultsBox;
    if (resultsBox != null && resultsBox.isOpen) {
      resultsBox.clear();
    }
  }
}

/// Hive-backed persistent implementation of [ProgressRepository].
class HiveGarudaProgressRepository implements ProgressRepository {
  static const String boxName = 'garuda_learner_progress';

  final Box<String>? _box;
  final Map<String, LearnerProgress> _progressMap = {};

  HiveGarudaProgressRepository({Box<String>? box})
      : _box = box ??
            (Hive.isBoxOpen(boxName) ? Hive.box<String>(boxName) : null) {
    _loadFromStorage();
  }

  static String _key(String learnerId, String objectiveId) =>
      '$learnerId:$objectiveId';

  void _loadFromStorage() {
    final box = _box;
    if (box != null && box.isOpen) {
      for (final key in box.keys) {
        final raw = box.get(key);
        if (raw != null) {
          try {
            final decoded = jsonDecode(raw);
            if (decoded is Map<String, dynamic>) {
              final learnerId = decoded['learnerId'] as String?;
              final objectiveId = decoded['objectiveId'] as String?;
              if (learnerId != null &&
                  learnerId.trim().isNotEmpty &&
                  objectiveId != null &&
                  objectiveId.trim().isNotEmpty) {
                final progress = LearnerProgress.fromJson(decoded);
                _progressMap[_key(progress.learnerId, progress.objectiveId)] =
                    progress;
              }
            }
          } catch (_) {
            // Malformed data safely skipped
          }
        }
      }
    }
  }

  @override
  void saveProgress(LearnerProgress progress) {
    if (progress.learnerId.trim().isEmpty ||
        progress.objectiveId.trim().isEmpty) {
      throw ArgumentError(
          'Progress must have non-empty learnerId and objectiveId');
    }
    final key = _key(progress.learnerId, progress.objectiveId);
    _progressMap[key] = progress;
    final box = _box;
    if (box != null && box.isOpen) {
      box.put(key, jsonEncode(progress.toJson()));
    }
  }

  @override
  LearnerProgress? getProgress(String learnerId, String objectiveId) {
    return _progressMap[_key(learnerId, objectiveId)];
  }

  @override
  List<LearnerProgress> getProgressForLearner(String learnerId) {
    final list = _progressMap.values
        .where((p) => p.learnerId == learnerId)
        .toList()
      ..sort((a, b) => a.objectiveId.compareTo(b.objectiveId));
    return List.unmodifiable(list);
  }

  @override
  List<LearnerProgress> getAll() {
    final list = _progressMap.values.toList()
      ..sort((a, b) => _key(a.learnerId, a.objectiveId)
          .compareTo(_key(b.learnerId, b.objectiveId)));
    return List.unmodifiable(list);
  }

  @override
  void clear() {
    _progressMap.clear();
    final box = _box;
    if (box != null && box.isOpen) {
      box.clear();
    }
  }
}

/// Hive-backed persistent implementation of [LearnerRepository].
class HiveGarudaLearnerRepository implements LearnerRepository {
  static const String boxName = 'garuda_learners';

  final Box<String>? _box;
  final Map<String, Learner> _learners = {};

  HiveGarudaLearnerRepository({
    Box<String>? box,
    List<Learner>? initialLearners,
  }) : _box = box ??
            (Hive.isBoxOpen(boxName) ? Hive.box<String>(boxName) : null) {
    _loadFromStorage();
    if (initialLearners != null) {
      for (final l in initialLearners) {
        save(l);
      }
    }
  }

  void _loadFromStorage() {
    final box = _box;
    if (box != null && box.isOpen) {
      for (final key in box.keys) {
        final raw = box.get(key);
        if (raw != null) {
          try {
            final decoded = jsonDecode(raw);
            if (decoded is Map<String, dynamic>) {
              final id = decoded['id'] as String?;
              final name = decoded['name'] as String?;
              if (id != null &&
                  id.trim().isNotEmpty &&
                  name != null &&
                  name.trim().isNotEmpty) {
                final learner = Learner.fromJson(decoded);
                _learners[learner.id] = learner;
              }
            }
          } catch (_) {
            // Malformed data safely skipped
          }
        }
      }
    }
  }

  @override
  void save(Learner learner) {
    if (learner.id.trim().isEmpty) {
      throw ArgumentError('Learner ID cannot be empty');
    }
    _learners[learner.id] = learner;
    final box = _box;
    if (box != null && box.isOpen) {
      box.put(learner.id, jsonEncode(learner.toJson()));
    }
  }

  @override
  Learner? getById(String id) => _learners[id];

  @override
  List<Learner> getAll() {
    final list = _learners.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    return List.unmodifiable(list);
  }

  @override
  bool exists(String id) => _learners.containsKey(id);

  @override
  void clear() {
    _learners.clear();
    final box = _box;
    if (box != null && box.isOpen) {
      box.clear();
    }
  }
}

/// Hive-backed persistent implementation of [SessionManager].
class HiveGarudaSessionManager extends SessionManager {
  static const String boxName = 'garuda_sessions';

  final Box<String>? _box;
  final Map<String, AssessmentSession> _storedSessions = {};

  HiveGarudaSessionManager({
    required super.learnerRepository,
    Box<String>? box,
  }) : _box = box ??
            (Hive.isBoxOpen(boxName) ? Hive.box<String>(boxName) : null) {
    _loadFromStorage();
  }

  void _loadFromStorage() {
    final box = _box;
    if (box != null && box.isOpen) {
      for (final key in box.keys) {
        final raw = box.get(key);
        if (raw != null) {
          try {
            final decoded = jsonDecode(raw);
            if (decoded is Map<String, dynamic>) {
              final sessionId = decoded['sessionId'] as String?;
              final learnerId = decoded['learnerId'] as String?;
              if (sessionId != null &&
                  sessionId.trim().isNotEmpty &&
                  learnerId != null &&
                  learnerId.trim().isNotEmpty) {
                final session = AssessmentSession.fromJson(decoded);
                _storedSessions[session.sessionId] = session;
              }
            }
          } catch (_) {
            // Malformed data safely skipped
          }
        }
      }
    }
  }

  @override
  AssessmentSession startSession({
    required String learnerId,
    List<String>? objectiveIds,
    List<String>? questionIds,
    String? sessionId,
  }) {
    final session = super.startSession(
      learnerId: learnerId,
      objectiveIds: objectiveIds,
      questionIds: questionIds,
      sessionId: sessionId,
    );
    _storedSessions[session.sessionId] = session;
    final box = _box;
    if (box != null && box.isOpen) {
      box.put(session.sessionId, jsonEncode(session.toJson()));
    }
    return session;
  }

  @override
  AssessmentSession addAttemptToSession({
    required String sessionId,
    required QuestionAttempt attempt,
  }) {
    final session = super.addAttemptToSession(
      sessionId: sessionId,
      attempt: attempt,
    );
    _storedSessions[sessionId] = session;
    final box = _box;
    if (box != null && box.isOpen) {
      box.put(session.sessionId, jsonEncode(session.toJson()));
    }
    return session;
  }

  @override
  AssessmentSession completeSession(
    String sessionId, {
    DateTime? completionTime,
  }) {
    final session = super.completeSession(
      sessionId,
      completionTime: completionTime,
    );
    _storedSessions[sessionId] = session;
    final box = _box;
    if (box != null && box.isOpen) {
      box.put(session.sessionId, jsonEncode(session.toJson()));
    }
    return session;
  }

  @override
  AssessmentSession? getSession(String sessionId) {
    return super.getSession(sessionId) ?? _storedSessions[sessionId];
  }

  @override
  List<AssessmentSession> getSessionsForLearner(String learnerId) {
    final baseSessions = super.getSessionsForLearner(learnerId);
    final map = <String, AssessmentSession>{};
    for (final s in _storedSessions.values) {
      if (s.learnerId == learnerId) {
        map[s.sessionId] = s;
      }
    }
    for (final s in baseSessions) {
      map[s.sessionId] = s;
    }
    final list = map.values.toList()
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    return List.unmodifiable(list);
  }

  @override
  void clear() {
    super.clear();
    _storedSessions.clear();
    final box = _box;
    if (box != null && box.isOpen) {
      box.clear();
    }
  }
}
