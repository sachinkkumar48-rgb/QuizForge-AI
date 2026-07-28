import 'dart:async';

import 'ai_exception.dart';
import 'ai_model.dart';
import 'ai_provider.dart';
import 'ai_provider_registry.dart';
import 'ai_request.dart';
import 'ai_response.dart';
import 'offline_queue_manager.dart';
import 'prompt_template_engine.dart';
import 'retry_manager.dart';
import 'safety_validator.dart';
import 'streaming_response_manager.dart';
import 'telemetry_collector.dart';
import 'token_budget_manager.dart';

/// Pure Dart Production AI Orchestration Engine for Project TITAN.
///
/// Orchestrates provider selection, prompt rendering, safety validation,
/// token budgeting, exponential retries, streaming response management,
/// offline queueing, and telemetry collection.
class AIOrchestrator {
  final AIProviderRegistry providerRegistry;
  final PromptTemplateEngine promptEngine;
  final TokenBudgetManager tokenBudgetManager;
  final TelemetryCollector telemetryCollector;
  final RetryManager retryManager;
  final SafetyValidator safetyValidator;
  final OfflineQueueManager offlineQueueManager;

  bool _isInitialized = false;
  bool _isClosed = false;

  AIOrchestrator({
    required this.providerRegistry,
    PromptTemplateEngine? promptEngine,
    TokenBudgetManager? tokenBudgetManager,
    TelemetryCollector? telemetryCollector,
    RetryManager? retryManager,
    SafetyValidator? safetyValidator,
    OfflineQueueManager? offlineQueueManager,
  })  : promptEngine = promptEngine ?? PromptTemplateEngine(),
        tokenBudgetManager = tokenBudgetManager ?? TokenBudgetManager(),
        telemetryCollector = telemetryCollector ?? TelemetryCollector(),
        retryManager = retryManager ?? RetryManager(),
        safetyValidator = safetyValidator ?? SafetyValidator(),
        offlineQueueManager = offlineQueueManager ?? OfflineQueueManager();

  bool get isInitialized => _isInitialized && !_isClosed;

  /// Initializes orchestrator and registered providers.
  Future<void> initialize() async {
    if (_isClosed) {
      throw const AIInitializationException(
          'Cannot initialize closed AIOrchestrator.');
    }
    for (final provider in providerRegistry.providers) {
      if (!provider.isInitialized) {
        await provider.initialize();
      }
    }
    _isInitialized = true;
  }

  void _checkState() {
    if (_isClosed) {
      throw const AIInitializationException('AIOrchestrator has been closed.');
    }
    if (!_isInitialized) {
      throw const AIInitializationException(
          'AIOrchestrator is not initialized. Call initialize() first.');
    }
  }

  /// Selects the target provider by [providerName] or defaults.
  AIProvider _selectProvider(String? providerName) {
    if (providerName != null && providerName.isNotEmpty) {
      return providerRegistry.provider(providerName);
    }
    return providerRegistry.defaultProvider();
  }

  /// Renders template by ID or returns prompt directly.
  String preparePrompt({
    required String promptOrTemplateId,
    Map<String, Object?>? variables,
  }) {
    if (variables != null && variables.isNotEmpty) {
      final template = promptEngine.getTemplate(promptOrTemplateId);
      if (template != null) {
        return template.render(variables);
      }
    }
    return promptOrTemplateId;
  }

