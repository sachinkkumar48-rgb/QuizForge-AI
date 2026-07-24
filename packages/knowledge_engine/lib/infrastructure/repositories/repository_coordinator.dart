import '../../domain/entities/knowledge_object.dart';
import '../../domain/repositories/knowledge_repository.dart';
import '../data_sources/knowledge_cache_data_source.dart';
import '../data_sources/knowledge_local_data_source.dart';
import '../data_sources/knowledge_remote_data_source.dart';
import '../sync/knowledge_sync_queue.dart';

/// Concrete repository implementation that orchestrates multi-tier data flow
/// across memory cache, local storage, remote cloud storage, and offline sync queue.
///
/// Implements [KnowledgeRepository] and adheres strictly to Clean Architecture and
/// Dependency Inversion Principles by depending exclusively on abstract data sources.
class RepositoryCoordinator implements KnowledgeRepository {
  /// Primary local database engine (required).
  final KnowledgeLocalDataSource localDataSource;

  /// Optional remote cloud storage engine (e.g. Supabase, REST API).
  final KnowledgeRemoteDataSource? remoteDataSource;

  /// Optional ultra-fast L1 memory cache.
  final KnowledgeCacheDataSource? cacheDataSource;

  /// Optional offline write-ahead synchronization queue.
  final KnowledgeSyncQueue? syncQueue;

  /// Constructs a [RepositoryCoordinator] with pluggable data source instances.
  RepositoryCoordinator({
    required this.localDataSource,
    this.remoteDataSource,
    this.cacheDataSource,
    this.syncQueue,
  });

  @override
  Future<void> save(KnowledgeObject object) async {
    // 1. Optimistic L1 Cache update
    cacheDataSource?.put(object);

    // 2. Immediate L2 Local Persistence
    await localDataSource.save(object);

    // 3. Optional L3 Remote Synchronization with offline queue fallback
    if (remoteDataSource != null) {
      try {
        await remoteDataSource!.save(object);
      } catch (_) {
        await syncQueue?.enqueue(KnowledgeSyncOperation.save, object);
      }
    }
  }

  @override
  Future<void> update(KnowledgeObject object) async {
    // 1. Optimistic L1 Cache update
    cacheDataSource?.put(object);

    // 2. Immediate L2 Local Persistence update
    await localDataSource.update(object);

    // 3. Optional L3 Remote Synchronization with offline queue fallback
    if (remoteDataSource != null) {
      try {
        await remoteDataSource!.update(object);
      } catch (_) {
        await syncQueue?.enqueue(KnowledgeSyncOperation.update, object);
      }
    }
  }

  @override
  Future<void> delete(String id) async {
    // 1. Fetch object or create minimal reference for sync queue logging
    final existing =
        cacheDataSource?.get(id) ?? await localDataSource.findById(id);

    // 2. Evict from L1 Cache and L2 Local Storage
    cacheDataSource?.remove(id);
    await localDataSource.delete(id);

    // 3. Optional L3 Remote Deletion with offline queue fallback
    if (remoteDataSource != null) {
      try {
        await remoteDataSource!.delete(id);
      } catch (_) {
        if (existing != null) {
          await syncQueue?.enqueue(KnowledgeSyncOperation.delete, existing);
        }
      }
    }
  }

  @override
  Future<KnowledgeObject?> findById(String id) async {
    // 1. Check L1 Memory Cache
    final cached = cacheDataSource?.get(id);
    if (cached != null) {
      return cached;
    }

    // 2. Check L2 Local Storage
    final local = await localDataSource.findById(id);
    if (local != null) {
      cacheDataSource?.put(local);
      return local;
    }

    // 3. Check L3 Remote Cloud Storage
    if (remoteDataSource != null) {
      try {
        final remote = await remoteDataSource!.findById(id);
        if (remote != null) {
          await localDataSource.save(remote);
          cacheDataSource?.put(remote);
          return remote;
        }
      } catch (_) {
        // Fallthrough to return null on remote network/fetch errors
      }
    }

    return null;
  }

  @override
  Future<List<KnowledgeObject>> search(String query) async {
    // 1. Perform primary search in local storage
    final localResults = await localDataSource.search(query);
    if (localResults.isNotEmpty) {
      for (final item in localResults) {
        cacheDataSource?.put(item);
      }
      return localResults;
    }

    // 2. Fallback to remote cloud search if local yields no results
    if (remoteDataSource != null) {
      try {
        final remoteResults = await remoteDataSource!.search(query);
        for (final item in remoteResults) {
          await localDataSource.save(item);
          cacheDataSource?.put(item);
        }
        return remoteResults;
      } catch (_) {
        return const [];
      }
    }

    return const [];
  }
}
