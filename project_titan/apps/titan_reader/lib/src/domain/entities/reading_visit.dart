import 'package:meta/meta.dart';

/// A single visit entry in the reading history.
@immutable
class ReadingVisit {
  /// Identifier of the visited [ReaderDocument].
  final String documentId;

  /// When the document was opened. Injected by callers for deterministic
  /// behavior in tests.
  final DateTime visitedAt;

  const ReadingVisit({required this.documentId, required this.visitedAt})
      : assert(documentId != '', 'documentId must not be blank');

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'documentId': documentId,
      'visitedAt': visitedAt.toIso8601String(),
    };
  }

  /// Deserializes a [ReadingVisit] from its JSON representation.
  /// Throws [FormatException] on malformed required fields.
  factory ReadingVisit.fromJson(Map<String, Object?> json) {
    final documentId = json['documentId'];
    final visitedAt = json['visitedAt'];
    if (documentId is! String || visitedAt is! String) {
      throw const FormatException(
          'ReadingVisit JSON requires documentId and visitedAt fields.');
    }
    return ReadingVisit(
      documentId: documentId,
      visitedAt: DateTime.parse(visitedAt),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadingVisit &&
          runtimeType == other.runtimeType &&
          documentId == other.documentId &&
          visitedAt == other.visitedAt;

  @override
  int get hashCode => Object.hash(documentId, visitedAt);

  @override
  String toString() =>
      'ReadingVisit(documentId: $documentId, visitedAt: $visitedAt)';
}
