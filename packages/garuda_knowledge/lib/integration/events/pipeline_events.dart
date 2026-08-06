import 'knowledge_events.dart';

class BeforeRegistrationEvent extends KnowledgeEvent {
  final String objectId;
  final String packageName;

  BeforeRegistrationEvent({required this.objectId, required this.packageName});
}

class AfterValidationEvent extends KnowledgeEvent {
  final String objectId;
  final bool isValid;
  final int issueCount;

  AfterValidationEvent({
    required this.objectId,
    required this.isValid,
    required this.issueCount,
  });
}

class BeforeRepositoryWriteEvent extends KnowledgeEvent {
  final String objectId;
  final String operation;

  BeforeRepositoryWriteEvent({required this.objectId, required this.operation});
}

class RepositoryUpdatedEvent extends KnowledgeEvent {
  final String objectId;
  final String operation;

  RepositoryUpdatedEvent({required this.objectId, required this.operation});
}

class IndexUpdatedEvent extends KnowledgeEvent {
  final String objectId;

  IndexUpdatedEvent({required this.objectId});
}

class AnalyticsUpdatedEvent extends KnowledgeEvent {
  final String objectId;

  AnalyticsUpdatedEvent({required this.objectId});
}

class RegistrationCompletedEvent extends KnowledgeEvent {
  final String objectId;
  final double durationMs;

  RegistrationCompletedEvent({required this.objectId, required this.durationMs});
}

class RegistrationFailedEvent extends KnowledgeEvent {
  final String objectId;
  final String reason;
  final int failedStage;

  RegistrationFailedEvent({
    required this.objectId,
    required this.reason,
    required this.failedStage,
  });
}

class RollbackExecutedEvent extends KnowledgeEvent {
  final String objectId;
  final String transactionId;
  final String reason;

  RollbackExecutedEvent({
    required this.objectId,
    required this.transactionId,
    required this.reason,
  });
}
