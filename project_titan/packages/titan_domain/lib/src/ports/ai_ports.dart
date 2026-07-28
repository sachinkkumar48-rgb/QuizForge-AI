import 'package:meta/meta.dart';

/// Immutable model describing an LLM model capabilities in Project TITAN.
@immutable
class AIModel {
  final String id;
  final String displayName;
  final int contextWindow;
  final bool supportsVision;
  final bool supportsStreaming;
  final bool supportsJson;
  final int maxOutputTokens;

  const AIModel({
    required this.id,
    required this.displayName,
    required this.contextWindow,
    this.supportsVision = false,
    this.supportsStreaming = false,
    this.supportsJson = false,
    required this.maxOutputTokens,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AIModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          displayName == other.displayName &&
          contextWindow == other.contextWindow &&
          supportsVision == other.supportsVision &&
          supportsStreaming == other.supportsStreaming &&
          supportsJson == other.supportsJson &&
          maxOutputTokens == other.maxOutputTokens;

  @override
  int get hashCode =>
      id.hashCode ^
      displayName.hashCode ^
      contextWindow.hashCode ^
      supportsVision.hashCode ^
      supportsStreaming.hashCode ^
      supportsJson.hashCode ^
      maxOutputTokens.hashCode;

  @override
  String toString() => 'AIModel($id - $displayName)';
}

/// Immutable record of token consumption for an AI generation request.
@immutable
class AITokenUsage {
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;

  const AITokenUsage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });

  const AITokenUsage.zero()
      : promptTokens = 0,
        completionTokens = 0,
        totalTokens = 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AITokenUsage &&
          runtimeType == other.runtimeType &&
          promptTokens == other.promptTokens &&
          completionTokens == other.completionTokens &&
          totalTokens == other.totalTokens;

  @override
  int get hashCode =>
      promptTokens.hashCode ^ completionTokens.hashCode ^ totalTokens.hashCode;

  @override
  String toString() =>
      'AITokenUsage(prompt: $promptTokens, completion: $completionTokens, total: $totalTokens)';
}

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

/// Base exception class for all AI foundation errors in Project TITAN.
abstract class AIException implements Exception {
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  const AIException(this.message, [this.cause, this.stackTrace]);

  @override
  String toString() {
    final causeStr = cause != null ? ' (Cause: $cause)' : '';
    return '$runtimeType: $message$causeStr';
  }
}

/// Thrown when AI service or provider initialization fails.
class AIInitializationException extends AIException {
  const AIInitializationException(super.message,
      [super.cause, super.stackTrace]);
}

/// Thrown when an AI request payload is invalid or rejected prior to execution.
class AIRequestException extends AIException {
  const AIRequestException(super.message, [super.cause, super.stackTrace]);
}

/// Thrown when network connectivity or socket errors occur during AI requests.
class AINetworkException extends AIException {
  const AINetworkException(super.message, [super.cause, super.stackTrace]);
}

/// Thrown when safety validation (prompt injection, XSS, credential leaks) fails.
class AISafetyException extends AIException {
  final String? flaggedCategory;

  const AISafetyException(
    super.message, [
    this.flaggedCategory,
    super.cause,
    super.stackTrace,
  ]);
}

/// Thrown when a requested feature or provider operation is unsupported.
class AIUnsupportedException extends AIException {
  const AIUnsupportedException(super.message, [super.cause, super.stackTrace]);
}

/// Thrown when an AI provider returns an error response or unparseable output.
class AIResponseException extends AIException {
  final int? statusCode;

  const AIResponseException(
    super.message, [
    this.statusCode,
    super.cause,
    super.stackTrace,
  ]);
}

/// Thrown when a requested provider is not found or fails to execute.
class AIProviderException extends AIException {
  final String? providerName;

  const AIProviderException(
    super.message, [
    this.providerName,
    super.cause,
    super.stackTrace,
  ]);
}

/// Thrown when an invalid or unsupported AI model is specified.
class AIModelException extends AIException {
  final String? modelId;

  const AIModelException(
    super.message, [
    this.modelId,
    super.cause,
    super.stackTrace,
  ]);
}

/// Single top-level entry point interface for AI generation in Project TITAN applications.
abstract class AIService {
  /// Initializes the AI service and its underlying providers.
  Future<void> initialize();

  /// Returns true if the service is initialized.
  bool get isInitialized;

  /// Generates an AI completion using the active provider.
  Future<AIResponse<T>> generate<T>(AIRequest request);

  /// Returns list of available models supported by current AI providers.
  List<AIModel> availableModels();

  /// Returns default AI model.
  AIModel defaultModel();

  /// Closes AI service and releases resources.
  Future<void> close();
}
