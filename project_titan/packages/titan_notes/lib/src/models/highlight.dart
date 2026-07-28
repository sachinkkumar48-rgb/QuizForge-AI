import 'package:meta/meta.dart';
import 'enums.dart';

/// Immutable domain model representing a highlighted snippet of text or media segment.
@immutable
class Highlight {
  final String id;
  final String contentId;
  final String highlightedText;
  final HighlightColor color;
  final int? startIndex;
  final int? endIndex;
  final int? timestampSeconds;
  final int? pageNumber;
  final String? note;
  final DateTime createdAt;

  const Highlight({
    required this.id,
    required this.contentId,
    required this.highlightedText,
    this.color = HighlightColor.yellow,
    this.startIndex,
    this.endIndex,
    this.timestampSeconds,
    this.pageNumber,
    this.note,
    required this.createdAt,
  });

  Highlight copyWith({
    String? id,
    String? contentId,
    String? highlightedText,
    HighlightColor? color,
    int? startIndex,
    int? endIndex,
    int? timestampSeconds,
    int? pageNumber,
    String? note,
    DateTime? createdAt,
  }) {
    return Highlight(
      id: id ?? this.id,
      contentId: contentId ?? this.contentId,
      highlightedText: highlightedText ?? this.highlightedText,
      color: color ?? this.color,
      startIndex: startIndex ?? this.startIndex,
      endIndex: endIndex ?? this.endIndex,
      timestampSeconds: timestampSeconds ?? this.timestampSeconds,
      pageNumber: pageNumber ?? this.pageNumber,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'contentId': contentId,
        'highlightedText': highlightedText,
        'color': color.name,
        'startIndex': startIndex,
        'endIndex': endIndex,
        'timestampSeconds': timestampSeconds,
        'pageNumber': pageNumber,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Highlight.fromJson(Map<String, dynamic> json) => Highlight(
        id: json['id'] as String,
        contentId: json['contentId'] as String,
        highlightedText: json['highlightedText'] as String,
        color: HighlightColor.values.firstWhere(
          (e) => e.name == json['color'],
          orElse: () => HighlightColor.yellow,
        ),
        startIndex: json['startIndex'] as int?,
        endIndex: json['endIndex'] as int?,
        timestampSeconds: json['timestampSeconds'] as int?,
        pageNumber: json['pageNumber'] as int?,
        note: json['note'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Highlight &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          contentId == other.contentId &&
          highlightedText == other.highlightedText &&
          color == other.color &&
          startIndex == other.startIndex &&
          endIndex == other.endIndex &&
          timestampSeconds == other.timestampSeconds &&
          pageNumber == other.pageNumber &&
          note == other.note &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        contentId,
        highlightedText,
        color,
        startIndex,
        endIndex,
        timestampSeconds,
        pageNumber,
        note,
        createdAt,
      );
}
