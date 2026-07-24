import 'di_exceptions.dart';

enum DependencyLifetime { singleton, lazySingleton, factory }

abstract class _ServiceEntry<T extends Object> {
  T resolve();
  DependencyLifetime get lifetime;
}

class _SingletonEntry<T extends Object> implements _ServiceEntry<T> {
  final T instance;
  _SingletonEntry(this.instance);

  @override
  T resolve() => instance;

  @override
  DependencyLifetime get lifetime => DependencyLifetime.singleton;
}

class _LazySingletonEntry<T extends Object> implements _ServiceEntry<T> {
  final T Function() _factory;
  T? _instance;

  _LazySingletonEntry(this._factory);

  @override
  T resolve() {
    _instance ??= _factory();
    return _instance!;
  }

  @override
  DependencyLifetime get lifetime => DependencyLifetime.lazySingleton;
}

class _FactoryEntry<T extends Object> implements _ServiceEntry<T> {
  final T Function() _factory;

  _FactoryEntry(this._factory);

  @override
  T resolve() => _factory();

  @override
  DependencyLifetime get lifetime => DependencyLifetime.factory;
}

/// Lightweight, framework-agnostic Service Locator for Clean Architecture
/// dependency injection in Project TITAN.
class TitanServiceLocator {
  static final TitanServiceLocator _instance = TitanServiceLocator._internal();
  final Map<Type, _ServiceEntry<Object>> _registrations = {};

  factory TitanServiceLocator() => _instance;

  static TitanServiceLocator get instance => _instance;

  TitanServiceLocator._internal();

  /// Register an eager singleton instance.
  void registerSingleton<T extends Object>(
    T instance, {
    bool allowOverride = false,
  }) {
    _checkDuplicate<T>(allowOverride);
    _registrations[T] = _SingletonEntry<T>(instance);
  }

  /// Register a lazy singleton instance resolved on first access.
  void registerLazySingleton<T extends Object>(
    T Function() factory, {
    bool allowOverride = false,
  }) {
    _checkDuplicate<T>(allowOverride);
    _registrations[T] = _LazySingletonEntry<T>(factory);
  }

  /// Register a factory that creates a new instance on every access.
  void registerFactory<T extends Object>(
    T Function() factory, {
    bool allowOverride = false,
  }) {
    _checkDuplicate<T>(allowOverride);
    _registrations[T] = _FactoryEntry<T>(factory);
  }

  /// Resolve a registered dependency instance.
  T get<T extends Object>() {
    final entry = _registrations[T];
    if (entry == null) {
      throw TitanMissingDependencyException(T);
    }
    return entry.resolve() as T;
  }

  /// Callable shortcut syntax: `TitanServiceLocator()<T>()`
  T call<T extends Object>() => get<T>();

  /// Returns true if a dependency of type [T] is registered.
  bool isRegistered<T extends Object>() {
    return _registrations.containsKey(T);
  }

  /// Returns true if a dependency of runtime [type] is registered.
  bool isRegisteredType(Type type) {
    return _registrations.containsKey(type);
  }

  /// Returns the registered dependency lifetime, or null if not registered.
  DependencyLifetime? getLifetime<T extends Object>() {
    return _registrations[T]?.lifetime;
  }

  /// Unregister a specific service type [T].
  void unregister<T extends Object>() {
    _registrations.remove(T);
  }

  /// Reset all registered dependencies (for unit testing).
  void reset() {
    _registrations.clear();
  }

  void _checkDuplicate<T extends Object>(bool allowOverride) {
    if (!allowOverride && _registrations.containsKey(T)) {
      throw TitanDuplicateDependencyException(T);
    }
  }
}
