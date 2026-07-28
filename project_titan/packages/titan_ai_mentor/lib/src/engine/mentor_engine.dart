import 'dart:async';
import 'package:titan_ai/titan_ai.dart';

import '../models/mentor_context.dart';
import '../models/mentor_message.dart';
import '../models/mentor_session.dart';
import '../providers/mentor_provider.dart';
import '../providers/mock_mentor_provider.dart';
import '../repository/mentor_repository.dart';
import 'context_builder.dart';
import 'conversation_memory_manager.dart';
import 'prompt_builder.dart';

/// Central AI Mentor 2.0 orchestration engine powered by clean architecture,
/// production AIOrchestrator, ContextBuilder, and ConversationMemoryManager.
class MentorEngine {
  final MentorRepository _repository;
  final MentorProvider _provider;
  final ContextBuilder _contextBuilder;
  final PromptBuilder _promptBuilder;
  final ConversationMemoryManager _memoryManager;
  final AIOrchestrator? _orchestrator;

  final StreamController<MentorMessage> _messageStreamController =
      StreamController<MentorMessage>.broadcast();

  MentorEngine({
    required MentorRepository repository,
    MentorProvider? provider,
    ContextBuilder? contextBuilder,
    PromptBuilder? promptBuilder,
    ConversationMemoryManager? memoryManager,
    AIOrchestrator? orchestrator,
  })  : _repository = repository,
        _provider = provider ?? MockMentorProvider(),
        _contextBuilder = contextBuilder ?? const ContextBuilder(),
        _promptBuilder = promptBuilder ?? const PromptBuilder(),
        _memoryManager = memoryManager ?? ConversationMemoryManager(),
        _orchestrator = orchestrator;

  /// Real-time stream emitting generated mentor messages.
  Stream<MentorMessage> get messageStream => _messageStreamController.stream;

  /// AI Orchestrator instance if configured.
  AIOrchestrator? get orchestrator => _orchestrator;

  /// Assembles current learner context across all TITAN modules.
  Future<MentorContext> assembleContext({
    required String userId,
    required String userName,
    String targetExam = 'UPSC CSE',
  }) {
    return _contextBuilder.buildContext(
      userId: userId,
      userName: userName,
      targetExam: targetExam,
    );
  }

  /// Sends a prompt in an existing session or creates a new session if [sessionId] is null.
  Future<MentorMessage> ask({
    required String userId,
    required String userName,
    required String prompt,
    String? sessionId,
  }) async {
    final context = await assembleContext(userId: userId, userName: userName);

    MentorSession session;
    if (sessionId != null) {
      final found = await _repository.getSession(sessionId);
      session = found ??
          await _repository.createSession(
            userId: userId,
            title:
                prompt.length > 30 ? '${prompt.substring(0, 30)}...' : prompt,
          );
    } else {
      session = await _repository.createSession(
        userId: userId,
        title: prompt.length > 30 ? '${prompt.substring(0, 30)}...' : prompt,
      );
    }

    final userMessage = MentorMessage(
      id: 'msg_user_${DateTime.now().millisecondsSinceEpoch}',
      sender: MentorMessageSender.user,
      content: prompt,
      timestamp: DateTime.now(),
    );

    await _repository.addMessage(session.id, userMessage);
    _memoryManager.addMessage(session.id, userMessage);
    _messageStreamController.add(userMessage);

    final updatedSession = await _repository.getSession(session.id);
    final history = updatedSession?.messages ?? [userMessage];
    final windowedHistory = _memoryManager.getWindowedHistory(session.id);

    final systemPrompt = _promptBuilder.buildSystemPrompt(context);

    MentorMessage responseMessage;
    final orch = _orchestrator;
    if (orch != null && orch.isInitialized) {
      final aiReq = AIRequest(
        prompt: prompt,
        systemPrompt: systemPrompt,
      );
      final aiResp = await orch.execute<String>(
        request: aiReq,
        templateId: 'mentor_guide',
        templateVariables: {
          'userName': userName,
          'targetExam': context.targetExam,
          'weakSubjects': context.weakSubjects.join(', '),
          'strongSubjects': context.strongSubjects.join(', '),
          'recommendedTopic': context.recommendedTopic,
          'pendingRevisionsCount': context.pendingRevisionsCount,
          'studyHoursCompleted': context.studyHoursCompleted,
          'studyHoursTarget': context.studyHoursTarget,
          'context': context.toString(),
          'userQuery': prompt,
        },
      );

      responseMessage = MentorMessage(
        id: 'msg_assistant_${DateTime.now().millisecondsSinceEpoch}',
        sender: MentorMessageSender.mentor,
        content: aiResp.text,
        timestamp: DateTime.now(),
      );
    } else {
      responseMessage = await _provider.generateResponse(
        context: context.copyWith(
          metadata: {'systemPrompt': systemPrompt},
        ),
        history: windowedHistory.isNotEmpty ? windowedHistory : history,
        userPrompt: prompt,
      );
    }

    await _repository.addMessage(session.id, responseMessage);
    _memoryManager.addMessage(session.id, responseMessage);
    _messageStreamController.add(responseMessage);

    if (_memoryManager.shouldSummarize(session.id)) {
      final summary = await _provider.summarizeConversation(history);
      _memoryManager.setSummary(session.id, summary);
      final finalSession = await _repository.getSession(session.id);
      if (finalSession != null) {
        await _repository.saveSession(finalSession.copyWith(summary: summary));
      }
    }

    return responseMessage;
  }

  /// Clean up stream resources on disposal.
  Future<void> dispose() async {
    await _messageStreamController.close();
  }
}
