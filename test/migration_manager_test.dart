import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:quizforge_upsc/database/migrations/migration.dart';
import 'package:quizforge_upsc/database/migrations/migration_manager.dart';

class FailingTestMigration extends SchemaMigration {
  FailingTestMigration()
      : super(
          fromVersion: 1,
          toVersion: 2,
          description:
              'Intentional failing migration step for rollback testing',
        );

  @override
  Future<void> up(Map<String, Map<String, String>> boxesData) async {
    // Mutate data first
    boxesData['engine_bookmarks']?['test_bm'] =
        jsonEncode({'category': 'Corrupted'});
    // Then throw error to trigger rollback
    throw Exception('Intentional migration failure for rollback verification');
  }

  @override
  Future<void> down(Map<String, Map<String, String>> boxesData) async {}
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir =
        await Directory.systemTemp.createTemp('quizforge_migration_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('MigrationManager Version Detection & Sequential Upgrade Tests', () {
    test('Detects default initial schema version 1 and upgrades to version 3',
        () async {
      final manager = MigrationManager();

      final initialVersion = await manager.getCurrentSchemaVersion();
      expect(initialVersion, equals(1));

      // Seed pre-migration data
      final expBox = await Hive.openBox<String>('engine_explanations');
      await expBox.put(
          'exp_1',
          jsonEncode({
            'explanationId': 'exp_1',
            'questionId': 'q_1',
            'explanationType': 'Official',
            'content': 'Official text',
            'source': 'Key',
          }));

      final bmBox = await Hive.openBox<String>('engine_bookmarks');
      await bmBox.put(
          'q_1',
          jsonEncode({
            'bookmarkId': 'q_1',
            'questionId': 'q_1',
            'category': '',
          }));

      final statsBox = await Hive.openBox<String>('engine_statistics');
      await statsBox.put(
          'q_1',
          jsonEncode({
            'questionId': 'q_1',
            'totalAttempts': 2,
            'correctAttempts': 1,
          }));

      // Execute migration to version 3
      final didMigrate = await manager.runMigrations(targetVersion: 3);
      expect(didMigrate, isTrue);

      final newVersion = await manager.getCurrentSchemaVersion();
      expect(newVersion, equals(3));

      // Verify v1 -> v2 migration data transformation (explanations author added)
      final expVal = expBox.get('exp_1');
      expect(expVal, isNotNull);
      final expMap = jsonDecode(expVal!) as Map<String, dynamic>;
      expect(expMap['author'], equals('Official UPSC'));
      expect(expMap['version'], equals('1.0.0'));

      // Verify v2 -> v3 migration data transformation (bookmarks category & stats accuracy)
      final bmVal = bmBox.get('q_1');
      expect(bmVal, isNotNull);
      final bmMap = jsonDecode(bmVal!) as Map<String, dynamic>;
      expect(bmMap['category'], equals('General'));

      final statsVal = statsBox.get('q_1');
      expect(statsVal, isNotNull);
      final statsMap = jsonDecode(statsVal!) as Map<String, dynamic>;
      expect(statsMap['accuracyPercentage'], equals(50.0));

      // Verify MigrationLog history
      final history = await manager.getMigrationHistory();
      expect(history.length, equals(2));
      expect(history.every((l) => l.isSuccess), isTrue);
    });

    test('Returns false when schema is already up to date', () async {
      final manager = MigrationManager();
      await manager.runMigrations(targetVersion: 3);

      final didMigrateAgain = await manager.runMigrations(targetVersion: 3);
      expect(didMigrateAgain, isFalse);
    });
  });

  group('Downgrade Protection Tests', () {
    test(
        'Throws DowngradeNotSupportedException if target version < current version',
        () async {
      final manager = MigrationManager();
      await manager.runMigrations(targetVersion: 3);

      await expectLater(
        () => manager.runMigrations(targetVersion: 1),
        throwsA(isA<DowngradeNotSupportedException>().having(
          (e) => e.message,
          'message',
          contains('Cannot downgrade database schema'),
        )),
      );
    });
  });

  group('Rollback & Failure Recovery Tests', () {
    test('Automatically restores backup snapshot when migration step fails',
        () async {
      final manager = MigrationManager(
        customMigrations: [FailingTestMigration()],
      );

      // Seed original bookmark before migration
      final bmBox = await Hive.openBox<String>('engine_bookmarks');
      await bmBox.put(
          'test_bm',
          jsonEncode({
            'bookmarkId': 'test_bm',
            'category': 'Original Category',
          }));

      // Run migration expecting failure
      await expectLater(
        () => manager.runMigrations(targetVersion: 2),
        throwsA(isA<MigrationFailedException>().having(
          (e) => e.message,
          'message',
          contains(
              'Migration step 1 -> 2 failed. Rollback executed successfully.'),
        )),
      );

      // Verify original data was restored by rollback
      final bmVal = bmBox.get('test_bm');
      expect(bmVal, isNotNull);
      final bmMap = jsonDecode(bmVal!) as Map<String, dynamic>;
      expect(bmMap['category'], equals('Original Category')); // Uncorrupted!

      // Verify failed step is logged in history
      final history = await manager.getMigrationHistory();
      expect(history.length, equals(1));
      expect(history.first.isSuccess, isFalse);
      expect(history.first.error, contains('Intentional migration failure'));
    });
  });
}
