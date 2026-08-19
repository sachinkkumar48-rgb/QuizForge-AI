import 'package:meta/meta.dart';

/// Application-managed bookmark created by the user inside TITAN Reader.
///
/// Deliberately separate from PDF-native outline entries: outline entries are
/// read from the document at runtime and are never persisted here, while
/// application bookmarks live in Reader storage and survive restarts.
@immutable
class ReaderBookmark {
  /// Stable unique identifier.
  final String id;

  /// Identifier of the owning document entry.
  final String documentId;

  /// 1-based page the bookmark points to.
  final int pageNumber;

  /// User-editable display title. Defaults to a page reference when created
  /// without an explicit title.
  final String title;

  /// Creation timestamp. Injected by callers for deterministic tests.
  final DateTime createdAt;

  /// Last modification timestamp.
  final DateTime updatedAt;

  const ReaderBookmark({
    required this.id,
    required this.documentId,
    required this.pageNumber,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  }) : assert(pageNumber >= 1, 'pageNumber must be >= 1');

  /// Returns a copy with the given fields replaced.
  ReaderBookmark copyWith({
    String? title,
    int? pageNumber,
    DateTime? updatedAt,
  }) {
    return ReaderBookmark(
      id: id,
      documentId: documentId,
      pageNumber: pageNumber ?? this.pageNumber,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'documentId': documentId,
        'pageNumber': pageNumber,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// Deserializes a [ReaderBookmark]; throws [FormatException] on malformed
  /// required fields.
  factory ReaderBookmark.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final documentId = json['documentId'];
    final pageNumber = json['pageNumber'];
    final title = json['title'];
    final createdAt = json['createdAt'];
    final updatedAt = json['updatedAt'];
    if (id is! String ||
        documentId is! String ||
        pageNumber is! int ||
        title is! String ||
        createdAt is! String ||
        updatedAt is! String) {
      throw const FormatException(
          'ReaderBookmark JSON requires id, documentId, pageNumber, title, '
          'createdAt and updatedAt fields.');
    }
    return ReaderBookmark(
      id: id,
      documentId: documentId,
      pageNumber: pageNumber,
      title: title,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReaderBookmark &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          documentId == other.documentId &&
          pageNumber == other.pageNumber &&
          title == other.title &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      Object.hash(id, documentId, pageNumber, title, createdAt, updatedAt);

  @override
  String toString() => 'ReaderBookmark(id: $id, page: $pageNumber, "$title")';
}

/// Read-only entry of the PDF document's native outline (a.k.a. PDF
/// bookmarks), surfaced alongside application bookmarks but never persisted.
@immutable
class ReaderOutlineEntry {
  /// Outline title as stored inside the PDF.
  final String title;

  /// 1-based destination page when the engine could resolve it; null when the
  /// destination uses a non-page target.
  final int? pageNumber;

  /// Engine-agnostic navigation key (slash separated sibling indices, e.g.
  /// "0/2/1"). The viewer handle resolves the key back to the concrete
  /// destination without leaking engine types into the domain.
  final String path;

  /// Nested outline entries.
  final List<ReaderOutlineEntry> children;

  const ReaderOutlineEntry({
    required this.title,
    required this.path,
    this.pageNumber,
    this.children = const [],
  });

  @override
  String toString() => 'ReaderOutlineEntry("$title", page: $pageNumber, '
      'path: $path, children: ${children.length})';
}
