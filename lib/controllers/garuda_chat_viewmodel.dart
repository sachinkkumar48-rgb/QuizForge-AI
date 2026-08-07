import 'dart:async';
import 'package:flutter/foundation.dart';

/// Enum for supported Chat Message Types
enum ChatMessageType {
  user,
  assistant,
  system,
  error,
  loading,
}

/// DTO representing an individual message in GARUDA AI Chat
class ChatMessageDto {
  final String id;
  final ChatMessageType type;
  final String content;
  final DateTime timestamp;
  final String? requestId;
  final bool isStreaming;
  final String? groundedPdfName;

  const ChatMessageDto({
    required this.id,
    required this.type,
    required this.content,
    required this.timestamp,
    this.requestId,
    this.isStreaming = false,
    this.groundedPdfName,
  });

  ChatMessageDto copyWith({
    String? id,
    ChatMessageType? type,
    String? content,
    DateTime? timestamp,
    String? requestId,
    bool? isStreaming,
    String? groundedPdfName,
  }) {
    return ChatMessageDto(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      requestId: requestId ?? this.requestId,
      isStreaming: isStreaming ?? this.isStreaming,
      groundedPdfName: groundedPdfName ?? this.groundedPdfName,
    );
  }
}

/// DTO representing an active GARUDA Chat Session
class ChatSessionDto {
  final String sessionId;
  final String userId;
  final String topicId;
  final String topicName;
  final String? pdfDocumentId;
  final String? pdfDocumentName;

  const ChatSessionDto({
    required this.sessionId,
    required this.userId,
    required this.topicId,
    required this.topicName,
    this.pdfDocumentId,
    this.pdfDocumentName,
  });

  bool get isPdfSession => pdfDocumentId != null && pdfDocumentId!.isNotEmpty;
}

/// Abstract Repository Interface for GARUDA AI Chat
abstract class GarudaChatRepository {
  Future<List<ChatMessageDto>> loadConversationHistory(String sessionId);
  Stream<String> sendMessageStream({
    required String sessionId,
    required String userMessage,
    bool isPdfSession = false,
    String? pdfDocumentId,
  });
}

/// Mock Implementation of GarudaChatRepository for zero-network testing & offline execution
class MockGarudaChatRepository implements GarudaChatRepository {
  @override
  Future<List<ChatMessageDto>> loadConversationHistory(String sessionId) async {
    return [
      ChatMessageDto(
        id: 'msg_sys_0',
        type: ChatMessageType.system,
        content: 'GARUDA AI Socratic Tutor initialized. Ask any question to begin.',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      ChatMessageDto(
        id: 'msg_user_1',
        type: ChatMessageType.user,
        content: 'Explain Article 14 of the Indian Constitution.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 50)),
      ),
      ChatMessageDto(
        id: 'msg_asst_1',
        type: ChatMessageType.assistant,
        content: 'Article 14 guarantees **Equality Before Law** and **Equal Protection of Laws**.\n\n### Key Concepts:\n- **Equality Before Law**: Negative concept derived from British law.\n- **Equal Protection of Laws**: Positive concept derived from American law.\n\n```python\ndef check_equality(person_a, person_b):\n    return person_a.rights == person_b.rights\n```',
        timestamp: DateTime.now().subtract(const Duration(minutes: 49)),
        requestId: 'req_pdf_mock_001',
      ),
    ];
  }

  @override
  Stream<String> sendMessageStream({
    required String sessionId,
    required String userMessage,
    bool isPdfSession = false,
    String? pdfDocumentId,
  }) async* {
    final prefix = isPdfSession ? '[Grounded in PDF] ' : '';
    final tokens = [
      '$prefix Socratic Analysis: ',
      'Regarding your question about "${userMessage.trim()}", ',
      'let us break this down into **key principles**:\n\n',
      '1. **Core Definition**: The underlying framework guarantees fairness.\n',
      '2. **Judicial Precedents**: Key Supreme Court landmark judgements apply.\n\n',
      '```sql\nSELECT * FROM fundamental_rights WHERE article = 14;\n```\n\n',
      'Would you like to solve a practice quiz on this topic?',
    ];

    for (final token in tokens) {
      await Future.delayed(const Duration(milliseconds: 150));
      yield token;
    }
  }
}

/// ViewModel for GARUDA AI Chat Experience (MVVM Architecture)
class GarudaChatViewModel extends ChangeNotifier {
  final GarudaChatRepository repository;
  final ChatSessionDto _session;


