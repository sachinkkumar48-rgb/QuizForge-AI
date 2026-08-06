import '../domain/entities/knowledge_object.dart';
import '../repositories/knowledge_repository.dart';

enum TransactionStatus { active, committed, rolledBack }

class KnowledgeTransaction {
  final String transactionId;
  final KnowledgeObject targetObject;
  final KnowledgeObject? originalState;
  final DateTime startedAt;
  TransactionStatus status = TransactionStatus.active;

  KnowledgeTransaction({
    required this.transactionId,
    required this.targetObject,
    this.originalState,
    required this.startedAt,
  });

  Future<void> commit() async {
    status = TransactionStatus.committed;
  }

  Future<void> rollback(KnowledgeRepository repository) async {
    if (status == TransactionStatus.rolledBack) return;
    if (originalState == null) {
      await repository.delete(targetObject.id);
    } else {
      await repository.update(originalState!);
    }
    status = TransactionStatus.rolledBack;
  }
}
