import 'dart:convert';

import 'package:titan_storage/titan_storage.dart';

import '../domain/entities/reader_document.dart';

/// Repository contract for the TITAN Reader document library.
abstract class DocumentLibraryRepository {
  /// Returns all library documents sorted for display: documents with a
  /// last-opened timestamp first (most recent first), then never-opened
  /// documents by newest addition.
  Future<List<ReaderDocument>> getAll();

  /// Returns the document with [id], or null when absent.
  Future<ReaderDocument?> getById(String id);

  /// Returns the document backed by [filePath], or null when absent.
  Future<ReaderDocument?> getByFilePath(String filePath);

  /// Inserts [document]. Replaces any existing entry with the same id.
  Future<void> save(ReaderDocument document);

  /// Removes the document with [id]. No-op when absent.
  Future<void> remove(String id);
}

/// [DocumentLibraryRepository] backed by the shared TITAN [StorageService].
///
/// The whole library is persisted as a single JSON collection. The library
/// is personal-scale (dozens to hundreds of entries), so single-key storage
/// keeps reads atomic and avoids index drift. No second storage engine is
/// introduced (TITAN storage policy).
class StorageDocumentLibraryRepository implements DocumentLibraryRepository {
  /// Storage namespace used for all reader library data.
  static const String namespace = 'titan.reader.library';

  /// Storage key holding the serialized library collection.
  static const String collectionKey = 'documents';

  final StorageService _storage;

  StorageDocumentLibraryRepository(this._storage);

  StorageKey get _key => const StorageKey(collectionKey, namespace: namespace);

  @override
  Future<List<ReaderDocument>> getAll() async {
    final documents = await _readAll();
    documents.sort(_displayOrder);
    return documents;
  }

  @override
  Future<ReaderDocument?> getById(String id) async {
    final documents = await _readAll();
    for (final document in documents) {
      if (document.id == id) return document;
    }
    return null;
  }

  @override
  Future<ReaderDocument?> getByFilePath(String filePath) async {
    final documents = await _readAll();
    for (final document in documents) {
      if (document.filePath == filePath) return document;
    }
    return null;
  }

  @override
  Future<void> save(ReaderDocument document) async {
    final documents = await _readAll();
    final index = documents.indexWhere((d) => d.id == document.id);
    if (index >= 0) {
      documents[index] = document;
    } else {
      documents.add(document);
    }
    await _writeAll(documents);
  }

  @override
  Future<void> remove(String id) async {
    final documents = await _readAll();
    documents.removeWhere((d) => d.id == id);
    await _writeAll(documents);
  }

  Future<List<ReaderDocument>> _readAll() async {
    final raw = await _storage.read<String>(_key);
    if (raw == null || raw.isEmpty) return <ReaderDocument>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException(
          'Reader library collection is malformed: expected JSON list.');
    }
    final result = <ReaderDocument>[];
    for (final item in decoded) {
      if (item is Map<String, Object?>) {
        // Skip malformed entries instead of failing the whole library.
        try {
          result.add(ReaderDocument.fromJson(item));
        } on FormatException {
          continue;
        }
      }
    }
    return result;
  }

  Future<void> _writeAll(List<ReaderDocument> documents) {
    final payload =
        jsonEncode(documents.map((d) => d.toJson()).toList(growable: false));
    return _storage.write<String>(_key, payload);
  }

  /// Display order: last-opened documents first (most recent first), then
  /// never-opened documents by newest addition. Deterministic tie-break by id.
  static int _displayOrder(ReaderDocument a, ReaderDocument b) {
    final aOpened = a.lastOpenedAt;
    final bOpened = b.lastOpenedAt;
    if (aOpened != null && bOpened != null) {
      final byOpened = bOpened.compareTo(aOpened);
      if (byOpened != 0) return byOpened;
      return a.id.compareTo(b.id);
    }
    if (aOpened != null) return -1;
    if (bOpened != null) return 1;
    final byAdded = b.addedAt.compareTo(a.addedAt);
    if (byAdded != 0) return byAdded;
    return a.id.compareTo(b.id);
  }
}
