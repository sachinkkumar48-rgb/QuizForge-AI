library;

import 'package:meta/meta.dart';

/// Immutable container holding unparsed raw evidence payload received from a source.
@immutable
class RawEvidencePayload {
  final String sourceIdentifier;
  final dynamic rawContent;
  final String contentType;
  final Map<String, String> headers;
  final DateTime fetchedAt;
  final Map<String, dynamic> metadata;

  const RawEvidencePayload({
    required this.sourceIdentifier,
    required this.rawContent,
    this.contentType = 'text/html',
    this.headers = const {},
    required this.fetchedAt,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
        'sourceIdentifier': sourceIdentifier,
        'rawContent': rawContent.toString(),
        'contentType': contentType,
        'headers': headers,
        'fetchedAt': fetchedAt.toIso8601String(),
        'metadata': metadata,
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RawEvidencePayload &&
        other.sourceIdentifier == sourceIdentifier &&
        other.fetchedAt == fetchedAt;
  }

  @override
  int get hashCode => Object.hash(sourceIdentifier, fetchedAt);
}
