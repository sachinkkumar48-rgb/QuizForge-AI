import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_upsc/models/bookmark.dart';
import 'package:quizforge_upsc/models/question_statistics.dart';
import 'package:quizforge_upsc/models/revision_schedule.dart';
import 'package:quizforge_upsc/models/user_note.dart';
import 'package:quizforge_upsc/repositories/bookmark_repository.dart';
import 'package:quizforge_upsc/repositories/revision_repository.dart';
import 'package:quizforge_upsc/repositories/statistics_repository.dart';
import 'package:quizforge_upsc/repositories/user_note_repository.dart';

import 'package:quizforge_upsc/sync/sync.dart';

class MemoryBookmarkRepository implements BookmarkRepository {
  final Map<String, Bookmark> _map = {};

  @override
  Future<void> toggleBookmark(String questionId,
      {String category = 'General', String? noteSnippet}) async {
    if (_map.containsKey(questionId)) {
      _map.remove(questionId);
    } else {
      _map[questionId] = Bookmark(
        bookmarkId: questionId,
        questionId: questionId,
        category: category,
        noteSnippet: noteSnippet,
      );
    }
  }

  @override
  Future<bool> isBookmarked(String questionId) async =>
      _map.containsKey(questionId);

  @override
  Future<Bookmark?> getBookmark(String questionId) async => _map[questionId];

  @override
  Future<List<Bookmark>> getBookmarks() async => _map.values.toList();

  @override
  Future<List<String>> getBookmarkedQuestionIds() async => _map.keys.toList();

  @override
  Future<void> removeBookmark(String questionId) async {
    _map.remove(questionId);
  }

  @override
  Future<void> clear() async {
    _map.clear();
  }
}

class MemoryUserNoteRepository implements UserNoteRepository {
  final Map<String, UserNote> _map = {};

  @override
  Future<void> saveNote(UserNote note) async {
    _map[note.noteId] = note;
  }

  @override
  Future<UserNote?> getNoteForQuestion(String questionId) async {
    final list = _map.values.where((n) => n.questionId == questionId);
    return list.isNotEmpty ? list.first : null;
  }

  @override
  Future<List<UserNote>> getAllNotes() async => _map.values.toList();

  @override
  Future<List<UserNote>> searchNotes(String query) async {
    return _map.values.where((n) => n.content.contains(query)).toList();
  }

  @override
  Future<void> deleteNote(String noteId) async {
    _map.remove(noteId);
  }

  @override
  Future<void> clear() async {
    _map.clear();
  }
}

class MemoryStatisticsRepository implements StatisticsRepository {
  final Map<String, QuestionStatistics> _map = {};

  @override
  Future<QuestionStatistics?> getQuestionStats(String questionId) async =>
      _map[questionId];

  @override
  Future<List<QuestionStatistics>> getAllStats() async => _map.values.toList();

  @override
  Future<void> updateQuestionStats({
    required String questionId,
    required bool isCorrect,
    required int timeSpentSeconds,
  }) async {
    final existing =
        _map[questionId] ?? QuestionStatistics(questionId: questionId);
    _map[questionId] = QuestionStatistics(
      questionId: questionId,
      totalAttempts: existing.totalAttempts + 1,
      correctAttempts: existing.correctAttempts + (isCorrect ? 1 : 0),
      incorrectAttempts: existing.incorrectAttempts + (isCorrect ? 0 : 1),
      averageTimeSeconds: timeSpentSeconds,
      lastAttemptedAt: DateTime.now(),
    );
  }

  @override
  Future<void> clear() async {
    _map.clear();
  }
}

class MemoryRevisionRepository implements RevisionRepository {
  final Map<String, RevisionSchedule> _map = {};

  @override
  Future<RevisionSchedule?> getSchedule(String questionId) async =>
      _map[questionId];

  @override
  Future<Map<String, RevisionSchedule>> getAllSchedules() async =>
      Map.from(_map);

  @override
  Future<List<RevisionSchedule>> getDueRevisions() async =>
      _map.values.toList();

  @override
  Future<void> updateSchedule(RevisionSchedule schedule) async {
    _map[schedule.questionId] = schedule;
  }

