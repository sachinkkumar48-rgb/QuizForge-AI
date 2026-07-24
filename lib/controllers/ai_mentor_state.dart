import 'package:flutter/foundation.dart';
import '../models/ai_mentor_models.dart';

enum AIMentorStatus { loading, ready, error }

/// Immutable state container for the AI Mentor Panel.
@immutable
class AIMentorState {
  final AIMentorStatus status;
  final AIMentorData? data;
  final String? errorMessage;

  const AIMentorState({
    required this.status,
    this.data,
    this.errorMessage,
  });

  factory AIMentorState.loading() => const AIMentorState(
        status: AIMentorStatus.loading,
      );

  factory AIMentorState.ready(AIMentorData data) => AIMentorState(
        status: AIMentorStatus.ready,
        data: data,
      );

  factory AIMentorState.error(String message) => AIMentorState(
        status: AIMentorStatus.error,
        errorMessage: message,
      );

  bool get isLoading => status == AIMentorStatus.loading;
  bool get isReady => status == AIMentorStatus.ready;
  bool get isError => status == AIMentorStatus.error;

  AIMentorState copyWith({
    AIMentorStatus? status,
    AIMentorData? data,
    String? errorMessage,
  }) {
    return AIMentorState(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
