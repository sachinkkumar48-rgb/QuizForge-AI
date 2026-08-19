import 'package:meta/meta.dart';

/// Free-form note attached to a document inside TITAN Reader.
///
/// Associations are intentionally loose: a note keeps a page reference and
/// optional selected-text / annotation references, but remains fully usable
/// when the referenced annotation is removed.
@immutable
class ReaderNote {
  /// Stable unique identifier.
  final String id;

  /// Identifier of the owning document entry.
  final String documentId;

  /// 1-based source page the note refers to.
  final int pageNumber;

  /// User-editable note title. May be empty.
  final String title;

  /// Note body text.
  final String content;

  /// Text the note was created from, when it originated from a selection.
  /// Null for free notes.
  final String? selectedText;

  /// Identifier of a related [ReaderAnnotation], when the note was created
  /// from one. The note stays valid if the annotation is deleted.
  final String? annotationId;

  /// Creation timestamp. Injected by callers for deterministic tests.
  final DateTime createdAt;

  /// Last modification timestamp.
  final DateTime updatedAt;

  const ReaderNote({
    required this.id,
    required this.documentId,
    required this.pageNumber,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.selectedText,
    this.annotationId,
  }) : assert(pageNumber >= 1, 'pageNumber must be >= 1');

  /// Whether [query] matches title, content or the referenced selection,
  /// case-insensitively. Empty queries match nothing.
  bool matches(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return false;
    return title.toLowerCase().contains(needle) ||
        content.toLowerCase().contains(needle) ||
        (selectedText?.toLowerCase().contains(needle) ?? false);
  }

  /// Returns a copy with the given fields replaced.
  ReaderNote copyWith({
    String? title,
    String? content,
    int? pageNumber,
    DateTime? updatedAt,
  }) {
    return ReaderNote(
      id: id,
      documentId: documentId,
      pageNumber: pageNumber ?? this.pageNumber,
      title: title ?? this.title,
      content: content ?? this.content,
      selectedText: selectedText,
      annotationId: annotationId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'documentId': documentId,
        'pageNumber': pageNumber,
        'title': title,
        'content': content,
        'selectedText': selectedText,
        'annotationId': annotationId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// Deserializes a [ReaderNote]; throws [FormatException] on malformed
  /// required fields.
  factory ReaderNote.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final documentId = json['documentId'];
    final pageNumber = json['pageNumber'];
    final title = json['title'];
    final content = json['content'];
    final createdAt = json['createdAt'];
    final updatedAt = json['updatedAt'];
    if (id is! String ||
        documentId is! String ||
        pageNumber is! int ||
        title is! String ||
        content is! String ||
        createdAt is! String ||
        updatedAt is! String) {
      throw const FormatException(
          'ReaderNote JSON requires id, documentId, pageNumber, title, '
          'content, createdAt and updatedAt fields.');
    }
    final selectedText = json['selectedText'];
    final annotationId = json['annotationId'];
    return ReaderNote(
      id: id,
      documentId: documentId,
      pageNumber: pageNumber,
      title: title,
      content: content,
      selectedText: selectedText is String ? selectedText : null,
      annotationId: annotationId is String ? annotationId : null,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReaderNote &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          documentId == other.documentId &&
          pageNumber == other.pageNumber &&
          title == other.title &&
          content == other.content &&
          selectedText == other.selectedText &&
          annotationId == other.annotationId &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(id, documentId, pageNumber, title, content,
      selectedText, annotationId, createdAt, updatedAt);

  @override
  String toString() => 'ReaderNote(id: $id, page: $pageNumber, "$title")';
}
