import 'package:meta/meta.dart';

/// Immutable domain model representing a learner's study state, goals, and history in TITAN.
@immutable
class LearnerProfile {
  /// Unique identifier of the learner.
  final String learnerId;

  /// Subjects preferred or prioritized by the learner (e.g. ['Polity', 'Economy']).
  final List<String> preferredSubjects;

  /// Topics already completed/mastered by the learner.
  final List<String> completedTopics;

  /// Topics identified as weak areas needing remediation.
  final List<String> weakTopics;

  /// Ordered list of knowledge item IDs or topic tags previously studied.
  final List<String> studyHistory;

  /// Current target goal or milestone (e.g. 'UPSC CSE 2026 Prelims').
  final String currentGoal;

  /// Constructs an immutable [LearnerProfile].
  LearnerProfile({
    required this.learnerId,
    List<String> preferredSubjects = const [],
    List<String> completedTopics = const [],
    List<String> weakTopics = const [],
    List<String> studyHistory = const [],
    this.currentGoal = 'UPSC CSE Prelims',
  })  : preferredSubjects = List<String>.unmodifiable(preferredSubjects),
        completedTopics = List<String>.unmodifiable(completedTopics),
        weakTopics = List<String>.unmodifiable(weakTopics),
        studyHistory = List<String>.unmodifiable(studyHistory);

  /// Creates a copy of this [LearnerProfile] with updated fields.
  LearnerProfile copyWith({
    String? learnerId,
    List<String>? preferredSubjects,
    List<String>? completedTopics,
    List<String>? weakTopics,
    List<String>? studyHistory,
    String? currentGoal,
  }) {
    return LearnerProfile(
      learnerId: learnerId ?? this.learnerId,
      preferredSubjects: preferredSubjects ?? this.preferredSubjects,
      completedTopics: completedTopics ?? this.completedTopics,
      weakTopics: weakTopics ?? this.weakTopics,
      studyHistory: studyHistory ?? this.studyHistory,
      currentGoal: currentGoal ?? this.currentGoal,
    );
  }

  /// Converts this [LearnerProfile] into a JSON-compatible Map.
  Map<String, dynamic> toMap() {
    return {
      'learnerId': learnerId,
      'preferredSubjects': preferredSubjects,
      'completedTopics': completedTopics,
      'weakTopics': weakTopics,
      'studyHistory': studyHistory,
      'currentGoal': currentGoal,
    };
  }

  /// Deserializes a [LearnerProfile] from a Map.
  factory LearnerProfile.fromMap(Map<String, dynamic> map) {
    return LearnerProfile(
      learnerId: (map['learnerId'] as String?) ?? '',
      preferredSubjects:
          List<String>.from(map['preferredSubjects'] as List? ?? const []),
      completedTopics:
          List<String>.from(map['completedTopics'] as List? ?? const []),
      weakTopics: List<String>.from(map['weakTopics'] as List? ?? const []),
      studyHistory: List<String>.from(map['studyHistory'] as List? ?? const []),
      currentGoal: (map['currentGoal'] as String?) ?? 'UPSC CSE Prelims',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LearnerProfile &&
        other.learnerId == learnerId &&
        _listEquals(other.preferredSubjects, preferredSubjects) &&
        _listEquals(other.completedTopics, completedTopics) &&
        _listEquals(other.weakTopics, weakTopics) &&
        _listEquals(other.studyHistory, studyHistory) &&
        other.currentGoal == currentGoal;
  }

  @override
  int get hashCode {
    return Object.hash(
      learnerId,
      Object.hashAll(preferredSubjects),
      Object.hashAll(completedTopics),
      Object.hashAll(weakTopics),
      Object.hashAll(studyHistory),
      currentGoal,
    );
  }

  @override
  String toString() {
    return 'LearnerProfile(learnerId: $learnerId, goal: $currentGoal, weakTopics: ${weakTopics.length})';
  }

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
