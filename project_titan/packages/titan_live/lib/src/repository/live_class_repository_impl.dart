import '../models/live_models.dart';
import 'live_class_repository.dart';

/// Concrete offline-first implementation of [LiveClassRepository].
class LiveClassRepositoryImpl implements LiveClassRepository {
  final Map<String, LiveClass> _classStore = {};
  final Map<String, List<Attendance>> _attendanceStore = {};
  final Map<String, List<ChatMessage>> _chatStore = {};
  final Map<String, List<WhiteboardSnapshot>> _whiteboardStore = {};
  final Map<String, List<SessionReminder>> _reminderStore = {};

  LiveClassRepositoryImpl({List<LiveClass>? initialClasses}) {
    if (initialClasses != null && initialClasses.isNotEmpty) {
      for (final c in initialClasses) {
        _classStore[c.id] = c;
      }
    } else {
      _seedDefaultData();
    }
  }

  void _seedDefaultData() {
    final now = DateTime.now();
    final defaultSchedule = SessionSchedule(
      id: 'sched_01',
      liveClassId: 'lc_live_01',
      scheduledStartTime: now.add(const Duration(hours: 2)),
      scheduledEndTime: now.add(const Duration(hours: 4)),
      timeZone: 'IST',
    );

    final defaultSession = LiveSession(
      id: 'sess_01',
      liveClassId: 'lc_live_01',
      status: LiveSessionStatus.scheduled,
      participants: [
        Participant(
          id: 'p_inst_1',
          userId: 'inst_dr_sharma',
          name: 'Dr. Sharma',
          role: ParticipantRole.instructor,
          joinedAt: now,
          isMuted: false,
          isVideoOn: true,
        ),
      ],
      chatMessages: [
        ChatMessage(
          id: 'cm_01',
          sessionId: 'sess_01',
          senderId: 'inst_dr_sharma',
          senderName: 'Dr. Sharma',
          senderRole: ParticipantRole.instructor,
          message:
              'Welcome everyone! We will cover Article 21 and SC precedents today.',
          type: ChatMessageType.announcement,
          timestamp: now,
          isPinned: true,
        ),
      ],
      activePoll: Poll(
        id: 'poll_01',
        sessionId: 'sess_01',
        question: 'Is Right to Privacy a Fundamental Right under Article 21?',
        options: const [
          PollOption(
              id: 'opt_yes',
              optionText: 'Yes (Puttaswamy Ruling)',
              voteCount: 42),
          PollOption(id: 'opt_no', optionText: 'No', voteCount: 3),
        ],
        status: PollStatus.active,
        createdAt: now,
      ),
      whiteboardSnapshots: [
        WhiteboardSnapshot(
          id: 'wb_01',
          sessionId: 'sess_01',
          title: 'Article 21 & Due Process Diagram',
          drawingDataJson: '{"strokes": []}',
          capturedAt: now,
          capturedBy: 'Dr. Sharma',
        ),
      ],
      recording: Recording(
        id: 'rec_01',
        sessionId: 'sess_01',
        videoUrl: 'https://storage.titan.edu/recordings/lc_live_01.mp4',
        durationSeconds: 7200,
        fileSizeBytes: 450000000,
        status: RecordingStatus.ready,
        createdAt: now.subtract(const Duration(days: 1)),
        learningContentId: 'lc_rec_content_01',
      ),
      resources: [
        const LiveResource(
          id: 'res_01',
          sessionId: 'sess_01',
          title: 'Landmark Judgments Handout PDF',
          url: 'https://storage.titan.edu/handouts/article_21.pdf',
          type: LiveResourceType.pdf,
        ),
      ],
      knowledgeNodeIds: const ['node_polity_article21', 'node_kesavananda'],
    );

    final defaultClass = LiveClass(
      id: 'lc_live_01',
      title: 'Polity & Governance: Fundamental Rights & Article 21 Masterclass',
      description:
          'In-depth discussion of Article 21, Right to Life & Personal Liberty, Puttaswamy ruling, and Maneka Gandhi test.',
      subjectCategory: 'Polity',
      instructorId: 'inst_dr_sharma',
      instructorName: 'Dr. Sharma',
      schedule: defaultSchedule,
      activeSession: defaultSession,
      recording: defaultSession.recording,
      knowledgeNodeIds: const ['node_polity_article21'],
      createdAt: now.subtract(const Duration(days: 2)),
    );

    _classStore[defaultClass.id] = defaultClass;
    _chatStore[defaultSession.id] = List.from(defaultSession.chatMessages);
    _whiteboardStore[defaultSession.id] =
        List.from(defaultSession.whiteboardSnapshots);
  }

  @override
  Future<LiveClass?> getLiveClassById(String classId) async {
    return _classStore[classId];
  }

