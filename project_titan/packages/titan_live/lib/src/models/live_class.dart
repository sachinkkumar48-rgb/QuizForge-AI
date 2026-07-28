import 'package:meta/meta.dart';
import 'session_schedule.dart';
import 'live_session.dart';
import 'recording.dart';

/// Primary immutable domain model representing a Live Class in Project TITAN.
@immutable
class LiveClass {
  final String id;
  final String title;
  final String description;
  final String subjectCategory;
  final String instructorId;
  final String instructorName;
  final SessionSchedule schedule;
  final LiveSession? activeSession;
  final Recording? recording;
  final List<String> knowledgeNodeIds;
  final DateTime createdAt;

  LiveClass({
    required this.id,
    required this.title,
    required this.description,
    required this.subjectCategory,
    required this.instructorId,
    required this.instructorName,
    required this.schedule,
    this.activeSession,
    this.recording,
    required List<String> knowledgeNodeIds,
    required this.createdAt,
  }) : knowledgeNodeIds = List<String>.unmodifiable(knowledgeNodeIds);

  LiveClass copyWith({
    String? id,
    String? title,
    String? description,
    String? subjectCategory,
    String? instructorId,
    String? instructorName,
    SessionSchedule? schedule,
    LiveSession? activeSession,
    Recording? recording,
    List<String>? knowledgeNodeIds,
    DateTime? createdAt,
  }) {
    return LiveClass(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      subjectCategory: subjectCategory ?? this.subjectCategory,
      instructorId: instructorId ?? this.instructorId,
      instructorName: instructorName ?? this.instructorName,
      schedule: schedule ?? this.schedule,
      activeSession: activeSession ?? this.activeSession,
      recording: recording ?? this.recording,
      knowledgeNodeIds: knowledgeNodeIds ?? this.knowledgeNodeIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'subjectCategory': subjectCategory,
        'instructorId': instructorId,
        'instructorName': instructorName,
        'schedule': schedule.toJson(),
        'activeSession': activeSession?.toJson(),
        'recording': recording?.toJson(),
        'knowledgeNodeIds': knowledgeNodeIds,
        'createdAt': createdAt.toIso8601String(),
      };

  factory LiveClass.fromJson(Map<String, dynamic> json) => LiveClass(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        subjectCategory: json['subjectCategory'] as String,
        instructorId: json['instructorId'] as String,
        instructorName: json['instructorName'] as String,
        schedule: SessionSchedule.fromJson(
            Map<String, dynamic>.from(json['schedule'] as Map)),
        activeSession: json['activeSession'] != null
            ? LiveSession.fromJson(
                Map<String, dynamic>.from(json['activeSession'] as Map))
            : null,
        recording: json['recording'] != null
            ? Recording.fromJson(
                Map<String, dynamic>.from(json['recording'] as Map))
            : null,
        knowledgeNodeIds:
            (json['knowledgeNodeIds'] as List? ?? []).cast<String>(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LiveClass &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          instructorId == other.instructorId &&
          schedule == other.schedule;

  @override
  int get hashCode => Object.hash(id, title, instructorId, schedule);
}
