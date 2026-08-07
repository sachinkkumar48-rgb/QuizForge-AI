import 'package:meta/meta.dart';
import '../../domain/entities/evidence_object.dart';

/// Base abstract class for all Evidence Orchestration events.
@immutable
abstract class EvidenceEvent {
  final String eventId;
  final DateTime timestamp;
  final String eventType;

  const EvidenceEvent({
    required this.eventId,
    required this.timestamp,
    required this.eventType,
  });

  Map<String, dynamic> toJson();
}

/// Event triggered when raw evidence is collected.
class EvidenceCollected extends EvidenceEvent {
  final String sourceName;
  final String evidenceId;

  const EvidenceCollected({
    required super.eventId,
    required super.timestamp,
    required this.sourceName,
    required this.evidenceId,
  }) : super(
          eventType: 'EvidenceCollected',
        );

  @override
  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'eventType': eventType,
        'sourceName': sourceName,
        'evidenceId': evidenceId,
      };
}

/// Event triggered when raw evidence is parsed into EvidenceObject.
class EvidenceParsed extends EvidenceEvent {
  final EvidenceObject evidence;

  const EvidenceParsed({
    required super.eventId,
    required super.timestamp,
    required this.evidence,
  }) : super(
          eventType: 'EvidenceParsed',
        );

  @override
  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'eventType': eventType,
        'evidenceId': evidence.id,
      };
}

/// Event triggered when evidence passes validation.
class EvidenceValidated extends EvidenceEvent {
  final String evidenceId;
  final bool isValid;

  const EvidenceValidated({
    required super.eventId,
    required super.timestamp,
    required this.evidenceId,
    required this.isValid,
  }) : super(
          eventType: 'EvidenceValidated',
        );

  @override
  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'eventType': eventType,
        'evidenceId': evidenceId,
        'isValid': isValid,
      };
}

/// Event triggered when evidence is approved by editorial review.
class EvidenceApproved extends EvidenceEvent {
  final String evidenceId;
  final String reviewer;

  const EvidenceApproved({
    required super.eventId,
    required super.timestamp,
    required this.evidenceId,
    required this.reviewer,
  }) : super(
          eventType: 'EvidenceApproved',
        );

  @override
  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'eventType': eventType,
        'evidenceId': evidenceId,
        'reviewer': reviewer,
      };
}

/// Event triggered when evidence is rejected during review.
class EvidenceRejected extends EvidenceEvent {
  final String evidenceId;
  final String reviewer;
  final String reason;

  const EvidenceRejected({
    required super.eventId,
    required super.timestamp,
    required this.evidenceId,
    required this.reviewer,
    required this.reason,
  }) : super(
          eventType: 'EvidenceRejected',
        );

  @override
  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'eventType': eventType,
        'evidenceId': evidenceId,
        'reviewer': reviewer,
        'reason': reason,
      };
}

/// Event triggered when evidence version is updated.
class EvidenceUpdated extends EvidenceEvent {
  final String evidenceId;
  final int newVersion;

  const EvidenceUpdated({
    required super.eventId,
    required super.timestamp,
    required this.evidenceId,
    required this.newVersion,
  }) : super(
          eventType: 'EvidenceUpdated',
        );

  @override
  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'eventType': eventType,
        'evidenceId': evidenceId,
        'newVersion': newVersion,
      };
}

/// Event triggered when evidence is linked to Knowledge Graph objects.
class KnowledgeLinked extends EvidenceEvent {
  final String evidenceId;
  final String knowledgeObjectType;
  final String targetLinkId;

  const KnowledgeLinked({
    required super.eventId,
    required super.timestamp,
    required this.evidenceId,
    required this.knowledgeObjectType,
    required this.targetLinkId,
  }) : super(
          eventType: 'KnowledgeLinked',
        );

  @override
  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'eventType': eventType,
        'evidenceId': evidenceId,
        'knowledgeObjectType': knowledgeObjectType,
        'targetLinkId': targetLinkId,
      };
}

/// Event triggered when an evidence source is unavailable.
class SourceUnavailable extends EvidenceEvent {
  final String sourceName;
  final String errorDetails;

  const SourceUnavailable({
    required super.eventId,
    required super.timestamp,
    required this.sourceName,
    required this.errorDetails,
  }) : super(
          eventType: 'SourceUnavailable',
        );

  @override
  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'eventType': eventType,
        'sourceName': sourceName,
        'errorDetails': errorDetails,
      };
}

/// Event triggered when a collector fails execution.
class CollectorFailed extends EvidenceEvent {
  final String collectorName;
  final String errorMessage;

  const CollectorFailed({
    required super.eventId,
    required super.timestamp,
    required this.collectorName,
    required this.errorMessage,
  }) : super(
          eventType: 'CollectorFailed',
        );

  @override
  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'eventType': eventType,
        'collectorName': collectorName,
        'errorMessage': errorMessage,
      };
}
