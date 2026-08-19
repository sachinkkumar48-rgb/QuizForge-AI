import 'dart:convert';

import 'package:titan_storage/titan_storage.dart';

import '../domain/entities/reader_annotation.dart';

/// Repository contract for Reader-managed markup annotations.
///
/// Annotations are stored per document; the whole annotation list of one
/// document is persisted atomically as a single JSON entry.
abstract class AnnotationRepository {
  /// Returns all stored annotations for [documentId], ordered by creation
  /// time. Empty list when the document has no annotations.
  Future<List<ReaderAnnotation>> load(String documentId);

  /// Replaces the stored annotation list for [documentId].
  Future<void> saveAll(String documentId, List<ReaderAnnotation> annotations);

  /// Deletes every stored annotation for [documentId]. No-op when absent.
  Future<void> deleteDocument(String documentId);
}

/// [AnnotationRepository] backed by the shared TITAN [StorageService].
///
/// One storage entry per document inside the Reader-specific
/// `titan.reader.annotations` namespace.
class StorageAnnotationRepository implements AnnotationRepository {
  /// Storage namespace used for all Reader annotations.
  static const String namespace = 'titan.reader.annotations';

  final StorageService _storage;

  StorageAnnotationRepository(this._storage);

  StorageKey _keyFor(String documentId) =>
      StorageKey(documentId, namespace: namespace);

  @override
  Future<List<ReaderAnnotation>> load(String documentId) async {
    final raw = await _storage.read<String>(_keyFor(documentId));
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw FormatException(
          'Annotation store is malformed for document "$documentId".');
    }
    return decoded
        .whereType<Map<String, Object?>>()
        .map(ReaderAnnotation.fromJson)
        .toList();
  }

  @override
  Future<void> saveAll(String documentId, List<ReaderAnnotation> annotations) {
    final payload = jsonEncode(annotations.map((a) => a.toJson()).toList());
    return _storage.write<String>(_keyFor(documentId), payload);
  }

  @override
  Future<void> deleteDocument(String documentId) {
    return _storage.delete(_keyFor(documentId));
  }
}
