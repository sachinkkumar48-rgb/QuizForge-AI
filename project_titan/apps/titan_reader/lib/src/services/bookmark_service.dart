import 'package:flutter/foundation.dart';

import '../data/bookmark_repository.dart';
import '../domain/entities/reader_bookmark.dart';
import 'reader_undo_stack.dart';

/// Application service managing application bookmarks for TITAN Reader.
///
/// PDF-native outline entries are intentionally not handled here; they are
/// read from the document through the PDF engine abstraction at runtime.
class BookmarkService {
  BookmarkService({
    required BookmarkRepository repository,
    String Function(String prefix)? idGenerator,
  })  : _repository = repository,
        _idGenerator = idGenerator ?? _defaultIdGenerator;

  final BookmarkRepository _repository;
  final String Function(String prefix) _idGenerator;

  /// Undo/redo stack shared by all bookmark operations of this service.
  final ReaderUndoStack undoStack = ReaderUndoStack();

  final Map<String, List<ReaderBookmark>> _byDocument = {};
  final List<VoidCallback> _listeners = [];
  int _idSequence = 0;

  /// Loads the stored bookmarks for [documentId] into the in-memory cache and
  /// clears the undo stack for a clean document session.
  Future<void> preload(String documentId) async {
    final stored = List.of(await _repository.load(documentId));
    stored.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    _byDocument[documentId] = List.of(stored);
    undoStack.clear();
    _notify();
  }

  /// Synchronous view of the cached bookmarks for [documentId] in creation
  /// order.
  List<ReaderBookmark> bookmarksFor(String documentId) =>
      List.unmodifiable(_byDocument[documentId] ?? const []);

  /// The bookmark of [documentId] pointing to [pageNumber], or null.
  ReaderBookmark? bookmarkForPage(String documentId, int pageNumber) {
    for (final bookmark
        in _byDocument[documentId] ?? const <ReaderBookmark>[]) {
      if (bookmark.pageNumber == pageNumber) return bookmark;
    }
    return null;
  }

  /// Adds [bookmark] and persists the change. Undoable.
  Future<void> addBookmark(ReaderBookmark bookmark) async {
    final list = _listFor(bookmark.documentId);
    undoStack.perform(ReaderOperation(
      label: 'Add bookmark',
      scope: bookmark.documentId,
      apply: () => list.add(bookmark),
      revert: () => list.remove(bookmark),
    ));
    await _persist(bookmark.documentId);
  }

  /// Updates title and/or page of the bookmark identified by [bookmarkId].
  /// Undoable. Returns the updated bookmark, or null when not found.
  Future<ReaderBookmark?> updateBookmark({
    required String documentId,
    required String bookmarkId,
    required DateTime at,
    String? title,
    int? pageNumber,
  }) async {
    final list = _listFor(documentId);
    final index = list.indexWhere((b) => b.id == bookmarkId);
    if (index < 0) return null;
    final previous = list[index];
    final updated =
        previous.copyWith(title: title, pageNumber: pageNumber, updatedAt: at);
    if (updated == previous) return previous;
    undoStack.perform(ReaderOperation(
      label: 'Edit bookmark',
      scope: documentId,
      apply: () {
        final i = list.indexWhere((b) => b.id == bookmarkId);
        if (i >= 0) list[i] = updated;
      },
      revert: () {
        final i = list.indexWhere((b) => b.id == bookmarkId);
        if (i >= 0) list[i] = previous;
      },
    ));
    await _persist(documentId);
    return updated;
  }

  /// Removes the bookmark identified by [bookmarkId]. Undoable. Returns the
  /// removed bookmark, or null when not found.
  Future<ReaderBookmark?> removeBookmark({
    required String documentId,
    required String bookmarkId,
  }) async {
    final list = _listFor(documentId);
    final index = list.indexWhere((b) => b.id == bookmarkId);
    if (index < 0) return null;
    final removed = list[index];
    final removedIndex = index;
    undoStack.perform(ReaderOperation(
      label: 'Remove bookmark',
      scope: documentId,
      apply: () => list.remove(removed),
      revert: () => list.insert(removedIndex.clamp(0, list.length), removed),
    ));
    await _persist(documentId);
    return removed;
  }

  /// Undoes the latest bookmark operation and persists the result.
  Future<bool> undo() async {
    final scope = undoStack.peekUndo?.scope;
    if (!undoStack.undo()) return false;
    if (scope != null) await _persist(scope);
    return true;
  }

  /// Redoes the latest undone bookmark operation and persists the result.
  Future<bool> redo() async {
    final scope = undoStack.peekRedo?.scope;
    if (!undoStack.redo()) return false;
    if (scope != null) await _persist(scope);
    return true;
  }

  /// Deletes every stored bookmark of [documentId]. Not undoable.
  Future<void> clearDocument(String documentId) async {
    _byDocument.remove(documentId);
    undoStack.clear();
    await _repository.deleteDocument(documentId);
    _notify();
  }

  /// Generates a new unique bookmark id.
  String nextId() => _idGenerator('bm_${_idSequence++}');

  void addListener(VoidCallback listener) => _listeners.add(listener);

  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  List<ReaderBookmark> _listFor(String documentId) =>
      _byDocument.putIfAbsent(documentId, () => <ReaderBookmark>[]);

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
      'bm_${DateTime.now().microsecondsSinceEpoch}_$seed';
}
