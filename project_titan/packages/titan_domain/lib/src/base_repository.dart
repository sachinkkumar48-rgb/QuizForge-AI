import 'package:meta/meta.dart';

import 'ports/ports.dart';

import 'cache_strategy.dart';
import 'repository.dart';
import 'repository_exception.dart';

/// Base repository class coordinating AI, Storage, and Network infrastructure services
/// while translating infrastructure exceptions into the domain [RepositoryException] hierarchy.
abstract class BaseRepository<T> implements Repository<T> {
  final AIService aiService;
  final StorageService storageService;
  final NetworkService networkService;
  final CacheStrategy cacheStrategy;

  bool _isInitialized = false;
  bool _isDisposed = false;

  BaseRepository({
    required this.aiService,
    required this.storageService,
    required this.networkService,
    CacheStrategy? cacheStrategy,
  }) : cacheStrategy = cacheStrategy ?? const CacheFirstStrategy();

  @override
  bool get isInitialized => _isInitialized && !_isDisposed;

  /// Validates repository lifecycle state before performing operations.
  @protected
  void checkState() {
    if (_isDisposed) {
      throw const RepositoryInitializationException(
          'Repository has been disposed.');
    }
    if (!isInitialized) {
      throw const RepositoryInitializationException(
          'Repository is not initialized.');
    }
  }

  @override
  Future<void> initialize() async {
    if (_isDisposed) {
      throw const RepositoryInitializationException(
          'Cannot initialize disposed repository.');
    }
    await executeGuarded(() async {
      if (!aiService.isInitialized) {
        await aiService.initialize();
      }
      if (!storageService.isInitialized) {
        await storageService.initialize();
      }
      if (!networkService.isInitialized) {
        await networkService.initialize();
      }
    });
    _isInitialized = true;
  }

  @override
  Future<void> dispose() async {
    _isInitialized = false;
    _isDisposed = true;
  }

  /// Protected helper method that wraps infrastructure calls and translates
  /// infrastructure exceptions into standard [RepositoryException] instances.
  @protected
  Future<R> executeGuarded<R>(Future<R> Function() action) async {
    try {
      return await action();
    } on RepositoryException {
      rethrow;
    } on AIException catch (e, st) {
      throw RepositoryAIException(e.message, e, st);
    } on StorageException catch (e, st) {
      throw RepositoryCacheException(e.message, e, st);
    } on NetworkException catch (e, st) {
      final statusCode = e is NetworkResponseException ? e.statusCode : null;
      throw RepositoryNetworkException(e.message, statusCode, e, st);
    } on FormatException catch (e, st) {
      throw RepositoryDataException('Data format error: ${e.message}', e, st);
    } catch (e, st) {
      if (e is TypeError) {
        throw RepositoryDataException('Type mismatch error: $e', e, st);
      }
      throw RepositoryDataException('Unexpected repository error: $e', e, st);
    }
  }
}
