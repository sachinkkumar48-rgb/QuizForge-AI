library;

import 'dart:async';
import 'dart:convert';

import '../domain/entities/ai_reading_models.dart';
import '../domain/entities/ai_reading_task.dart';
import 'ai_reading_provider.dart';

/// Deterministic mock provider for tests and offline development.
class MockAIReadingProvider implements AIReadingProvider {
  String? scriptedResponse;
  Stream<String>? scriptedStream;
  Exception? errorToThrow;
  int streamChunkDelayMs;

  MockAIReadingProvider({
    this.scriptedResponse,
    this.scriptedStream,
    this.errorToThrow,
    this.streamChunkDelayMs = 0,
  });

  @override
  String get providerId => 'mock';

  @override
  String get displayName => 'Mock AI Provider';

  @override
  bool get isLocal => true;

  @override
  Future<List<AIModelInfo>> listModels() async {
    return const [
      AIModelInfo(
        id: 'mock-llama-3',
        displayName: 'Mock Llama 3',
        providerId: 'mock',
        isLocal: true,
        contextWindow: 8192,
      ),
      AIModelInfo(
        id: 'mock-fast-model',
        displayName: 'Mock Fast Model',
        providerId: 'mock',
        isLocal: true,
        contextWindow: 4096,
      ),
    ];
  }

  @override
  Future<AIReadingResponse> generate(
    AIReadingRequest request, {
    required AIConfig config,
    AICancellationToken? cancelToken,
  }) async {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    if (cancelToken?.isCancelled ?? false) {
      throw TimeoutException('AI request cancelled.');
    }

    final text = scriptedResponse ?? _defaultResponseFor(request);
    return _buildResponse(request, text, config);
  }

  @override
  Stream<String> generateStream(
    AIReadingRequest request, {
    required AIConfig config,
    AICancellationToken? cancelToken,
  }) async* {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }

    if (scriptedStream != null) {
      await for (final chunk in scriptedStream!) {
        if (cancelToken?.isCancelled ?? false) break;
        yield chunk;
      }
      return;
    }

    final fullText = scriptedResponse ?? _defaultResponseFor(request);
    final words = fullText.split(' ');
    for (var i = 0; i < words.length; i++) {
      if (cancelToken?.isCancelled ?? false) break;
      final piece = (i == words.length - 1) ? words[i] : '${words[i]} ';
      if (streamChunkDelayMs > 0) {
        await Future<void>.delayed(Duration(milliseconds: streamChunkDelayMs));
      }
      yield piece;
    }
  }

  AIReadingResponse _buildResponse(
    AIReadingRequest request,
    String text,
    AIConfig config,
  ) {
    List<AIFlashcard> flashcards = const [];
    List<AIQuestion> questions = const [];
    List<String> keyTerms = const [];

    if (request.task == AIReadingTask.generateFlashcards) {
      flashcards = _tryParseFlashcards(text, request);
    } else if (request.task == AIReadingTask.generateQuestions) {
      questions = _tryParseQuestions(text, request);
    } else if (request.task == AIReadingTask.explain) {
      keyTerms = _extractKeyTerms(text);
    }

    return AIReadingResponse(
      text: text,
      task: request.task,
      providerId: providerId,
      modelId: config.activeModelId,
      sources: request.contextChunks,
      flashcards: flashcards,
      questions: questions,
      extractedKeyTerms: keyTerms,
      createdAt: DateTime.now(),
    );
  }

  String _defaultResponseFor(AIReadingRequest request) {
    switch (request.task) {
      case AIReadingTask.explain:
        return 'Explanation: ${request.text}\n\n'
            'Key Concept: This text discusses fundamental principles.\n'
            'Important Terms: Principle, Analysis, Context.';

      case AIReadingTask.simplify:
        return 'Simplified: ${request.text} (written in simpler language with facts preserved).';

      case AIReadingTask.summarize:
        return 'Summary of content: The passage provides an overview of the key topics.';

      case AIReadingTask.askQuestion:
        if (request.contextChunks.isNotEmpty) {
          final pages = request.contextChunks
              .map((c) => 'Page ${c.pageNumber}')
              .toSet()
              .join(', ');
          return 'Based on the document ($pages), the answer to "${request.userQuestion}" is directly addressed in the text.';
        }
        return 'I answered "${request.userQuestion}" using the provided text context.';

      case AIReadingTask.keyPoints:
        return '• Key Point 1: Core argument\n• Key Point 2: Supporting evidence\n• Key Point 3: Conclusion';

      case AIReadingTask.generateFlashcards:
        return jsonEncode([
          {'front': 'What is the main topic?', 'back': 'The selected subject.'},
          {'front': 'Define key term', 'back': 'The primary definition.'}
        ]);

      case AIReadingTask.generateQuestions:
        return jsonEncode([
          {
            'question': 'What is the primary theme?',
            'options': ['Theme A', 'Theme B', 'Theme C', 'Theme D'],
            'correctOptionIndex': 0,
            'explanation': 'Theme A is explicitly mentioned in the text.'
          }
        ]);

      case AIReadingTask.translate:
        return 'Translated [${request.targetLanguage ?? "English"}]: ${request.text}';
    }
  }

  List<AIFlashcard> _tryParseFlashcards(String text, AIReadingRequest req) {
    try {
      final jsonStr = _extractJson(text);
      final decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        return decoded.whereType<Map<String, Object?>>().map((m) {
          return AIFlashcard(
            id: 'fc_${DateTime.now().microsecondsSinceEpoch}',
            front: m['front'] as String? ?? 'Front',
            back: m['back'] as String? ?? 'Back',
            documentId: req.documentId,
            pageNumber: req.pageNumber,
            createdAt: DateTime.now(),
          );
        }).toList();
      }
    } catch (_) {}
    return const [];
  }

  List<AIQuestion> _tryParseQuestions(String text, AIReadingRequest req) {
    try {
      final jsonStr = _extractJson(text);
      final decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        return decoded.whereType<Map<String, Object?>>().map((m) {
          return AIQuestion(
            id: 'q_${DateTime.now().microsecondsSinceEpoch}',
            question: m['question'] as String? ?? 'Question',
            options: (m['options'] as List?)?.whereType<String>().toList() ??
                const [],
            correctOptionIndex: m['correctOptionIndex'] as int?,
            explanation: m['explanation'] as String? ?? '',
            documentId: req.documentId,
            pageNumber: req.pageNumber,
          );
        }).toList();
      }
    } catch (_) {}
    return const [];
  }

  List<String> _extractKeyTerms(String text) {
    if (text.contains('Important Terms:')) {
      final part = text.split('Important Terms:').last;
      return part
          .split(',')
          .map((s) => s.trim().replaceAll('.', ''))
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return const ['Concept', 'Principle'];
  }

  String _extractJson(String raw) {
    var s = raw.trim();
    if (s.contains('```json')) {
      s = s.split('```json')[1].split('```')[0].trim();
    } else if (s.contains('```')) {
      s = s.split('```')[1].split('```')[0].trim();
    }
    return s;
  }
}
