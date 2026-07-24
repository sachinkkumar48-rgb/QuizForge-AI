import 'package:flutter/foundation.dart';

import '../models/quiz_model.dart';

/// Status enum representing stages of the quiz generation flow.
enum QuizGenerationStatus {
  idle,
  generating,
  success,
  error,
}

/// Immutable state container for managing progress and error states in quiz generation.
@immutable
class QuizGenerationState {
  final QuizGenerationStatus status;
  final String? message;
  final QuizModel? quizModel;
  final Object? error;
  final bool isApiKeyError;

  const QuizGenerationState({
    required this.status,
    this.message,
    this.quizModel,
    this.error,
    this.isApiKeyError = false,
  });

  factory QuizGenerationState.idle() => const QuizGenerationState(
        status: QuizGenerationStatus.idle,
      );

  factory QuizGenerationState.generating({String? message}) =>
      QuizGenerationState(
        status: QuizGenerationStatus.generating,
        message: message,
      );

  factory QuizGenerationState.success(QuizModel quizModel) =>
      QuizGenerationState(
        status: QuizGenerationStatus.success,
        quizModel: quizModel,
      );

  factory QuizGenerationState.error(
    String message, {
    Object? error,
    bool isApiKeyError = false,
  }) =>
      QuizGenerationState(
        status: QuizGenerationStatus.error,
        message: message,
        error: error,
        isApiKeyError: isApiKeyError,
      );

  bool get isIdle => status == QuizGenerationStatus.idle;
  bool get isGenerating => status == QuizGenerationStatus.generating;
  bool get isSuccess => status == QuizGenerationStatus.success;
  bool get isError => status == QuizGenerationStatus.error;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuizGenerationState &&
        other.status == status &&
        other.message == message &&
        other.quizModel == quizModel &&
        other.error == error &&
        other.isApiKeyError == isApiKeyError;
  }

  @override
  int get hashCode =>
      Object.hash(status, message, quizModel, error, isApiKeyError);
}
