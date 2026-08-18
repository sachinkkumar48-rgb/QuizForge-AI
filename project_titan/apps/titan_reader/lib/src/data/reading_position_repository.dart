import 'dart:convert';

import 'package:titan_storage/titan_storage.dart';

import '../domain/entities/reading_position.dart';

/// Repository contract for per-document reading positions.
abstract class ReadingPositionRepository {
  /// Returns the stored position for [documentId], or null when the
  /// document has no recorded position yet.
  Future<ReadingPosition?> load(String documentId);

  /// Persists [position], replacing any previously stored position for the
  /// same document.
  Future<void> save(ReadingPosition position);

  /// Deletes the stored position for [documentId]. No-op when absent.
  Future<void> delete(String documentId);
}

/// [ReadingPositionRepository] backed by the shared TITAN [StorageService].
///
/// One storage entry per document inside the `titan.reader.positions`
/// namespace, serialized as JSON.
class StorageReadingPositionRepository implements ReadingPositionRepository {
  /// Storage namespace used for all reading positions.
  static const String namespace = 'titan.reader.positions';

  final StorageService _storage;

  StorageReadingPositionRepository(this._storage);

  StorageKey _keyFor(String documentId) =>
      StorageKey(documentId, namespace: namespace);

  @override
  Future<ReadingPosition?> load(String documentId) async {
    final raw = await _storage.read<String>(_keyFor(documentId));
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, Object?>) {
      throw FormatException(
          'Reading position entry is malformed for document "$documentId".');
    }
    return ReadingPosition.fromJson(decoded);
  }

  @override
  Future<void> save(ReadingPosition position) {
    final payload = jsonEncode(position.toJson());
    return _storage.write<String>(_keyFor(position.documentId), payload);
  }

  @override
  Future<void> delete(String documentId) {
    return _storage.delete(_keyFor(documentId));
  }
}
