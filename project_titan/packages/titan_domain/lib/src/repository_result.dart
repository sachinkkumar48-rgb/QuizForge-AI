import 'package:meta/meta.dart';

/// Enumeration of data origins for repository results in Project TITAN.
enum RepositorySource {
  cache,
  network,
  ai,
  local,
}

/// Immutable generic model encapsulating data returned by a repository.
@immutable
class RepositoryResult<T> {
  final T? data;
  final RepositorySource source;
  final Map<String, Object?> metadata;
  final DateTime timestamp;

  RepositoryResult({
    this.data,
    required this.source,
    Map<String, Object?>? metadata,
    DateTime? timestamp,
  })  : metadata = Map<String, Object?>.unmodifiable(metadata ?? const {}),
        timestamp = timestamp ?? DateTime.now();

  const RepositoryResult.constResult({
    required this.data,
    required this.source,
    required this.metadata,
    required this.timestamp,
  });

  /// Convenience getter to verify presence of non-null data payload.
  bool get hasData => data != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepositoryResult<T> &&
          runtimeType == other.runtimeType &&
          data == other.data &&
          source == other.source &&
          metadata == other.metadata &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      data.hashCode ^ source.hashCode ^ metadata.hashCode ^ timestamp.hashCode;

  @override
  String toString() =>
      'RepositoryResult<$T>(source: ${source.name}, hasData: $hasData, timestamp: $timestamp)';
}
