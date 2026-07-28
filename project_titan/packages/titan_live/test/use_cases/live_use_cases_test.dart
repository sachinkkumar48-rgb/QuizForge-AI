import 'package:flutter_test/flutter_test.dart';
import 'package:titan_learning_content/titan_learning_content.dart';
import 'package:titan_live/titan_live.dart';
import 'package:titan_notes/titan_notes.dart';

void main() {
  group('Live Classes Use Cases & Integrator Tests', () {
    late LiveClassRepository repository;
    late ScheduleLiveClassUseCase scheduleUseCase;
    late JoinLiveClassUseCase joinUseCase;
    late LeaveLiveClassUseCase leaveUseCase;
    late StartRecordingUseCase startRecordingUseCase;
    late StopRecordingUseCase stopRecordingUseCase;
    late MarkAttendanceUseCase markAttendanceUseCase;
    late GetUpcomingClassesUseCase getUpcomingClassesUseCase;
    late ContinueRecordedClassUseCase continueRecordedClassUseCase;

    setUp(() {
      repository = LiveClassRepositoryImpl();
      scheduleUseCase = ScheduleLiveClassUseCase(repository);
      joinUseCase = JoinLiveClassUseCase(repository);
      leaveUseCase = LeaveLiveClassUseCase(repository);
      startRecordingUseCase = StartRecordingUseCase(repository);
      stopRecordingUseCase = StopRecordingUseCase(repository);
      markAttendanceUseCase = MarkAttendanceUseCase(repository);
      getUpcomingClassesUseCase = GetUpcomingClassesUseCase(repository);
      continueRecordedClassUseCase = ContinueRecordedClassUseCase(repository);
    });

    test('Schedule, Join, Leave use cases execute successfully', () async {
      final now = DateTime.now();
      final liveClass = LiveClass(
        id: 'lc_uc_01',
        title: 'International Relations: Quad & Indo-Pacific',
        description: 'Strategic analysis.',
        subjectCategory: 'IR',
        instructorId: 'inst_03',
        instructorName: 'Ambassador Roy',
        schedule: SessionSchedule(
          id: 'sch_uc_01',
          liveClassId: 'lc_uc_01',
          scheduledStartTime: now.add(const Duration(days: 2)),
          scheduledEndTime: now.add(const Duration(days: 2, hours: 2)),
        ),
        knowledgeNodeIds: const [],
        createdAt: now,
      );

      final scheduled = await scheduleUseCase.execute(liveClass);
      expect(scheduled.title, contains('Quad'));

      final participant = await joinUseCase.execute(
        'sess_01',
        Participant(
          id: 'p_uc_1',
          userId: 'u_student_9',
          name: 'Suresh',
          role: ParticipantRole.student,
          joinedAt: now,
        ),
      );
      expect(participant.name, equals('Suresh'));

      final left = await leaveUseCase.execute('sess_01', 'u_student_9');
      expect(left, isTrue);
    });

    test('Recording use cases manage session recordings', () async {
      final startRec = await startRecordingUseCase.execute('sess_01');
      expect(startRec.status, equals(RecordingStatus.recording));

      final stopRec = await stopRecordingUseCase.execute(
        sessionId: 'sess_01',
        recordingId: startRec.id,
        videoUrl: 'https://storage.titan.edu/rec_sess_01.mp4',
        durationSeconds: 3600,
        fileSizeBytes: 200000000,
      );

      expect(stopRec.status, equals(RecordingStatus.ready));
      expect(stopRec.durationSeconds, equals(3600));

      final recording =
          await continueRecordedClassUseCase.execute('lc_live_01');
      expect(recording, isNotNull);
    });

    test('GetUpcomingClassesUseCase and MarkAttendanceUseCase execute cleanly',
        () async {
      final upcoming = await getUpcomingClassesUseCase.execute();
      expect(upcoming.isNotEmpty, isTrue);

      final attendance = await markAttendanceUseCase.execute(
        Attendance(
          id: 'att_01',
          sessionId: 'sess_01',
          userId: 'u_student_1',
          userName: 'Rahul',
          joinedAt: DateTime.now(),
          watchDurationMinutes: 45,
        ),
      );

      expect(attendance.watchDurationMinutes, equals(45));
    });

    test(
        'LiveEngineIntegrator AI, Notes, Planner, and Search integrations work',
        () async {
      const integrator = LiveEngineIntegrator();
      final liveClass = (await repository.getLiveClassById('lc_live_01'))!;

      final explanation = await integrator.explainTeacherDiscussion(
        userId: 'u_1',
        discussionSnippet: 'Puttaswamy 9-judge bench ruling on Privacy',
      );
      expect(explanation, isNotNull);
      expect(explanation!.content, contains('AI Live Explanation'));

      final liveNote = integrator.createLiveNote(
        id: 'note_live_1',
        liveClass: liveClass,
        content: 'Key takeaway on Article 21',
        timestampSeconds: 300,
      );
      expect(liveNote.type, equals(NoteType.timestamp));

      final plannerTask = integrator.scheduleClassInPlanner(liveClass);
      expect(plannerTask.title, contains(liveClass.title));

      final content = integrator.convertRecordingToLearningContent(
        liveClass,
        liveClass.recording!,
      );
      expect(content.type, equals(ContentType.liveClass));
    });
  });
}
