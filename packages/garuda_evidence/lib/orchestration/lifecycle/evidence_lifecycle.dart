import 'package:meta/meta.dart';

/// Complete lifecycle states for Evidence Objects in Project TITAN.
enum EvidenceLifecycleState {
  discovered,
  collected,
  parsed,
  validated,
  reviewPending,
  approved,
  linked,
  published,
  archived,
}

/// Audit trail log entry for a lifecycle state transition.
@immutable
class EvidenceLifecycleTransition {
  final EvidenceLifecycleState fromState;
  final EvidenceLifecycleState toState;
  final DateTime timestamp;
  final String transitionedBy;
  final String notes;

  const EvidenceLifecycleTransition({
    required this.fromState,
    required this.toState,
    required this.timestamp,
    this.transitionedBy = 'system',
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'fromState': fromState.name,
        'toState': toState.name,
        'timestamp': timestamp.toIso8601String(),
        'transitionedBy': transitionedBy,
        'notes': notes,
      };

  factory EvidenceLifecycleTransition.fromJson(Map<String, dynamic> json) =>
      EvidenceLifecycleTransition(
        fromState: EvidenceLifecycleState.values.firstWhere(
          (e) => e.name == json['fromState'],
          orElse: () => EvidenceLifecycleState.discovered,
        ),
        toState: EvidenceLifecycleState.values.firstWhere(
          (e) => e.name == json['toState'],
          orElse: () => EvidenceLifecycleState.collected,
        ),
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now(),
        transitionedBy: json['transitionedBy'] as String? ?? 'system',
        notes: json['notes'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EvidenceLifecycleTransition &&
        other.fromState == fromState &&
        other.toState == toState &&
        other.timestamp == timestamp &&
        other.transitionedBy == transitionedBy;
  }

  @override
  int get hashCode =>
      Object.hash(fromState, toState, timestamp, transitionedBy);
}

/// Immutable container tracking the current state and complete transition history.
@immutable
class EvidenceLifecycle {
  final EvidenceLifecycleState currentState;
  final List<EvidenceLifecycleTransition> history;
  final DateTime updatedAt;
  final String updatedBy;

  const EvidenceLifecycle({
    this.currentState = EvidenceLifecycleState.discovered,
    this.history = const [],
    required this.updatedAt,
    this.updatedBy = 'system',
  });

  EvidenceLifecycle transitionTo(
    EvidenceLifecycleState newState, {
    required String by,
    String notes = '',
  }) {
    final now = DateTime.now();
    final transition = EvidenceLifecycleTransition(
      fromState: currentState,
      toState: newState,
      timestamp: now,
      transitionedBy: by,
      notes: notes,
    );

    return EvidenceLifecycle(
      currentState: newState,
      history: [...history, transition],
      updatedAt: now,
      updatedBy: by,
    );
  }

  Map<String, dynamic> toJson() => {
        'currentState': currentState.name,
        'history': history.map((h) => h.toJson()).toList(),
        'updatedAt': updatedAt.toIso8601String(),
        'updatedBy': updatedBy,
      };

  factory EvidenceLifecycle.fromJson(Map<String, dynamic> json) =>
      EvidenceLifecycle(
        currentState: EvidenceLifecycleState.values.firstWhere(
          (e) => e.name == json['currentState'],
          orElse: () => EvidenceLifecycleState.discovered,
        ),
        history: (json['history'] as List?)
                ?.map((e) => EvidenceLifecycleTransition.fromJson(
                    Map<String, dynamic>.from(e as Map)))
                .toList() ??
            const [],
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.now(),
        updatedBy: json['updatedBy'] as String? ?? 'system',
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EvidenceLifecycle &&
        other.currentState == currentState &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(currentState, updatedAt);
}
