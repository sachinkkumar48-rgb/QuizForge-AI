import 'package:flutter/foundation.dart';

import '../data/annotation_repository.dart';
import '../domain/entities/reader_annotation.dart';
import 'reader_undo_stack.dart';

/// Application service managing Reader markup annotations for one or more
/// open documents.
///
/// Mutations run through a Reader-scoped [ReaderUndoStack] and are persisted
/// to the [AnnotationRepository] after every transition, so annotations
/// survive application restarts.
class AnnotationService {
  AnnotationService({
    required AnnotationRepository repository,
    String Function(String prefix)? idGenerator,
  })  : _repository = repository,
        _idGenerator = idGenerator ?? _defaultIdGenerator;

  final AnnotationRepository _repository;
  final String Function(String prefix) _idGenerator;

  /// Undo/redo stack shared by all annotation operations of this service.
  final ReaderUndoStack undoStack = ReaderUndoStack();

  final Map<String, List<ReaderAnnotation>> _byDocument = {};
  final List<VoidCallback> _listeners = [];
  int _idSequence = 0;

  /// Loads the stored annotations for [documentId] into the in-memory cache.
  /// Calling it again replaces the cache and clears the undo stack for a
  /// clean document session.
  Future<void> preload(String documentId) async {
    final stored = List.of(await _repository.load(documentId));
    stored.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    _byDocument[documentId] = List.of(stored);
    undoStack.clear();
    _notify();
  }

  /// Synchronous view of the cached annotations for [documentId] in creation
  /// order. Empty until [preload] completes.
  List<ReaderAnnotation> annotationsFor(String documentId) =>
      List.unmodifiable(_byDocument[documentId] ?? const []);

  /// Annotations of [documentId] located on [pageNumber].
  List<ReaderAnnotation> annotationsOnPage(String documentId, int pageNumber) =>
      annotationsFor(documentId)
          .where((a) => a.pageNumber == pageNumber)
          .toList();

  /// Adds [annotation] and persists the change. Undoable.
  Future<void> addAnnotation(ReaderAnnotation annotation) async {
    final list = _listFor(annotation.documentId);
    undoStack.perform(ReaderOperation(
      label: 'Add ${annotation.type.name}',
      scope: annotation.documentId,
      apply: () => list.add(annotation),
      revert: () => list.remove(annotation),
    ));
    await _persist(annotation.documentId);
  }

  /// Changes the color of the annotation identified by [annotationId].
  /// Undoable. Returns the updated annotation, or null when not found.
  Future<ReaderAnnotation?> changeColor({
    required String documentId,
    required String annotationId,
    required ReaderAnnotationColor color,
    required DateTime at,
  }) async {
    final list = _listFor(documentId);
    final index = list.indexWhere((a) => a.id == annotationId);
    if (index < 0) return null;
    final previous = list[index];
    if (previous.color == color) return previous;
    final updated = previous.copyWith(color: color, updatedAt: at);
    undoStack.perform(ReaderOperation(
      label: 'Recolor ${previous.type.name}',
      scope: documentId,
      apply: () {
        final i = list.indexWhere((a) => a.id == annotationId);
        if (i >= 0) list[i] = updated;
      },
      revert: () {
        final i = list.indexWhere((a) => a.id == annotationId);
        if (i >= 0) list[i] = previous;
      },
    ));
    await _persist(documentId);
    return updated;
  }

  /// Removes the annotation identified by [annotationId]. Undoable.
  /// Returns the removed annotation, or null when not found.
  Future<ReaderAnnotation?> removeAnnotation({
    required String documentId,
    required String annotationId,
  }) async {
    final list = _listFor(documentId);
    final index = list.indexWhere((a) => a.id == annotationId);
    if (index < 0) return null;
    final removed = list[index];
    final removedIndex = index;
    undoStack.perform(ReaderOperation(
      label: 'Remove ${removed.type.name}',
      scope: documentId,
      apply: () => list.remove(removed),
      revert: () => list.insert(removedIndex.clamp(0, list.length), removed),
    ));
    await _persist(documentId);
    return removed;
  }

  /// Undoes the latest annotation operation and persists the result.
  Future<bool> undo() async {
    final scope = undoStack.peekUndo?.scope;
    if (!undoStack.undo()) return false;
    if (scope != null) await _persist(scope);
    return true;
  }

  /// Redoes the latest undone annotation operation and persists the result.
  Future<bool> redo() async {
    final scope = undoStack.peekRedo?.scope;
    if (!undoStack.redo()) return false;
    if (scope != null) await _persist(scope);
    return true;
  }

  /// Deletes every stored annotation of [documentId] and clears its cache.
  /// Not undoable; used when a document is removed from the library.
  Future<void> clearDocument(String documentId) async {
    _byDocument.remove(documentId);
    undoStack.clear();
    await _repository.deleteDocument(documentId);
    _notify();
  }

  /// Generates a new unique annotation id.
  String nextId() => _idGenerator('ann_${_idSequence++}');

  /// Registers a listener notified on every mutation and load.
  void addListener(VoidCallback listener) => _listeners.add(listener);

  /// Removes a previously registered listener.
  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  List<ReaderAnnotation> _listFor(String documentId) =>
      _byDocument.putIfAbsent(documentId, () => <ReaderAnnotation>[]);

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
      'ann_${DateTime.now().microsecondsSinceEpoch}_$seed';
}
