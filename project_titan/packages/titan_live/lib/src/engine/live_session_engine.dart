import 'dart:async';
import '../models/live_models.dart';

/// Pure Dart Live Session Engine for Project TITAN.
/// Manages session lifecycle, participant state, real-time chat event streams,
/// interactive polling, whiteboard snapshots, recording state, reconnect handling,
/// and stream updates without any Flutter dependency.
class LiveSessionEngine {
  LiveSession _currentSession;
  final StreamController<LiveSession> _sessionStreamController =
      StreamController<LiveSession>.broadcast();
  final StreamController<ChatMessage> _chatStreamController =
      StreamController<ChatMessage>.broadcast();
  final StreamController<Poll> _pollStreamController =
      StreamController<Poll>.broadcast();

  LiveSessionEngine({required LiveSession initialSession})
      : _currentSession = initialSession;

  /// Current live session snapshot.
  LiveSession get currentSession => _currentSession;

  /// Stream of live session updates.
  Stream<LiveSession> get sessionStream => _sessionStreamController.stream;

  /// Stream of live chat messages.
  Stream<ChatMessage> get chatStream => _chatStreamController.stream;

  /// Stream of active poll updates.
  Stream<Poll> get pollStream => _pollStreamController.stream;

  // ==========================================
  // SESSION LIFECYCLE MANAGEMENT
  // ==========================================

  /// Opens the waiting room for the live class.
  LiveSession openWaitingRoom() {
    _currentSession = _currentSession.copyWith(
      status: LiveSessionStatus.waitingRoomOpen,
    );
    _notifySessionUpdate();
    return _currentSession;
  }

  /// Starts the live session.
  LiveSession startSession() {
    final now = DateTime.now();
    _currentSession = _currentSession.copyWith(
      status: LiveSessionStatus.live,
      actualStartTime: now,
    );
    _notifySessionUpdate();
    return _currentSession;
  }

  /// Pauses the live session.
  LiveSession pauseSession() {
    _currentSession = _currentSession.copyWith(
      status: LiveSessionStatus.paused,
    );
    _notifySessionUpdate();
    return _currentSession;
  }

  /// Resumes a paused live session.
  LiveSession resumeSession() {
    _currentSession = _currentSession.copyWith(
      status: LiveSessionStatus.live,
    );
    _notifySessionUpdate();
    return _currentSession;
  }

  /// Ends the live session.
  LiveSession endSession() {
    final now = DateTime.now();
    _currentSession = _currentSession.copyWith(
      status: LiveSessionStatus.ended,
      actualEndTime: now,
    );
    _notifySessionUpdate();
    return _currentSession;
  }

  // ==========================================
  // PARTICIPANT STATE MANAGEMENT
  // ==========================================

  /// Adds a participant to the session.
  LiveSession addParticipant(Participant participant) {
    final updatedList = List<Participant>.from(_currentSession.participants)
      ..removeWhere((p) => p.userId == participant.userId)
      ..add(participant);

    _currentSession = _currentSession.copyWith(participants: updatedList);
    _notifySessionUpdate();
    return _currentSession;
  }

  /// Removes a participant from the session.
  LiveSession removeParticipant(String userId) {
    final now = DateTime.now();
    final updatedList = _currentSession.participants.map((p) {
      if (p.userId == userId) {
        return p.copyWith(leftAt: now);
      }
      return p;
    }).toList();

    _currentSession = _currentSession.copyWith(participants: updatedList);
    _notifySessionUpdate();
    return _currentSession;
  }

  /// Toggles hand raised status for a participant.
  LiveSession toggleRaiseHand(String userId, bool isHandRaised) {
    final updatedList = _currentSession.participants.map((p) {
      if (p.userId == userId) {
        return p.copyWith(isHandRaised: isHandRaised);
      }
      return p;
    }).toList();

    _currentSession = _currentSession.copyWith(participants: updatedList);
    _notifySessionUpdate();
    return _currentSession;
  }

  /// Toggles audio mute status for a participant.
  LiveSession toggleMuteParticipant(String userId, bool isMuted) {
    final updatedList = _currentSession.participants.map((p) {
      if (p.userId == userId) {
        return p.copyWith(isMuted: isMuted);
      }
      return p;
    }).toList();

    _currentSession = _currentSession.copyWith(participants: updatedList);
    _notifySessionUpdate();
    return _currentSession;
  }

  // ==========================================
  // REAL-TIME CHAT EVENTS
  // ==========================================

  /// Sends and broadcasts a chat message.
  ChatMessage sendChatMessage({
    required String senderId,
    required String senderName,
    required ParticipantRole senderRole,
    required String messageText,
    ChatMessageType type = ChatMessageType.text,
  }) {
    final message = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      sessionId: _currentSession.id,
      senderId: senderId,
      senderName: senderName,
      senderRole: senderRole,
      message: messageText,
      type: type,
      timestamp: DateTime.now(),
    );

    final updatedMessages = List<ChatMessage>.from(_currentSession.chatMessages)
      ..add(message);

