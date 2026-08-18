import 'package:meta/meta.dart';

import 'document_privacy_state.dart';

/// Immutable metadata describing a document managed by the TITAN Reader
/// library.
///
/// The entity never holds document content itself - only descriptive
/// metadata, the local file path and user-facing state. Content always stays
/// in the local file referenced by [filePath] (offline-first, LOCAL_ONLY by
/// default).
@immutable
class ReaderDocument {
  /// Stable unique identifier for the library entry.
  final String id;

  /// Display title. Defaults to the file name on import.
  final String title;

  /// Absolute path of the local PDF file backing this entry.
  final String filePath;

  /// File size in bytes at import time.
  final int sizeBytes;

  /// Total page count. Null until the document has been opened once and the
  /// engine reported the page count.
  final int? pageCount;

  /// When the document was added to the library. Injected by callers for
  /// deterministic behavior in tests.
  final DateTime addedAt;

  /// When the document was last opened. Null if never opened.
  final DateTime? lastOpenedAt;

  /// Whether the user marked this document as favorite.
  final bool isFavorite;

  /// Privacy classification. Always [DocumentPrivacyState.localOnly] at
  /// import time.
  final DocumentPrivacyState privacyState;

  const ReaderDocument({
    required this.id,
    required this.title,
    required this.filePath,
    required this.sizeBytes,
    required this.addedAt,
    this.pageCount,
    this.lastOpenedAt,
    this.isFavorite = false,
    this.privacyState = DocumentPrivacyState.localOnly,
  })  : assert(sizeBytes >= 0, 'sizeBytes must not be negative'),
        assert(pageCount == null || pageCount > 0,
            'pageCount must be positive when known');

  /// Returns a copy with the given fields replaced.
  ReaderDocument copyWith({
    String? title,
    int? pageCount,
    DateTime? lastOpenedAt,
    bool? isFavorite,
    DocumentPrivacyState? privacyState,
  }) {
    return ReaderDocument(
      id: id,
      title: title ?? this.title,
      filePath: filePath,
      sizeBytes: sizeBytes,
      addedAt: addedAt,
      pageCount: pageCount ?? this.pageCount,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      privacyState: privacyState ?? this.privacyState,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'title': title,
      'filePath': filePath,
      'sizeBytes': sizeBytes,
      'pageCount': pageCount,
      'addedAt': addedAt.toIso8601String(),
      'lastOpenedAt': lastOpenedAt?.toIso8601String(),
      'isFavorite': isFavorite,
      'privacyState': privacyState.wireName,
    };
  }

  /// Deserializes a [ReaderDocument] from its JSON representation.
  /// Throws [FormatException] on malformed required fields.
  factory ReaderDocument.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final title = json['title'];
    final filePath = json['filePath'];
    final sizeBytes = json['sizeBytes'];
    final addedAt = json['addedAt'];
    if (id is! String ||
        title is! String ||
        filePath is! String ||
        sizeBytes is! int ||
        addedAt is! String) {
      throw const FormatException(
          'ReaderDocument JSON requires id, title, filePath, sizeBytes and '
          'addedAt fields.');
    }
    final pageCount = json['pageCount'];
    final lastOpenedAt = json['lastOpenedAt'];
    return ReaderDocument(
      id: id,
      title: title,
      filePath: filePath,
      sizeBytes: sizeBytes,
      addedAt: DateTime.parse(addedAt),
      pageCount: pageCount is int ? pageCount : null,
      lastOpenedAt:
          lastOpenedAt is String ? DateTime.parse(lastOpenedAt) : null,
      isFavorite: json['isFavorite'] == true,
      privacyState: DocumentPrivacyStateX.fromWire(
          json['privacyState'] is String
              ? json['privacyState'] as String
              : null),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReaderDocument &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          filePath == other.filePath &&
          sizeBytes == other.sizeBytes &&
          pageCount == other.pageCount &&
          addedAt == other.addedAt &&
          lastOpenedAt == other.lastOpenedAt &&
          isFavorite == other.isFavorite &&
          privacyState == other.privacyState;

  @override
  int get hashCode => Object.hash(id, title, filePath, sizeBytes, pageCount,
      addedAt, lastOpenedAt, isFavorite, privacyState);

  @override
  String toString() => 'ReaderDocument(id: $id, title: $title)';
}