  @override
  Future<List<LiveClass>> getUpcomingClasses() async {
    final now = DateTime.now();
    return _classStore.values
        .where((c) =>
            c.schedule.scheduledStartTime.isAfter(now) ||
            c.activeSession?.status == LiveSessionStatus.live ||
            c.activeSession?.status == LiveSessionStatus.waitingRoomOpen)
        .toList();
  }

  @override
  Future<List<LiveClass>> getAllLiveClasses() async {
    return _classStore.values.toList();
  }

  @override
  Future<LiveClass> scheduleClass(LiveClass liveClass) async {
    _classStore[liveClass.id] = liveClass;
    return liveClass;
  }

  @override
  Future<LiveClass> updateClass(LiveClass liveClass) async {
    _classStore[liveClass.id] = liveClass;
    return liveClass;
  }

  @override
  Future<bool> cancelClass(String classId) async {
    final liveClass = _classStore[classId];
    if (liveClass != null) {
      final updatedSession = liveClass.activeSession?.copyWith(
        status: LiveSessionStatus.cancelled,
      );
      _classStore[classId] = liveClass.copyWith(activeSession: updatedSession);
      return true;
    }
    return false;
  }

  @override
  Future<Participant> joinSession(
      String sessionId, Participant participant) async {
    final liveClass = _classStore.values.firstWhere(
      (c) => c.activeSession?.id == sessionId,
      orElse: () => _classStore.values.first,
    );

    final session = liveClass.activeSession;
    if (session != null) {
      final updatedParticipants = List<Participant>.from(session.participants)
        ..removeWhere((p) => p.userId == participant.userId)
        ..add(participant);

      final updatedSession =
          session.copyWith(participants: updatedParticipants);
      _classStore[liveClass.id] =
          liveClass.copyWith(activeSession: updatedSession);
    }
    return participant;
  }

  @override
  Future<bool> leaveSession(String sessionId, String userId) async {
    final liveClass = _classStore.values.firstWhere(
      (c) => c.activeSession?.id == sessionId,
      orElse: () => _classStore.values.first,
    );

    final session = liveClass.activeSession;
    if (session != null) {
      final now = DateTime.now();
      final updatedParticipants = session.participants.map((p) {
        if (p.userId == userId) {
          return p.copyWith(leftAt: now);
        }
        return p;
      }).toList();

      final updatedSession =
          session.copyWith(participants: updatedParticipants);
      _classStore[liveClass.id] =
          liveClass.copyWith(activeSession: updatedSession);
      return true;
    }
    return false;
  }

  @override
  Future<Attendance> recordAttendance(Attendance attendance) async {
    final list = _attendanceStore.putIfAbsent(attendance.sessionId, () => []);
    list.removeWhere((a) => a.userId == attendance.userId);
    list.add(attendance);
    return attendance;
  }

  @override
  Future<List<Attendance>> getAttendanceForSession(String sessionId) async {
    return _attendanceStore[sessionId] ?? const [];
  }

  @override
  Future<ChatMessage> sendChatMessage(ChatMessage message) async {
    final list = _chatStore.putIfAbsent(message.sessionId, () => []);
    list.add(message);
    return message;
  }

  @override
  Future<List<ChatMessage>> getChatHistory(String sessionId) async {
    return _chatStore[sessionId] ?? const [];
  }

  @override
  Future<WhiteboardSnapshot> saveWhiteboardSnapshot(
      WhiteboardSnapshot snapshot) async {
    final list = _whiteboardStore.putIfAbsent(snapshot.sessionId, () => []);
    list.add(snapshot);
    return snapshot;
  }

  @override
  Future<List<WhiteboardSnapshot>> getWhiteboardSnapshots(
      String sessionId) async {
    return _whiteboardStore[sessionId] ?? const [];
  }

  @override
  Future<Recording> saveRecordingMetadata(Recording recording) async {
    final liveClass = _classStore.values.firstWhere(
      (c) => c.activeSession?.id == recording.sessionId,
      orElse: () => _classStore.values.first,
    );

    final updatedSession =
        liveClass.activeSession?.copyWith(recording: recording);
    _classStore[liveClass.id] = liveClass.copyWith(
      activeSession: updatedSession,
      recording: recording,
    );
    return recording;
  }

  @override
  Future<SessionReminder> createReminder(SessionReminder reminder) async {
    final list = _reminderStore.putIfAbsent(reminder.userId, () => []);
    list.add(reminder);
    return reminder;
  }

  @override
  Future<List<SessionReminder>> getRemindersForUser(String userId) async {
    return _reminderStore[userId] ?? const [];
  }

  @override
  Future<void> cacheClassesLocally(List<LiveClass> classes) async {
    for (final c in classes) {
      _classStore[c.id] = c;
    }
  }
}