  /// Generates a complete AI response.
  Future<AIResponse<T>> execute<T>({
    required AIRequest request,
    String? providerName,
    String? templateId,
    Map<String, Object?>? templateVariables,
  }) async {
    _checkState();
    final stopwatch = Stopwatch()..start();
    final reqId = 'req_${DateTime.now().microsecondsSinceEpoch}';

    // 1. Prepare & Validate Prompt
    String finalPrompt = request.prompt;
    if (templateId != null && templateId.isNotEmpty) {
      finalPrompt = promptEngine.render(templateId, templateVariables ?? {});
    }

    final safetyCheck = safetyValidator.validatePrompt(finalPrompt);
    if (!safetyCheck.isSafe) {
      throw AISafetyException(
        'Prompt safety validation failed: ${safetyCheck.violationReason}',
        safetyCheck.flaggedCategory,
      );
    }

    final trimmedPrompt = tokenBudgetManager.trimPrompt(finalPrompt);
    final effectiveRequest = request.copyWith(prompt: trimmedPrompt);

    // 2. Offline check
    if (!offlineQueueManager.isOnline) {
      offlineQueueManager.enqueue(effectiveRequest);
      final offlineResp =
          offlineQueueManager.generateOfflineFallback<T>(effectiveRequest);

      telemetryCollector.record(AITelemetryRecord(
        requestId: reqId,
        providerName: 'offline_queue',
        modelId: effectiveRequest.model ?? 'offline',
        latency: stopwatch.elapsed,
        promptTokens: tokenBudgetManager.estimateTokens(trimmedPrompt),
        completionTokens: 0,
        totalTokens: tokenBudgetManager.estimateTokens(trimmedPrompt),
        retryAttempts: 0,
        isSuccess: true,
        timestamp: DateTime.now(),
      ));

      return offlineResp;
    }

    // 3. Select Provider & Execute with Retry
    final provider = _selectProvider(providerName);
    int attemptsUsed = 0;

    try {
      final response =
          await retryManager.execute<AIResponse<T>>((attempt) async {
        attemptsUsed = attempt;
        return await provider.generate<T>(effectiveRequest);
      });

      stopwatch.stop();

      // Output Safety Check
      final outputCheck = safetyValidator.validateOutput(response.text);
      if (!outputCheck.isSafe) {
        throw AISafetyException(
          'Output safety validation failed: ${outputCheck.violationReason}',
          outputCheck.flaggedCategory,
        );
      }

      // Track Token Usage & Telemetry
      final tokensUsed = response.usage.totalTokens;
      tokenBudgetManager.trackUsage(tokensUsed);

      telemetryCollector.record(AITelemetryRecord(
        requestId: reqId,
        providerName: provider.name,
        modelId: response.model,
        latency: stopwatch.elapsed,
        promptTokens: response.usage.promptTokens,
        completionTokens: response.usage.completionTokens,
        totalTokens: tokensUsed,
        retryAttempts: attemptsUsed - 1,
        isSuccess: true,
        timestamp: DateTime.now(),
      ));

      return response;
    } catch (e) {
      stopwatch.stop();
      telemetryCollector.record(AITelemetryRecord(
        requestId: reqId,
        providerName: provider.name,
        modelId: effectiveRequest.model ?? 'unknown',
        latency: stopwatch.elapsed,
        promptTokens: tokenBudgetManager.estimateTokens(trimmedPrompt),
        completionTokens: 0,
        totalTokens: tokenBudgetManager.estimateTokens(trimmedPrompt),
        retryAttempts: attemptsUsed > 0 ? attemptsUsed - 1 : 0,
        isSuccess: false,
        errorCode: e.runtimeType.toString(),
        timestamp: DateTime.now(),
      ));
      rethrow;
    }
  }

  /// Executes real-time streaming AI response.
  Stream<StreamChunkEvent> stream({
    required AIRequest request,
    String? providerName,
    String? templateId,
    Map<String, Object?>? templateVariables,
  }) {
    _checkState();
    final streamManager = StreamingResponseManager();

    String finalPrompt = request.prompt;
    if (templateId != null && templateId.isNotEmpty) {
      finalPrompt = promptEngine.render(templateId, templateVariables ?? {});
    }

    final safetyCheck = safetyValidator.validatePrompt(finalPrompt);
    if (!safetyCheck.isSafe) {
      throw AISafetyException(
        'Stream prompt safety validation failed: ${safetyCheck.violationReason}',
        safetyCheck.flaggedCategory,
      );
    }

    final trimmedPrompt = tokenBudgetManager.trimPrompt(finalPrompt);
    final effectiveRequest = request.copyWith(prompt: trimmedPrompt);

    final provider = _selectProvider(providerName);
    final rawStream = provider.generateStream(effectiveRequest);

    return streamManager.processStream(rawStream);
  }

  /// Returns all available models across registered providers.
  List<AIModel> availableModels() {
    _checkState();
    final models = <AIModel>[];
    for (final p in providerRegistry.providers) {
      models.addAll(p.models());
    }
    return models;
  }

  /// Process pending offline queued requests.
  Future<List<AIResponse<dynamic>>> processOfflineQueue() async {
    _checkState();
    if (!offlineQueueManager.isOnline ||
        offlineQueueManager.pendingCount == 0) {
      return const [];
    }

    final results = <AIResponse<dynamic>>[];
    while (offlineQueueManager.pendingCount > 0) {
      final queued = offlineQueueManager.dequeue();
      if (queued != null) {
        try {
          final res = await execute<dynamic>(request: queued.request);
          results.add(res);
        } catch (_) {}
      }
    }
    return results;
  }

  /// Closes orchestrator and all providers.
  Future<void> close() async {
    _isInitialized = false;
    _isClosed = true;
    for (final p in providerRegistry.providers) {
      if (p.isInitialized) {
        await p.close();
      }
    }
  }
}
