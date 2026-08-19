import 'dart:convert';

import 'package:titan_storage/titan_storage.dart';

import '../domain/entities/reader_bookmark.dart';

/// Repository contract for application-managed bookmarks.
///
/// PDF-native outline entries are not stored here; they are read from the
/// document at runtime through the PDF engine abstraction.
abstract class BookmarkRepository {
  /// Returns all stored bookmarks for [documentId], ordered by creation time.
  Future<List<ReaderBookmark>> load(String documentId);

  /// Replaces the stored bookmark list for [documentId].
  Future<void> saveAll(String documentId, List<ReaderBookmark> bookmarks);

  /// Deletes every stored bookmark for [documentId]. No-op when absent.
  Future<void> deleteDocument(String documentId);
}

/// [BookmarkRepository] backed by the shared TITAN [StorageService].
///
/// One storage entry per document inside the Reader-specific
/// `titan.reader.bookmarks` namespace.
class StorageBookmarkRepository implements BookmarkRepository {
  /// Storage namespace used for all Reader bookmarks.
  static const String namespace = 'titan.reader.bookmarks';

  final StorageService _storage;

  StorageBookmarkRepository(this._storage);

  StorageKey _keyFor(String documentId) =>
      StorageKey(documentId, namespace: namespace);

  @override
  Future<List<ReaderBookmark>> load(String documentId) async {
    final raw = await _storage.read<String>(_keyFor(documentId));
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw FormatException(
          'Bookmark store is malformed for document "$documentId".');
    }
    return decoded
        .whereType<Map<String, Object?>>()
        .map(ReaderBookmark.fromJson)
        .toList();
  }

  @override
  Future<void> saveAll(String documentId, List<ReaderBookmark> bookmarks) {
    final payload = jsonEncode(bookmarks.map((b) => b.toJson()).toList());
    return _storage.write<String>(_keyFor(documentId), payload);
  }

  @override
  Future<void> deleteDocument(String documentId) {
    return _storage.delete(_keyFor(documentId));
  }
}
