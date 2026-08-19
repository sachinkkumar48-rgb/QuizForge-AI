import 'package:flutter/foundation.dart';

/// A single reversible Reader operation.
///
/// [apply] performs (or re-applies) the operation, [revert] undoes it.
/// Both callbacks are synchronous state mutations; persistence is handled by
/// the owning service after each transition.
class ReaderOperation {
  /// Short human-readable label, e.g. "Add highlight" (for UI/diagnostics).
  final String label;

  final VoidCallback apply;
  final VoidCallback revert;

  /// Opaque scope tag (e.g. the affected document id) retained so the owning
  /// service knows what to persist after undo/redo.
  final String? scope;

  const ReaderOperation({
    required this.label,
    required this.apply,
    required this.revert,
    this.scope,
  });
}

/// Reader-scoped undo/redo stack.
///
/// Deliberately simple and local to TITAN Reader: operations are pushed with
/// inverse closures, undo reverts the latest operation and moves it to the
/// redo stack, and any new operation clears the redo stack. There is no
/// global application undo framework.
class ReaderUndoStack {
  ReaderUndoStack({this.capacity = 100})
      : assert(capacity > 0, 'capacity must be positive');

  /// Maximum number of undoable operations retained.
  final int capacity;

  final List<ReaderOperation> _undoStack = [];
  final List<ReaderOperation> _redoStack = [];
  final List<VoidCallback> _listeners = [];

  bool get canUndo => _undoStack.isNotEmpty;

  bool get canRedo => _redoStack.isNotEmpty;

  /// Label of the operation that would be undone next, if any.
  String? get undoLabel => _undoStack.isEmpty ? null : _undoStack.last.label;

  /// Label of the operation that would be redone next, if any.
  String? get redoLabel => _redoStack.isEmpty ? null : _redoStack.last.label;

  /// The operation that would be undone next, if any.
  ReaderOperation? get peekUndo => _undoStack.isEmpty ? null : _undoStack.last;

  /// The operation that would be redone next, if any.
  ReaderOperation? get peekRedo => _redoStack.isEmpty ? null : _redoStack.last;

  /// Executes [operation] and pushes it onto the undo stack, clearing the
  /// redo stack.
  void perform(ReaderOperation operation) {
    operation.apply();
    _undoStack.add(operation);
    if (_undoStack.length > capacity) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
    _notify();
  }

  /// Reverts the most recent operation. Returns true when something was
  /// undone.
  bool undo() {
    if (_undoStack.isEmpty) return false;
    final operation = _undoStack.removeLast();
    operation.revert();
    _redoStack.add(operation);
    _notify();
    return true;
  }

  /// Re-applies the most recently undone operation. Returns true when
  /// something was redone.
  bool redo() {
    if (_redoStack.isEmpty) return false;
    final operation = _redoStack.removeLast();
    operation.apply();
    _undoStack.add(operation);
    _notify();
    return true;
  }

  /// Clears both stacks, e.g. when the document changes.
  void clear() {
    if (_undoStack.isEmpty && _redoStack.isEmpty) return;
    _undoStack.clear();
    _redoStack.clear();
    _notify();
  }

  void addListener(VoidCallback listener) => _listeners.add(listener);

  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  void _notify() {
    for (final listener in List<VoidCallback>.of(_listeners)) {
      listener();
    }
  }
}
