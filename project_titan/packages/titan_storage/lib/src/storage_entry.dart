import 'package:meta/meta.dart';
import 'storage_key.dart';

/// Immutable model representing a single key-value record in storage with metadata.
@immutable
class StorageEntry<T> {
  final StorageKey key;
  final T value;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Generative constructor for [StorageEntry].
  StorageEntry({
    required this.key,
    required this.value,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  /// Const constructor requiring explicit timestamps.
  const StorageEntry.constEntry({
    required this.key,
    required this.value,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a copy of this [StorageEntry] with an updated value and new [updatedAt] timestamp.
  StorageEntry<T> copyWithUpdatedValue(T newValue, [DateTime? updateTime]) {
    return StorageEntry<T>.constEntry(
      key: key,
      value: newValue,
      createdAt: createdAt,
      updatedAt: updateTime ?? DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StorageEntry<T> &&
          runtimeType == other.runtimeType &&
          key == other.key &&
          value == other.value &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      key.hashCode ^ value.hashCode ^ createdAt.hashCode ^ updatedAt.hashCode;

  @override
  String toString() =>
      'StorageEntry<$T>(key: $key, value: $value, createdAt: $createdAt, updatedAt: $updatedAt)';
}
