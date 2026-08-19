import 'dart:convert';

import 'package:titan_storage/titan_storage.dart';

import '../domain/entities/reader_note.dart';

/// Repository contract for Reader notes.
abstract class NoteRepository {
  /// Returns all stored notes for [documentId], ordered by creation time.
  Future<List<ReaderNote>> load(String documentId);

  /// Replaces the stored note list for [documentId].
  Future<void> saveAll(String documentId, List<ReaderNote> notes);

  /// Deletes every stored note for [documentId]. No-op when absent.
  Future<void> deleteDocument(String documentId);
}

/// [NoteRepository] backed by the shared TITAN [StorageService].
///
/// One storage entry per document inside the Reader-specific
/// `titan.reader.notes` namespace.
class StorageNoteRepository implements NoteRepository {
  /// Storage namespace used for all Reader notes.
  static const String namespace = 'titan.reader.notes';

  final StorageService _storage;

  StorageNoteRepository(this._storage);

  StorageKey _keyFor(String documentId) =>
      StorageKey(documentId, namespace: namespace);

  @override
  Future<List<ReaderNote>> load(String documentId) async {
    final raw = await _storage.read<String>(_keyFor(documentId));
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw FormatException(
          'Note store is malformed for document "$documentId".');
    }
    return decoded
        .whereType<Map<String, Object?>>()
        .map(ReaderNote.fromJson)
        .toList();
  }

  @override
  Future<void> saveAll(String documentId, List<ReaderNote> notes) {
    final payload = jsonEncode(notes.map((n) => n.toJson()).toList());
    return _storage.write<String>(_keyFor(documentId), payload);
  }

  @override
  Future<void> deleteDocument(String documentId) {
    return _storage.delete(_keyFor(documentId));
  }
}
