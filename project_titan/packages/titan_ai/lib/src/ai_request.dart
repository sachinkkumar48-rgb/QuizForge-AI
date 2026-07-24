import 'package:meta/meta.dart';

/// Immutable model representing an AI generation request in Project TITAN.
@immutable
class AIRequest {
  final String prompt;
  final String? systemPrompt;
  final String? model;
  final double? temperature;
  final int? maxTokens;
  final Map<String, Object?> metadata;

  AIRequest({
    required this.prompt,
    this.systemPrompt,
    this.model,
    this.temperature,
    this.maxTokens,
    Map<String, Object?>? metadata,
  }) : metadata = Map<String, Object?>.unmodifiable(metadata ?? const {});

  /// Creates a modified copy of this [AIRequest].
  AIRequest copyWith({
    String? prompt,
    String? systemPrompt,
    String? model,
    double? temperature,
    int? maxTokens,
    Map<String, Object?>? metadata,
  }) {
    return AIRequest(
      prompt: prompt ?? this.prompt,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      model: model ?? this.model,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AIRequest &&
          runtimeType == other.runtimeType &&
          prompt == other.prompt &&
          systemPrompt == other.systemPrompt &&
          model == other.model &&
          temperature == other.temperature &&
          maxTokens == other.maxTokens &&
          metadata == other.metadata;

  @override
  int get hashCode =>
      prompt.hashCode ^
      systemPrompt.hashCode ^
      model.hashCode ^
      temperature.hashCode ^
      maxTokens.hashCode ^
      metadata.hashCode;

  @override
  String toString() =>
      'AIRequest(model: $model, promptLen: ${prompt.length}, sysPrompt: ${systemPrompt != null})';
}
