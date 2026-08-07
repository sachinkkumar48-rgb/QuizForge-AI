library;

import 'package:meta/meta.dart';
import '../domain/entities/knowledge_link.dart';

/// Base abstract event for GARUDA Knowledge Graph events.
@immutable
abstract class KnowledgeGraphEvent {
  final String eventId;
  final DateTime timestamp;
  final String eventType;

  const KnowledgeGraphEvent({
    required this.eventId,
    required this.timestamp,
    required this.eventType,
  });

  Map<String, dynamic> toJson();
}

/// Event fired when a new Knowledge Link is suggested by deterministic matching.
class LinkSuggested extends KnowledgeGraphEvent {
  final KnowledgeLink link;

  const LinkSuggested({
    required super.eventId,
    required super.timestamp,
    required this.link,
  }) : super(eventType: 'LinkSuggested');

  @override
  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'eventType': eventType,
        'linkId': link.id,
        'sourceId': link.sourceObject.id,
        'targetId': link.targetObject.id,
        'confidenceScore': link.confidenceScore,
      };
}

/// Event fired when a suggested link is approved by editorial review.
class LinkApproved extends KnowledgeGraphEvent {
  final String linkId;
  final String reviewer;

  const LinkApproved({
    required super.eventId,
    required super.timestamp,
    required this.linkId,
    required this.reviewer,
  }) : super(eventType: 'LinkApproved');

  @override
  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'eventType': eventType,
        'linkId': linkId,
        'reviewer': reviewer,
      };
}

/// Event fired when a suggested link is rejected.
class LinkRejected extends KnowledgeGraphEvent {
  final String linkId;
  final String reviewer;
  final String reason;

  const LinkRejected({
    required super.eventId,
    required super.timestamp,
    required this.linkId,
    required this.reviewer,
    required this.reason,
  }) : super(eventType: 'LinkRejected');

  @override
  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'eventType': eventType,
        'linkId': linkId,
        'reviewer': reviewer,
        'reason': reason,
      };
}

/// Event fired when a link is removed or deprecated.
class LinkRemoved extends KnowledgeGraphEvent {
  final String linkId;
  final String reason;

  const LinkRemoved({
    required super.eventId,
    required super.timestamp,
    required this.linkId,
    required this.reason,
  }) : super(eventType: 'LinkRemoved');

  @override
  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'eventType': eventType,
        'linkId': linkId,
        'reason': reason,
      };
}

/// Event fired when the graph structure or node connections change.
class KnowledgeGraphUpdated extends KnowledgeGraphEvent {
  final String nodeOrLinkId;
  final String updateType;

  const KnowledgeGraphUpdated({
    required super.eventId,
    required super.timestamp,
    required this.nodeOrLinkId,
    required this.updateType,
  }) : super(eventType: 'KnowledgeGraphUpdated');

  @override
  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'timestamp': timestamp.toIso8601String(),
        'eventType': eventType,
        'nodeOrLinkId': nodeOrLinkId,
        'updateType': updateType,
      };
}