  List<ChatMessageDto> _messages = [];
  bool _isLoading = false;
  bool _isGenerating = false;
  bool _developerMode = false;
  bool _showScrollToBottom = false;
  String? _errorMessage;
  StreamSubscription<String>? _streamSubscription;

  GarudaChatViewModel({
    required ChatSessionDto session,
    GarudaChatRepository? repository,
  })  : _session = session,
        repository = repository ?? MockGarudaChatRepository();

  ChatSessionDto get session => _session;
  List<ChatMessageDto> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  bool get developerMode => _developerMode;
  bool get showScrollToBottom => _showScrollToBottom;
  String? get errorMessage => _errorMessage;

  void toggleDeveloperMode() {
    _developerMode = !_developerMode;
    notifyListeners();
  }

  void updateScrollPosition(double offset, double maxScroll) {
    final shouldShow = offset < maxScroll - 200;
    if (shouldShow != _showScrollToBottom) {
      _showScrollToBottom = shouldShow;
      notifyListeners();
    }
  }

  Future<void> loadSessionHistory() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _messages = await repository.loadConversationHistory(_session.sessionId);
      _isLoading = false;
    } catch (e) {
      _errorMessage = 'Failed to load conversation history: $e';
      _isLoading = false;
    }
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty || _isGenerating) return;

    final userMsgId = 'msg_usr_${DateTime.now().millisecondsSinceEpoch}';
    final userMsg = ChatMessageDto(
      id: userMsgId,
      type: ChatMessageType.user,
      content: trimmedText,
      timestamp: DateTime.now(),
    );

    final asstMsgId = 'msg_ast_${DateTime.now().millisecondsSinceEpoch}';
    final reqId = _session.isPdfSession
        ? 'req_pdf_${DateTime.now().millisecondsSinceEpoch}'
        : 'req_tut_${DateTime.now().millisecondsSinceEpoch}';

    final asstMsgPlaceholder = ChatMessageDto(
      id: asstMsgId,
      type: ChatMessageType.assistant,
      content: '',
      timestamp: DateTime.now(),
      requestId: reqId,
      isStreaming: true,
      groundedPdfName: _session.pdfDocumentName,
    );

    _messages.add(userMsg);
    _messages.add(asstMsgPlaceholder);
    _isGenerating = true;
    _errorMessage = null;
    notifyListeners();

    final buffer = StringBuffer();

    _streamSubscription = repository
        .sendMessageStream(
      sessionId: _session.sessionId,
      userMessage: trimmedText,
      isPdfSession: _session.isPdfSession,
      pdfDocumentId: _session.pdfDocumentId,
    )
        .listen(
      (token) {
        buffer.write(token);
        final index = _messages.indexWhere((m) => m.id == asstMsgId);
        if (index != -1) {
          _messages[index] = _messages[index].copyWith(
            content: buffer.toString(),
            isStreaming: true,
          );
          notifyListeners();
        }
      },
      onError: (err) {
        _isGenerating = false;
        final index = _messages.indexWhere((m) => m.id == asstMsgId);
        if (index != -1) {
          _messages[index] = ChatMessageDto(
            id: 'msg_err_${DateTime.now().millisecondsSinceEpoch}',
            type: ChatMessageType.error,
            content: 'Error generating response: $err',
            timestamp: DateTime.now(),
          );
        }
        notifyListeners();
      },
      onDone: () {
        _isGenerating = false;
        final index = _messages.indexWhere((m) => m.id == asstMsgId);
        if (index != -1) {
          _messages[index] = _messages[index].copyWith(
            isStreaming: false,
          );
        }
        notifyListeners();
      },
    );
  }

  void stopGeneration() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _isGenerating = false;

    if (_messages.isNotEmpty && _messages.last.isStreaming) {
      _messages[_messages.length - 1] = _messages.last.copyWith(
        isStreaming: false,
      );
    }
    notifyListeners();
  }

  Future<void> retryLastMessage() async {
    if (_isGenerating || _messages.isEmpty) return;

    String? lastUserText;
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].type == ChatMessageType.user) {
        lastUserText = _messages[i].content;
        break;
      }
    }

    if (lastUserText != null) {
      if (_messages.last.type == ChatMessageType.assistant ||
          _messages.last.type == ChatMessageType.error) {
        _messages.removeLast();
      }
      await sendMessage(lastUserText);
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}
