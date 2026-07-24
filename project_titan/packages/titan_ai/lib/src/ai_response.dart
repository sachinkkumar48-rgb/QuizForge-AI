import 'package:meta/meta.dart';
import 'ai_token_usage.dart';

/// Immutable generic model representing an AI response in Project TITAN.
@immutable
class AIResponse<T> {
  final String text;
  final T? data;
  final AITokenUsage usage;
  final String model;
  final String provider;
  final String finishReason;
  final DateTime createdAt;

  AIResponse({
    required this.text,
    this.data,
    required this.usage,
    required this.model,
    required this.provider,
    required this.finishReason,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  const AIResponse.constResponse({
    required this.text,
    this.data,
    required this.usage,
    required this.model,
    required this.provider,
    required this.finishReason,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AIResponse<T> &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          data == other.data &&
          usage == other.usage &&
          model == other.model &&
          provider == other.provider &&
          finishReason == other.finishReason &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      text.hashCode ^
      data.hashCode ^
      usage.hashCode ^
      model.hashCode ^
      provider.hashCode ^
      finishReason.hashCode ^
      createdAt.hashCode;

  @override
  String toString() =>
      'AIResponse<$T>(provider: $provider, model: $model, finishReason: $finishReason)';
}
