import 'package:meta/meta.dart';

/// Strongly typed key abstraction for storage entries in Project TITAN.
@immutable
class StorageKey {
  /// Unique string identifier for the storage key.
  final String rawKey;

  /// Optional namespace or domain partition for logical grouping.
  final String? namespace;

  const StorageKey(this.rawKey, {this.namespace});

  /// Full qualified key path combining namespace and raw key.
  String get qualifiedKey => namespace != null && namespace!.isNotEmpty
      ? '$namespace:$rawKey'
      : rawKey;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StorageKey &&
          runtimeType == other.runtimeType &&
          rawKey == other.rawKey &&
          namespace == other.namespace;

  @override
  int get hashCode => rawKey.hashCode ^ namespace.hashCode;

  @override
  String toString() => qualifiedKey;
}
