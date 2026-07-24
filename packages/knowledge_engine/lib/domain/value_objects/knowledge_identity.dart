import 'package:meta/meta.dart';

/// Immutable value object representing a stable, canonical, versioned identity
/// for a Knowledge Object or Knowledge Entity in Project TITAN.
@immutable
class KnowledgeIdentity {
  /// Primary canonical identifier (e.g. 'cko_polity_001').
  final String canonicalId;

  /// Underlying source identifier (e.g. 'pdf_upsc_2026_ch1', 'pyq_2025_q14').
  final String sourceId;

  /// Entity schema or revision version number.
  final int version;

  /// Timestamp when this identity record was created or registered.
  final DateTime timestamp;

  /// Constructs an immutable [KnowledgeIdentity].
  KnowledgeIdentity({
    required this.canonicalId,
    required this.sourceId,
    this.version = 1,
    DateTime? timestamp,
  })  : assert(canonicalId.trim().isNotEmpty, 'canonicalId cannot be empty'),
        assert(sourceId.trim().isNotEmpty, 'sourceId cannot be empty'),
        assert(version > 0, 'version must be positive'),
        timestamp = timestamp ?? DateTime.now();

  /// Creates a copy of this [KnowledgeIdentity] with modified attributes.
  KnowledgeIdentity copyWith({
    String? canonicalId,
    String? sourceId,
    int? version,
    DateTime? timestamp,
  }) {
    return KnowledgeIdentity(
      canonicalId: canonicalId ?? this.canonicalId,
      sourceId: sourceId ?? this.sourceId,
      version: version ?? this.version,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Converts this [KnowledgeIdentity] into a Map for serialization.
  Map<String, dynamic> toMap() {
    return {
      'canonicalId': canonicalId,
      'sourceId': sourceId,
      'version': version,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Deserializes a [KnowledgeIdentity] from a Map.
  factory KnowledgeIdentity.fromMap(Map<String, dynamic> map) {
    return KnowledgeIdentity(
      canonicalId: map['canonicalId'] as String,
      sourceId: map['sourceId'] as String,
      version: map['version'] as int? ?? 1,
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'] as String)
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KnowledgeIdentity &&
        other.canonicalId == canonicalId &&
        other.sourceId == sourceId &&
        other.version == version &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(canonicalId, sourceId, version, timestamp);
  }

  @override
  String toString() {
    return 'KnowledgeIdentity(canonicalId: $canonicalId, sourceId: $sourceId, v$version)';
  }
}