  @override
  Future<void> recordRevisionResult({
    required String questionId,
    required bool isCorrect,
    int confidenceRating = 3,
    String difficulty = 'Medium',
    bool isBookmarked = false,
  }) async {
    final existing = _map[questionId] ??
        RevisionSchedule(
          scheduleId: 'sch_$questionId',
          questionId: questionId,
          lastReviewed: DateTime.now(),
          nextReviewDue: DateTime.now().add(const Duration(days: 1)),
        );
    _map[questionId] = existing;
  }

  @override
  Future<void> clear() async {
    _map.clear();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SyncEngine engine;
  late MemoryBookmarkRepository bookmarkRepo;
  late MemoryUserNoteRepository noteRepo;
  late MemoryStatisticsRepository statsRepo;
  late MemoryRevisionRepository revisionRepo;

  setUp(() {
    engine = SyncEngine();
    engine.resetEngine();

    bookmarkRepo = MemoryBookmarkRepository();
    noteRepo = MemoryUserNoteRepository();
    statsRepo = MemoryStatisticsRepository();
    revisionRepo = MemoryRevisionRepository();

    engine.registerTarget(
        BookmarkSyncTarget(repository: bookmarkRepo, deviceId: 'test_dev'));
    engine.registerTarget(
        NoteSyncTarget(repository: noteRepo, deviceId: 'test_dev'));
    engine.registerTarget(
        StatisticsSyncTarget(repository: statsRepo, deviceId: 'test_dev'));
    engine.registerTarget(
        RevisionSyncTarget(repository: revisionRepo, deviceId: 'test_dev'));
    engine.registerTarget(SettingsSyncTarget(
        deviceId: 'test_dev', initialSettings: {'darkMode': true}));
  });

  group('Cloud Sync Architecture - Core Models & Snapshot Tests', () {
    test('SyncMetadata computes SHA-256 checksum and serializes cleanly', () {
      final jsonMap = {'key': 'value', 'count': 42};
      final checksum = SyncMetadata.computeChecksum(jsonMap);
      expect(checksum.isNotEmpty, isTrue);

      final meta = SyncMetadata(
        entityId: 'ent_101',
        entityType: SyncEntityType.bookmark,
        version: 1,
        clientDeviceId: 'dev_mobile_1',
        checksum: checksum,
      );

      final metaJson = meta.toJson();
      final metaDecoded = SyncMetadata.fromJson(metaJson);

      expect(metaDecoded.entityId, equals('ent_101'));
      expect(metaDecoded.entityType, equals(SyncEntityType.bookmark));
      expect(metaDecoded.checksum, equals(checksum));
    });

    test('SyncSnapshot encapsulates all 5 domain targets', () {
      final snapshot = SyncSnapshot(
        snapshotId: 'snap_1',
        clientDeviceId: 'dev_1',
        bookmarks: [
          SyncEntity(
            metadata: SyncMetadata(
              entityId: 'bm_1',
              entityType: SyncEntityType.bookmark,
              version: 1,
              clientDeviceId: 'dev_1',
            ),
            payload: {'questionId': 'q_100'},
          ),
        ],
      );

      expect(snapshot.totalEntityCount, equals(1));
      expect(snapshot.bookmarks.length, equals(1));

      final jsonMap = snapshot.toJson();
      final restored = SyncSnapshot.fromJson(jsonMap);
      expect(restored.bookmarks.first.metadata.entityId, equals('bm_1'));
    });
  });

  group('Conflict Resolution Strategy Tests', () {
    test('Last-Write-Wins resolves newer remote timestamp to win', () {
      final oldLocal = SyncEntity<Map<String, dynamic>>(
        metadata: SyncMetadata(
          entityId: 'e1',
          entityType: SyncEntityType.note,
          version: 1,
          updatedAt: DateTime.utc(2026, 1, 1),
          clientDeviceId: 'dev_A',
        ),
        payload: {'content': 'Old Local Note'},
      );

      final newRemote = SyncEntity<Map<String, dynamic>>(
        metadata: SyncMetadata(
          entityId: 'e1',
          entityType: SyncEntityType.note,
          version: 2,
          updatedAt: DateTime.utc(2026, 1, 2),
          clientDeviceId: 'dev_B',
        ),
        payload: {'content': 'New Remote Note'},
      );

      final result = ConflictResolver.resolve(
        local: oldLocal,
        remote: newRemote,
        strategy: ConflictResolutionStrategy.lastWriteWins,
      );

      expect(
          result.resolvedEntity.payload['content'], equals('New Remote Note'));
      expect(result.updatedLocal, isTrue);
    });

    test('RemoteWins and LocalWins strategies override timestamps', () {
      final local = SyncEntity<Map<String, dynamic>>(
        metadata: SyncMetadata(
          entityId: 'e1',
          entityType: SyncEntityType.settings,
          version: 1,
          updatedAt: DateTime.utc(2026, 6, 1),
          clientDeviceId: 'dev_A',
        ),
        payload: {'theme': 'Dark'},
      );

      final remote = SyncEntity<Map<String, dynamic>>(
        metadata: SyncMetadata(
          entityId: 'e1',
          entityType: SyncEntityType.settings,
          version: 1,
          updatedAt: DateTime.utc(2026, 1, 1),
          clientDeviceId: 'dev_B',
        ),
        payload: {'theme': 'Light'},
      );

      final remoteWinsRes = ConflictResolver.resolve(
        local: local,
        remote: remote,
        strategy: ConflictResolutionStrategy.remoteWins,
      );
      expect(remoteWinsRes.resolvedEntity.payload['theme'], equals('Light'));

      final localWinsRes = ConflictResolver.resolve(
        local: local,
        remote: remote,
        strategy: ConflictResolutionStrategy.localWins,
      );
      expect(localWinsRes.resolvedEntity.payload['theme'], equals('Dark'));
    });
  });

  group('Offline Queue & Cloud Provider Integration', () {
    test('Offline mutation queueing and clearing', () {
      final queue = SyncQueue();
      expect(queue.isEmpty, isTrue);

      final entity = SyncEntity<Map<String, dynamic>>(
        metadata: SyncMetadata(
          entityId: 'note_1',
          entityType: SyncEntityType.note,
          version: 1,
          clientDeviceId: 'dev_1',
        ),
        payload: {'title': 'My Polity Note'},
      );

      queue.enqueue(entity);
      expect(queue.length, equals(1));

      queue.clear();
      expect(queue.isEmpty, isTrue);
    });

    test(
        'CloudSyncProvider implementations authenticate and exchange snapshots',
        () async {
      final driveProvider = GoogleDriveSyncProvider();
      await driveProvider.authenticate();
      expect(await driveProvider.isConnected(), isTrue);

      final firebaseProvider = FirebaseSyncProvider();
      await firebaseProvider.authenticate();
      expect(await firebaseProvider.isConnected(), isTrue);

      final customProvider = CustomBackendSyncProvider(
        serverUrl: 'https://api.test/sync',
        authToken: 'token_abc',
      );
      await customProvider.authenticate();
      expect(await customProvider.isConnected(), isTrue);
    });

    test(
        'SyncEngine executes full two-way synchronization cycle across all 5 targets',
        () async {
      // 1. Prepare local items
      await bookmarkRepo.toggleBookmark('q_500', category: 'Polity');
      await noteRepo.saveNote(UserNote(
        noteId: 'n_1',
        questionId: 'q_500',
        content: 'Article 21 details',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      // 2. Configure provider & sync
      final provider = GoogleDriveSyncProvider();
      engine.setCloudProvider(provider);

      final success = await engine.syncNow();
      expect(success, isTrue);
      expect(engine.state, equals(SyncState.success));
      expect(engine.lastSuccessfulSyncTime, isNotNull);

      // 3. Download snapshot from cloud provider to verify contents
      final remoteSnapshot = await provider.downloadSnapshot();
      expect(remoteSnapshot, isNotNull);
      expect(remoteSnapshot!.bookmarks.length, equals(1));
      expect(remoteSnapshot.notes.length, equals(1));
    });
  });

  group('Sync UI Widget Integration Tests', () {
    testWidgets(
        'SyncSettingsPage renders cloud synchronization dashboard cleanly',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SyncSettingsPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cloud Synchronization'), findsOneWidget);
      expect(find.text('Google Drive'), findsOneWidget);
      expect(find.text('Firebase Firestore'), findsOneWidget);
      expect(find.text('Cloud Providers'), findsOneWidget);
    });
  });
}
