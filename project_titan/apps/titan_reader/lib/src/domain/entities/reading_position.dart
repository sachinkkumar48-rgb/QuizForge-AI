import 'package:meta/meta.dart';

/// Immutable record of the last reading position inside a document.
///
/// Page numbers are 1-based. The position is always clamped to the valid
/// page range, which keeps restoration safe when a document's reported page
/// count changes between sessions.
@immutable
class ReadingPosition {
  /// Identifier of the [ReaderDocument] this position belongs to.
  final String documentId;

  /// 1-based page number last visible to the reader.
  final int pageNumber;

  /// Total pages known when the position was stored. Null if unknown.
  final int? totalPages;

  /// When the position was recorded. Injected by callers for deterministic
  /// behavior in tests.
  final DateTime updatedAt;

  ReadingPosition({
    required this.documentId,
    required int pageNumber,
    required this.updatedAt,
    this.totalPages,
  })  : assert(documentId.trim().isNotEmpty, 'documentId must not be blank'),
        assert(totalPages == null || totalPages > 0,
            'totalPages must be positive when known'),
        pageNumber = clampPage(pageNumber, totalPages);

  /// Clamps a raw page number into the valid 1-based range.
  static int clampPage(int raw, int? totalPages) {
    if (raw < 1) return 1;
    if (totalPages != null && raw > totalPages) return totalPages;
    return raw;
  }

  /// Returns a copy with the given fields replaced. The page number is
  /// re-clamped against the resulting total page count.
  ReadingPosition copyWith({int? pageNumber, int? totalPages}) {
    return ReadingPosition(
      documentId: documentId,
      pageNumber: pageNumber ?? this.pageNumber,
      totalPages: totalPages ?? this.totalPages,
      updatedAt: updatedAt,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'documentId': documentId,
      'pageNumber': pageNumber,
      'totalPages': totalPages,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Deserializes a [ReadingPosition] from its JSON representation.
  /// Throws [FormatException] on malformed required fields.
  factory ReadingPosition.fromJson(Map<String, Object?> json) {
    final documentId = json['documentId'];
    final pageNumber = json['pageNumber'];
    final updatedAt = json['updatedAt'];
    if (documentId is! String || pageNumber is! int || updatedAt is! String) {
      throw const FormatException(
          'ReadingPosition JSON requires documentId, pageNumber and '
          'updatedAt fields.');
    }
    final totalPages = json['totalPages'];
    return ReadingPosition(
      documentId: documentId,
      pageNumber: pageNumber,
      totalPages: totalPages is int ? totalPages : null,
      updatedAt: DateTime.parse(updatedAt),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadingPosition &&
          runtimeType == other.runtimeType &&
          documentId == other.documentId &&
          pageNumber == other.pageNumber &&
          totalPages == other.totalPages &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      Object.hash(documentId, pageNumber, totalPages, updatedAt);

  @override
  String toString() =>
      'ReadingPosition(documentId: $documentId, page: $pageNumber'
      '${totalPages != null ? '/$totalPages' : ''})';
}
