import 'dart:async';

/// Lazy Loading Manager providing lazy singleton instantiation and on-demand proxy evaluation.
class LazyLoader<T> {
  final FutureOr<T> Function() _factory;
  T? _instance;
  bool _isInitializing = false;

  LazyLoader(this._factory);

  /// Returns true if the object has been initialized.
  bool get isInitialized => _instance != null;

  /// Gets or asynchronously creates the instance on first access.
  Future<T> get instance async {
    if (_instance != null) return _instance!;
    if (_isInitializing) {
      // Simple spin-wait / async delay until initial factory finishes
      while (_isInitializing && _instance == null) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      return _instance!;
    }
    _isInitializing = true;
    try {
      _instance = await _factory();
      return _instance!;
    } finally {
      _isInitializing = false;
    }
  }

  /// Synchronously gets instance if already initialized, otherwise returns null.
  T? get instanceOrNull => _instance;

  /// Resets instance to force re-initialization on next call.
  void reset() {
    _instance = null;
    _isInitializing = false;
  }
}
