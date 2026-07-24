import '../../domain/repositories/knowledge_repository.dart';
import '../data_sources/knowledge_cache_data_source.dart';
import '../data_sources/knowledge_local_data_source.dart';
import '../data_sources/knowledge_remote_data_source.dart';
import '../repositories/repository_coordinator.dart';
import '../sync/knowledge_sync_queue.dart';

/// Service locator and dependency injection container for registering and
/// retrieving Knowledge Intelligence Engine infrastructure instances.
class KnowledgeDependencyContainer {
  KnowledgeLocalDataSource? _localDataSource;
  KnowledgeRemoteDataSource? _remoteDataSource;
  KnowledgeCacheDataSource? _cacheDataSource;
  KnowledgeSyncQueue? _syncQueue;
  KnowledgeRepository? _repository;

  /// Singleton container instance.
  static final KnowledgeDependencyContainer instance =
      KnowledgeDependencyContainer._();

  KnowledgeDependencyContainer._();

  /// Registers the primary local data source.
  void registerLocalDataSource(KnowledgeLocalDataSource dataSource) {
    _localDataSource = dataSource;
    _resetRepository();
  }

  /// Registers an optional remote data source.
  void registerRemoteDataSource(KnowledgeRemoteDataSource dataSource) {
    _remoteDataSource = dataSource;
    _resetRepository();
  }

  /// Registers an optional memory cache data source.
  void registerCacheDataSource(KnowledgeCacheDataSource dataSource) {
    _cacheDataSource = dataSource;
    _resetRepository();
  }

  /// Registers an optional offline sync queue.
  void registerSyncQueue(KnowledgeSyncQueue syncQueue) {
    _syncQueue = syncQueue;
    _resetRepository();
  }

  /// Registers a custom [KnowledgeRepository] instance directly.
  void registerRepository(KnowledgeRepository repository) {
    _repository = repository;
  }

  /// Resolves the registered [KnowledgeRepository] or builds a default [RepositoryCoordinator].
  KnowledgeRepository get repository {
    if (_repository != null) {
      return _repository!;
    }

    if (_localDataSource == null) {
      throw StateError(
        'KnowledgeLocalDataSource must be registered before resolving KnowledgeRepository.',
      );
    }

    _repository = RepositoryCoordinator(
      localDataSource: _localDataSource!,
      remoteDataSource: _remoteDataSource,
      cacheDataSource: _cacheDataSource,
      syncQueue: _syncQueue,
    );

    return _repository!;
  }

  /// Resets all registered dependencies.
  void reset() {
    _localDataSource = null;
    _remoteDataSource = null;
    _cacheDataSource = null;
    _syncQueue = null;
    _repository = null;
  }

  void _resetRepository() {
    _repository = null;
  }
}
