import 'package:meta/meta.dart';

/// Immutable domain entity aggregating rich context assembled across all 8 TITAN modules.
@immutable
class MentorContext {
  final String userId;
  final String userName;
  final String targetExam;
  final List<String> weakSubjects;
  final List<String> strongSubjects;
  final List<String> recentSearchQueries;
  final int pendingRevisionsCount;
  final String? recommendedTopic;
  final double studyHoursTarget;
  final double studyHoursCompleted;
  final double accuracyRate;
  final Map<String, dynamic> metadata;

  MentorContext({
    required this.userId,
    required this.userName,
    this.targetExam = 'UPSC CSE',
    List<String>? weakSubjects,
    List<String>? strongSubjects,
    List<String>? recentSearchQueries,
    this.pendingRevisionsCount = 0,
    this.recommendedTopic,
    this.studyHoursTarget = 6.0,
    this.studyHoursCompleted = 0.0,
    this.accuracyRate = 0.0,
    Map<String, dynamic>? metadata,
  })  : weakSubjects = List<String>.unmodifiable(weakSubjects ?? []),
        strongSubjects = List<String>.unmodifiable(strongSubjects ?? []),
        recentSearchQueries =
            List<String>.unmodifiable(recentSearchQueries ?? []),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? {});

  factory MentorContext.empty({String userId = 'guest'}) => MentorContext(
        userId: userId,
        userName: 'Learner',
      );

  MentorContext copyWith({
    String? userId,
    String? userName,
    String? targetExam,
    List<String>? weakSubjects,
    List<String>? strongSubjects,
    List<String>? recentSearchQueries,
    int? pendingRevisionsCount,
    String? recommendedTopic,
    double? studyHoursTarget,
    double? studyHoursCompleted,
    double? accuracyRate,
    Map<String, dynamic>? metadata,
  }) {
    return MentorContext(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      targetExam: targetExam ?? this.targetExam,
      weakSubjects: weakSubjects ?? this.weakSubjects,
      strongSubjects: strongSubjects ?? this.strongSubjects,
      recentSearchQueries: recentSearchQueries ?? this.recentSearchQueries,
      pendingRevisionsCount:
          pendingRevisionsCount ?? this.pendingRevisionsCount,
      recommendedTopic: recommendedTopic ?? this.recommendedTopic,
      studyHoursTarget: studyHoursTarget ?? this.studyHoursTarget,
      studyHoursCompleted: studyHoursCompleted ?? this.studyHoursCompleted,
      accuracyRate: accuracyRate ?? this.accuracyRate,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'userName': userName,
        'targetExam': targetExam,
        'weakSubjects': weakSubjects,
        'strongSubjects': strongSubjects,
        'recentSearchQueries': recentSearchQueries,
        'pendingRevisionsCount': pendingRevisionsCount,
        'recommendedTopic': recommendedTopic,
        'studyHoursTarget': studyHoursTarget,
        'studyHoursCompleted': studyHoursCompleted,
        'accuracyRate': accuracyRate,
        'metadata': metadata,
      };

  factory MentorContext.fromJson(Map<String, dynamic> json) => MentorContext(
        userId: json['userId'] as String,
        userName: json['userName'] as String,
        targetExam: json['targetExam'] as String? ?? 'UPSC CSE',
        weakSubjects: (json['weakSubjects'] as List? ?? []).cast<String>(),
        strongSubjects: (json['strongSubjects'] as List? ?? []).cast<String>(),
        recentSearchQueries:
            (json['recentSearchQueries'] as List? ?? []).cast<String>(),
        pendingRevisionsCount: json['pendingRevisionsCount'] as int? ?? 0,
        recommendedTopic: json['recommendedTopic'] as String?,
        studyHoursTarget: (json['studyHoursTarget'] as num? ?? 6.0).toDouble(),
        studyHoursCompleted:
            (json['studyHoursCompleted'] as num? ?? 0.0).toDouble(),
        accuracyRate: (json['accuracyRate'] as num? ?? 0.0).toDouble(),
        metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MentorContext &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          userName == other.userName &&
          targetExam == other.targetExam;

  @override
  int get hashCode => Object.hash(userId, userName, targetExam);
}