    _currentSession = _currentSession.copyWith(chatMessages: updatedMessages);
    _chatStreamController.add(message);
    _notifySessionUpdate();
    return message;
  }

  // ==========================================
  // INTERACTIVE POLLING
  // ==========================================

  /// Creates and launches a poll.
  Poll createPoll({
    required String question,
    required List<String> optionTexts,
  }) {
    final now = DateTime.now();
    final options = optionTexts.asMap().entries.map((e) {
      return PollOption(
        id: 'opt_${e.key}_${now.millisecondsSinceEpoch}',
        optionText: e.value,
        voteCount: 0,
      );
    }).toList();

    final poll = Poll(
      id: 'poll_${now.millisecondsSinceEpoch}',
      sessionId: _currentSession.id,
      question: question,
      options: options,
      status: PollStatus.active,
      createdAt: now,
    );

    _currentSession = _currentSession.copyWith(activePoll: poll);
    _pollStreamController.add(poll);
    _notifySessionUpdate();
    return poll;
  }

  /// Casts a vote on the active poll.
  Poll? votePoll({
    required String userId,
    required String optionId,
  }) {
    final currentPoll = _currentSession.activePoll;
    if (currentPoll == null || currentPoll.status != PollStatus.active) {
      return null;
    }

    final updatedUserVotes = Map<String, String>.from(currentPoll.userVotes)
      ..[userId] = optionId;

    // Recalculate option votes
    final updatedOptions = currentPoll.options.map((opt) {
      final votesForOpt =
          updatedUserVotes.values.where((id) => id == opt.id).length;
      return opt.copyWith(voteCount: votesForOpt);
    }).toList();

    final updatedPoll = currentPoll.copyWith(
      options: updatedOptions,
      userVotes: updatedUserVotes,
    );

    _currentSession = _currentSession.copyWith(activePoll: updatedPoll);
    _pollStreamController.add(updatedPoll);
    _notifySessionUpdate();
    return updatedPoll;
  }

  /// Closes the active poll and calculates results.
  PollResult? closePoll() {
    final currentPoll = _currentSession.activePoll;
    if (currentPoll == null) return null;

    final closedPoll = currentPoll.copyWith(
      status: PollStatus.closed,
      closedAt: DateTime.now(),
    );

    _currentSession = _currentSession.copyWith(activePoll: closedPoll);

    final optionVotes = <String, int>{};
    String? winningOptId;
    int maxVotes = -1;

    for (final opt in closedPoll.options) {
      optionVotes[opt.id] = opt.voteCount;
      if (opt.voteCount > maxVotes) {
        maxVotes = opt.voteCount;
        winningOptId = opt.id;
      }
    }

    final result = PollResult(
      pollId: closedPoll.id,
      totalVotes: closedPoll.userVotes.length,
      optionVotes: optionVotes,
      winningOptionId: winningOptId,
    );

    _pollStreamController.add(closedPoll);
    _notifySessionUpdate();
    return result;
  }

  // ==========================================
  // WHITEBOARD SNAPSHOTS
  // ==========================================

  /// Captures a whiteboard snapshot.
  WhiteboardSnapshot addWhiteboardSnapshot({
    required String title,
    required String drawingDataJson,
    required String capturedBy,
    String? imageUrl,
  }) {
    final snapshot = WhiteboardSnapshot(
      id: 'wb_${DateTime.now().millisecondsSinceEpoch}',
      sessionId: _currentSession.id,
      title: title,
      imageUrl: imageUrl,
      drawingDataJson: drawingDataJson,
      capturedAt: DateTime.now(),
      capturedBy: capturedBy,
    );

    final updatedSnapshots =
        List<WhiteboardSnapshot>.from(_currentSession.whiteboardSnapshots)
          ..add(snapshot);

    _currentSession =
        _currentSession.copyWith(whiteboardSnapshots: updatedSnapshots);
    _notifySessionUpdate();
    return snapshot;
  }

  // ==========================================
  // RECORDING STATE MANAGEMENT
  // ==========================================

  /// Starts recording the live session.
  Recording startRecording() {
    final now = DateTime.now();
    final rec = Recording(
      id: 'rec_${now.millisecondsSinceEpoch}',
      sessionId: _currentSession.id,
      durationSeconds: 0,
      status: RecordingStatus.recording,
      createdAt: now,
    );

    _currentSession = _currentSession.copyWith(recording: rec);
    _notifySessionUpdate();
    return rec;
  }

  /// Stops recording and prepares recording metadata.
  Recording stopRecording({
    required int durationSeconds,
    required String videoUrl,
    required int fileSizeBytes,
    String? learningContentId,
  }) {
    final currentRec = _currentSession.recording;
    final updatedRec = Recording(
      id: currentRec?.id ?? 'rec_${DateTime.now().millisecondsSinceEpoch}',
      sessionId: _currentSession.id,
      videoUrl: videoUrl,
      durationSeconds: durationSeconds,
      fileSizeBytes: fileSizeBytes,
      status: RecordingStatus.ready,
      createdAt: currentRec?.createdAt ?? DateTime.now(),
      learningContentId: learningContentId,
    );

    _currentSession = _currentSession.copyWith(recording: updatedRec);
    _notifySessionUpdate();
    return updatedRec;
  }

  // ==========================================
  // RECONNECT HANDLING & NETWORK AWARENESS
  // ==========================================

  /// Handles participant reconnect attempt.
  LiveSession handleParticipantReconnect(String userId) {
    final updatedList = _currentSession.participants.map((p) {
      if (p.userId == userId) {
        return p.copyWith(leftAt: null);
      }
      return p;
    }).toList();

    _currentSession = _currentSession.copyWith(participants: updatedList);
    _notifySessionUpdate();
    return _currentSession;
  }

  void _notifySessionUpdate() {
    if (!_sessionStreamController.isClosed) {
      _sessionStreamController.add(_currentSession);
    }
  }

  /// Disposes engine streams.
  Future<void> dispose() async {
    await _sessionStreamController.close();
    await _chatStreamController.close();
    await _pollStreamController.close();
  }
}
