import 'package:flutter/foundation.dart';

import '../data/note_repository.dart';
import '../domain/entities/reader_note.dart';
import 'reader_undo_stack.dart';

/// Application service managing notes for TITAN Reader.
///
/// Notes associate loosely with documents, pages, selections and annotations;
/// deleting a referenced annotation never invalidates the note itself.
class NoteService {
  NoteService({
    required NoteRepository repository,
    String Function(String prefix)? idGenerator,
  })  : _repository = repository,
        _idGenerator = idGenerator ?? _defaultIdGenerator;

  final NoteRepository _repository;
  final String Function(String prefix) _idGenerator;

  /// Undo/redo stack shared by all note operations of this service.
  final ReaderUndoStack undoStack = ReaderUndoStack();

  final Map<String, List<ReaderNote>> _byDocument = {};
  final List<VoidCallback> _listeners = [];
  int _idSequence = 0;

  /// Loads the stored notes for [documentId] into the in-memory cache and
  /// clears the undo stack for a clean document session.
  Future<void> preload(String documentId) async {
    final stored = List.of(await _repository.load(documentId));
    stored.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    _byDocument[documentId] = List.of(stored);
    undoStack.clear();
    _notify();
  }

  /// Synchronous view of the cached notes for [documentId] in creation order.
  List<ReaderNote> notesFor(String documentId) =>
      List.unmodifiable(_byDocument[documentId] ?? const []);

  /// Notes of [documentId] matching [query] in title, content or referenced
  /// selection. Empty query returns all notes.
  List<ReaderNote> searchNotes(String documentId, String query) {
    final all = notesFor(documentId);
    if (query.trim().isEmpty) return all;
    return all.where((note) => note.matches(query)).toList();
  }

  /// Adds [note] and persists the change. Undoable.
  Future<void> addNote(ReaderNote note) async {
    final list = _listFor(note.documentId);
    undoStack.perform(ReaderOperation(
      label: 'Add note',
      scope: note.documentId,
      apply: () => list.add(note),
      revert: () => list.remove(note),
    ));
    await _persist(note.documentId);
  }

  /// Updates title/content of the note identified by [noteId]. Undoable.
  /// Returns the updated note, or null when not found.
  Future<ReaderNote?> updateNote({
    required String documentId,
    required String noteId,
    required DateTime at,
    String? title,
    String? content,
  }) async {
    final list = _listFor(documentId);
    final index = list.indexWhere((n) => n.id == noteId);
    if (index < 0) return null;
    final previous = list[index];
    final updated =
        previous.copyWith(title: title, content: content, updatedAt: at);
    if (updated == previous) return previous;
    undoStack.perform(ReaderOperation(
      label: 'Edit note',
      scope: documentId,
      apply: () {
        final i = list.indexWhere((n) => n.id == noteId);
        if (i >= 0) list[i] = updated;
      },
      revert: () {
        final i = list.indexWhere((n) => n.id == noteId);
        if (i >= 0) list[i] = previous;
      },
    ));
    await _persist(documentId);
    return updated;
  }

  /// Removes the note identified by [noteId]. Undoable. Returns the removed
  /// note, or null when not found.
  Future<ReaderNote?> removeNote({
    required String documentId,
    required String noteId,
  }) async {
    final list = _listFor(documentId);
    final index = list.indexWhere((n) => n.id == noteId);
    if (index < 0) return null;
    final removed = list[index];
    final removedIndex = index;
    undoStack.perform(ReaderOperation(
      label: 'Remove note',
      scope: documentId,
      apply: () => list.remove(removed),
      revert: () => list.insert(removedIndex.clamp(0, list.length), removed),
    ));
    await _persist(documentId);
    return removed;
  }

  /// Undoes the latest note operation and persists the result.
  Future<bool> undo() async {
    final scope = undoStack.peekUndo?.scope;
    if (!undoStack.undo()) return false;
    if (scope != null) await _persist(scope);
    return true;
  }

  /// Redoes the latest undone note operation and persists the result.
  Future<bool> redo() async {
    final scope = undoStack.peekRedo?.scope;
    if (!undoStack.redo()) return false;
    if (scope != null) await _persist(scope);
    return true;
  }

  /// Deletes every stored note of [documentId]. Not undoable.
  Future<void> clearDocument(String documentId) async {
    _byDocument.remove(documentId);
    undoStack.clear();
    await _repository.deleteDocument(documentId);
    _notify();
  }

  /// Generates a new unique note id.
  String nextId() => _idGenerator('note_${_idSequence++}');

  void addListener(VoidCallback listener) => _listeners.add(listener);

  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  List<ReaderNote> _listFor(String documentId) =>
      _byDocument.putIfAbsent(documentId, () => <ReaderNote>[]);

  Future<void> _persist(String documentId) async {
    await _repository.saveAll(
        documentId, List.unmodifiable(_byDocument[documentId] ?? const []));
    _notify();
  }

  void _notify() {
    for (final listener in List<VoidCallback>.of(_listeners)) {
      listener();
    }
  }

  static String _defaultIdGenerator(String seed) =>
      'note_${DateTime.now().microsecondsSinceEpoch}_$seed';
}
