import 'package:meta/meta.dart';

import '../../domain/entities/knowledge_object.dart';

/// Supported pending operation types for offline sync queue commands.
enum KnowledgeSyncOperation {
  /// Save/Create operation.
  save,

  /// Update operation.
  update,

  /// Delete operation.
  delete,
}

/// Represents an immutable write-ahead pending synchronization command
/// queued for remote cloud transmission.
@immutable
class KnowledgeSyncCommand {
  /// Unique identifier of the queued sync command.
  final String id;

  /// Operation type (save, update, delete).
  final KnowledgeSyncOperation operation;

  /// Target entity associated with this operation.
  final KnowledgeObject knowledgeObject;

  /// Timestamp when the command was enqueued.
  final DateTime enqueuedAt;

  /// Creates a new [KnowledgeSyncCommand].
  KnowledgeSyncCommand({
    required this.id,
    required this.operation,
    required this.knowledgeObject,
    DateTime? enqueuedAt,
  }) : enqueuedAt = enqueuedAt ?? DateTime.now();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is KnowledgeSyncCommand &&
        other.id == id &&
        other.operation == operation &&
        other.knowledgeObject == knowledgeObject &&
        other.enqueuedAt == enqueuedAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, operation, knowledgeObject, enqueuedAt);
  }

  @override
  String toString() {
    return 'KnowledgeSyncCommand(id: $id, operation: ${operation.name}, objectId: ${knowledgeObject.id})';
  }
}

/// Abstract contract for managing offline synchronization queues
/// in the TITAN Knowledge Intelligence Engine infrastructure.
abstract class KnowledgeSyncQueue {
  /// Enqueues a write-ahead sync operation.
  Future<void> enqueue(
    KnowledgeSyncOperation operation,
    KnowledgeObject object,
  );

  /// Removes a processed command from the queue by its command [id].
  Future<void> dequeue(String id);

  /// Retrieves all pending queued commands ordered by [enqueuedAt] ascending.
  Future<List<KnowledgeSyncCommand>> getPendingCommands();

  /// Clears all queued commands.
  Future<void> clear();
}
