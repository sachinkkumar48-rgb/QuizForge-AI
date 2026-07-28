import 'package:meta/meta.dart';

/// Immutable domain model representing cross-links to other notes, video timestamps, or concepts.
@immutable
class NoteReference {
  final String id;
  final String targetType; // 'note', 'video', 'pdf', 'concept', 'pyq'
  final String targetId;
  final String displayTitle;
  final int? timestampSeconds;
  final int? pageNumber;

  const NoteReference({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.displayTitle,
    this.timestampSeconds,
    this.pageNumber,
  });

  NoteReference copyWith({
    String? id,
    String? targetType,
    String? targetId,
    String? displayTitle,
    int? timestampSeconds,
    int? pageNumber,
  }) {
    return NoteReference(
      id: id ?? this.id,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      displayTitle: displayTitle ?? this.displayTitle,
      timestampSeconds: timestampSeconds ?? this.timestampSeconds,
      pageNumber: pageNumber ?? this.pageNumber,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'targetType': targetType,
        'targetId': targetId,
        'displayTitle': displayTitle,
        'timestampSeconds': timestampSeconds,
        'pageNumber': pageNumber,
      };

  factory NoteReference.fromJson(Map<String, dynamic> json) => NoteReference(
        id: json['id'] as String,
        targetType: json['targetType'] as String,
        targetId: json['targetId'] as String,
        displayTitle: json['displayTitle'] as String,
        timestampSeconds: json['timestampSeconds'] as int?,
        pageNumber: json['pageNumber'] as int?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteReference &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          targetType == other.targetType &&
          targetId == other.targetId &&
          displayTitle == other.displayTitle &&
          timestampSeconds == other.timestampSeconds &&
          pageNumber == other.pageNumber;

  @override
  int get hashCode => Object.hash(
      id, targetType, targetId, displayTitle, timestampSeconds, pageNumber);
}
