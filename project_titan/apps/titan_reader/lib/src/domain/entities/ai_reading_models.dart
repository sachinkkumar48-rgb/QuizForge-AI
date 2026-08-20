library;

import 'package:meta/meta.dart';
import 'ai_reading_task.dart';

/// Provider type supported by TITAN Reader.
enum AIProviderType {
  /// Local Ollama native service (e.g. http://localhost:11434).
  localOllama,

  /// OpenAI-compatible local/remote server (e.g. LocalAI, vLLM, LM Studio, OpenAI).
  openAICompatible,

  /// Google Gemini REST API.
  gemini,

  /// Mock provider for 100% offline deterministic test suites.
  mock,
}

/// Metadata describing an available AI model.
@immutable
class AIModelInfo {
  final String id;
  final String displayName;
  final String providerId;
  final bool isLocal;
  final int contextWindow;

  const AIModelInfo({
    required this.id,
    required this.displayName,
    required this.providerId,
    this.isLocal = true,
    this.contextWindow = 4096,
  });

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'displayName': displayName,
        'providerId': providerId,
        'isLocal': isLocal,
        'contextWindow': contextWindow,
      };

  factory AIModelInfo.fromJson(Map<String, Object?> json) {
    return AIModelInfo(
      id: json['id'] as String? ?? 'default',
      displayName: json['displayName'] as String? ?? 'Default Model',
      providerId: json['providerId'] as String? ?? 'localOllama',
      isLocal: json['isLocal'] as bool? ?? true,
      contextWindow: json['contextWindow'] as int? ?? 4096,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AIModelInfo &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          providerId == other.providerId;

  @override
  int get hashCode => Object.hash(id, providerId);
}

/// Configuration for AI Reading Assistant.
@immutable
class AIConfig {
  final AIProviderType providerType;
  final String activeModelId;
  final String ollamaBaseUrl;
  final String openAIBaseUrl;
  final String? openAIApiKey;
  final String? geminiApiKey;
  final bool localFirst;
  final double temperature;
  final int maxTokens;

  const AIConfig({
    this.providerType = AIProviderType.localOllama,
    this.activeModelId = 'llama3.2',
    this.ollamaBaseUrl = 'http://127.0.0.1:11434',
    this.openAIBaseUrl = 'http://127.0.0.1:1234/v1',
    this.openAIApiKey,
    this.geminiApiKey,
    this.localFirst = true,
    this.temperature = 0.3,
    this.maxTokens = 1024,
  });

  AIConfig copyWith({
    AIProviderType? providerType,
    String? activeModelId,
    String? ollamaBaseUrl,
    String? openAIBaseUrl,
    String? openAIApiKey,
    String? geminiApiKey,
    bool? localFirst,
    double? temperature,
    int? maxTokens,
  }) {
    return AIConfig(
      providerType: providerType ?? this.providerType,
      activeModelId: activeModelId ?? this.activeModelId,
      ollamaBaseUrl: ollamaBaseUrl ?? this.ollamaBaseUrl,
      openAIBaseUrl: openAIBaseUrl ?? this.openAIBaseUrl,
      openAIApiKey: openAIApiKey ?? this.openAIApiKey,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      localFirst: localFirst ?? this.localFirst,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'providerType': providerType.name,
        'activeModelId': activeModelId,
        'ollamaBaseUrl': ollamaBaseUrl,
        'openAIBaseUrl': openAIBaseUrl,
        'openAIApiKey': openAIApiKey,
        'geminiApiKey': geminiApiKey,
        'localFirst': localFirst,
        'temperature': temperature,
        'maxTokens': maxTokens,
      };

  factory AIConfig.fromJson(Map<String, Object?> json) {
    final providerName = json['providerType'] as String?;
    final providerType = AIProviderType.values.firstWhere(
      (p) => p.name == providerName,
      orElse: () => AIProviderType.localOllama,
    );
    return AIConfig(
      providerType: providerType,
      activeModelId: json['activeModelId'] as String? ?? 'llama3.2',
      ollamaBaseUrl:
          json['ollamaBaseUrl'] as String? ?? 'http://127.0.0.1:11434',
      openAIBaseUrl:
          json['openAIBaseUrl'] as String? ?? 'http://127.0.0.1:1234/v1',
      openAIApiKey: json['openAIApiKey'] as String?,
      geminiApiKey: json['geminiApiKey'] as String?,
      localFirst: json['localFirst'] as bool? ?? true,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.3,
      maxTokens: json['maxTokens'] as int? ?? 1024,
    );
  }
}

/// Request for an AI reading assistant operation.
@immutable
class AIReadingRequest {
  final AIReadingTask task;
  final String text;
  final AIContextScope contextScope;
  final String? documentId;
  final String? documentName;
  final int? pageNumber;
  final List<SourceReference> contextChunks;
  final AISummaryLength summaryLength;
  final AISimplifyLevel simplifyLevel;
  final String? userQuestion;
  final String? targetLanguage;
  final String? customInstruction;

  const AIReadingRequest({
    required this.task,
    required this.text,
    this.contextScope = AIContextScope.selection,
    this.documentId,
    this.documentName,
    this.pageNumber,
    this.contextChunks = const [],
    this.summaryLength = AISummaryLength.medium,
    this.simplifyLevel = AISimplifyLevel.simple,
    this.userQuestion,
    this.targetLanguage,
    this.customInstruction,
  });

  Map<String, Object?> toJson() => <String, Object?>{
        'task': task.name,
        'text': text,
        'contextScope': contextScope.name,
        'documentId': documentId,
        'documentName': documentName,
        'pageNumber': pageNumber,
        'contextChunks': contextChunks.map((c) => c.toJson()).toList(),
        'summaryLength': summaryLength.name,
        'simplifyLevel': simplifyLevel.name,
        'userQuestion': userQuestion,
        'targetLanguage': targetLanguage,
        'customInstruction': customInstruction,
      };

  factory AIReadingRequest.fromJson(Map<String, Object?> json) {
    final taskName = json['task'] as String?;
    final task = AIReadingTask.values.firstWhere(
      (t) => t.name == taskName,
      orElse: () => AIReadingTask.explain,
    );
    final scopeName = json['contextScope'] as String?;
    final contextScope = AIContextScope.values.firstWhere(
      (s) => s.name == scopeName,
      orElse: () => AIContextScope.selection,
    );
    final rawChunks = json['contextChunks'];
    final chunks = rawChunks is List
        ? rawChunks
            .whereType<Map<String, Object?>>()
            .map(SourceReference.fromJson)
            .toList()
        : const <SourceReference>[];
    return AIReadingRequest(
      task: task,
      text: json['text'] as String? ?? '',
      contextScope: contextScope,
      documentId: json['documentId'] as String?,
      documentName: json['documentName'] as String?,
      pageNumber: json['pageNumber'] as int?,
      contextChunks: List.unmodifiable(chunks),
      summaryLength: AISummaryLength.values.firstWhere(
        (s) => s.name == json['summaryLength'],
        orElse: () => AISummaryLength.medium,
      ),
      simplifyLevel: AISimplifyLevel.values.firstWhere(
        (s) => s.name == json['simplifyLevel'],
        orElse: () => AISimplifyLevel.simple,
      ),
      userQuestion: json['userQuestion'] as String?,
      targetLanguage: json['targetLanguage'] as String?,
      customInstruction: json['customInstruction'] as String?,
    );
  }
}

/// Result of an AI reading assistant operation.
@immutable
class AIReadingResponse {
  final String text;
  final AIReadingTask task;
  final String providerId;
  final String modelId;
  final List<SourceReference> sources;
  final List<AIFlashcard> flashcards;
  final List<AIQuestion> questions;
  final List<String> extractedKeyTerms;
  final DateTime createdAt;

  const AIReadingResponse({
    required this.text,
    required this.task,
    required this.providerId,
    required this.modelId,
    this.sources = const [],
    this.flashcards = const [],
    this.questions = const [],
    this.extractedKeyTerms = const [],
    required this.createdAt,
  });

  Map<String, Object?> toJson() => <String, Object?>{
        'text': text,
        'task': task.name,
        'providerId': providerId,
        'modelId': modelId,
        'sources': sources.map((s) => s.toJson()).toList(),
        'flashcards': flashcards.map((f) => f.toJson()).toList(),
        'questions': questions.map((q) => q.toJson()).toList(),
        'extractedKeyTerms': extractedKeyTerms,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AIReadingResponse.fromJson(Map<String, Object?> json) {
    final taskName = json['task'] as String?;
    final task = AIReadingTask.values.firstWhere(
      (t) => t.name == taskName,
      orElse: () => AIReadingTask.explain,
    );
    final rawSources = json['sources'];
    final sources = rawSources is List
        ? rawSources
            .whereType<Map<String, Object?>>()
            .map(SourceReference.fromJson)
            .toList()
        : const <SourceReference>[];
    final rawFlashcards = json['flashcards'];
    final flashcards = rawFlashcards is List
        ? rawFlashcards
            .whereType<Map<String, Object?>>()
            .map(AIFlashcard.fromJson)
            .toList()
        : const <AIFlashcard>[];
    final rawQuestions = json['questions'];
    final questions = rawQuestions is List
        ? rawQuestions
            .whereType<Map<String, Object?>>()
            .map(AIQuestion.fromJson)
            .toList()
        : const <AIQuestion>[];
    final rawTerms = json['extractedKeyTerms'];
    final terms = rawTerms is List
        ? List<String>.unmodifiable(rawTerms.whereType<String>())
        : const <String>[];
    return AIReadingResponse(
      text: json['text'] as String? ?? '',
      task: task,
      providerId: json['providerId'] as String? ?? 'unknown',
      modelId: json['modelId'] as String? ?? 'unknown',
      sources: List.unmodifiable(sources),
      flashcards: List.unmodifiable(flashcards),
      questions: List.unmodifiable(questions),
      extractedKeyTerms: terms,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

/// Message in an AI reading conversation.
@immutable
class AIReadingMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final List<SourceReference> sources;

  const AIReadingMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.sources = const [],
  });

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'content': content,
        'isUser': isUser,
        'timestamp': timestamp.toIso8601String(),
        'sources': sources.map((s) => s.toJson()).toList(),
      };

  factory AIReadingMessage.fromJson(Map<String, Object?> json) {
    final rawSources = json['sources'];
    final sources = rawSources is List
        ? rawSources
            .whereType<Map<String, Object?>>()
            .map(SourceReference.fromJson)
            .toList()
        : const <SourceReference>[];
    return AIReadingMessage(
      id: json['id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      isUser: json['isUser'] as bool? ?? false,
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      sources: List.unmodifiable(sources),
    );
  }
}

/// Document-scoped AI conversation.
@immutable
class AIReadingConversation {
  final String id;
  final String documentId;
  final String title;
  final List<AIReadingMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AIReadingConversation({
    required this.id,
    required this.documentId,
    required this.title,
    this.messages = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'documentId': documentId,
        'title': title,
        'messages': messages.map((m) => m.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory AIReadingConversation.fromJson(Map<String, Object?> json) {
    final rawMessages = json['messages'];
    final messages = rawMessages is List
        ? rawMessages
            .whereType<Map<String, Object?>>()
            .map(AIReadingMessage.fromJson)
            .toList()
        : const <AIReadingMessage>[];
    return AIReadingConversation(
      id: json['id'] as String? ?? '',
      documentId: json['documentId'] as String? ?? '',
      title: json['title'] as String? ?? 'Conversation',
      messages: List.unmodifiable(messages),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
