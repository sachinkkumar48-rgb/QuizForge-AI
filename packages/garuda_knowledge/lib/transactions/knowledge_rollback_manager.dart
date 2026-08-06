import '../integration/events/knowledge_event_bus.dart';
import '../integration/events/pipeline_events.dart';
import '../repositories/knowledge_repository.dart';
import 'knowledge_transaction.dart';

class KnowledgeRollbackManager {
  final KnowledgeRepository _repository;
  final KnowledgeEventBus _eventBus;
  final Map<String, KnowledgeTransaction> _activeTransactions = {};

  KnowledgeRollbackManager(this._repository, this._eventBus);

  KnowledgeTransaction startTransaction(KnowledgeTransaction tx) {
    _activeTransactions[tx.transactionId] = tx;
    return tx;
  }

  Future<void> commitTransaction(String txId) async {
    final tx = _activeTransactions.remove(txId);
    if (tx != null) {
      await tx.commit();
    }
  }

  Future<void> rollbackTransaction(String txId, String reason) async {
    final tx = _activeTransactions.remove(txId);
    if (tx != null) {
      await tx.rollback(_repository);
      _eventBus.publish(RollbackExecutedEvent(
        objectId: tx.targetObject.id.value,
        transactionId: txId,
        reason: reason,
      ));
    }
  }

  int get activeTransactionCount => _activeTransactions.length;
}
