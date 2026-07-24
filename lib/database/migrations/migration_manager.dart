import 'dart:convert';
import 'package:hive/hive.dart';
import 'migration.dart';
import 'migration_1_to_2.dart';
import 'migration_2_to_3.dart';

class DowngradeNotSupportedException implements Exception {
  final String message;
  DowngradeNotSupportedException(this.message);

  @override
  String toString() => 'DowngradeNotSupportedException: $message';
}

class MigrationFailedException implements Exception {
  final String message;
  final Object? originalError;
  MigrationFailedException(this.message, [this.originalError]);

  @override
  String toString() => 'MigrationFailedException: $message';
}

class MigrationManager {
  static const String metaBoxName = 'engine_schema_meta';
  static const String schemaVersionKey = 'schema_version';
  static const String datasetVersionKey = 'dataset_version';
  static const String appVersionKey = 'app_version';
  static const String historyKey = 'migration_history';

  static const int currentEngineSchemaVersion = 3;
  static const String currentAppVersion = '1.6.0';
  static const String currentDatasetVersion = '1.0.0';

  final List<SchemaMigration> _migrations;

  MigrationManager({List<SchemaMigration>? customMigrations})
      : _migrations = customMigrations ?? [Migration1To2(), Migration2To3()];

  List<SchemaMigration> get registeredMigrations =>
      List.unmodifiable(_migrations);

  Future<Box<String>> _getMetaBox() async {
    return await Hive.openBox<String>(metaBoxName);
  }

  /// Get stored current schema version (defaults to 1 for uninitialized/fresh DB).
  Future<int> getCurrentSchemaVersion() async {
    final metaBox = await _getMetaBox();
    final val = metaBox.get(schemaVersionKey);
    if (val == null) return 1;
    return int.tryParse(val) ?? 1;
  }

  /// Get stored dataset version.
  Future<String> getStoredDatasetVersion() async {
    final metaBox = await _getMetaBox();
    return metaBox.get(datasetVersionKey) ?? currentDatasetVersion;
  }

  /// Get stored app version.
  Future<String> getStoredAppVersion() async {
    final metaBox = await _getMetaBox();
    return metaBox.get(appVersionKey) ?? currentAppVersion;
  }

  /// Retrieve full migration logs history.
  Future<List<MigrationLog>> getMigrationHistory() async {
    final metaBox = await _getMetaBox();
    final jsonStr = metaBox.get(historyKey);
    if (jsonStr == null) return [];
    try {
      final List rawList = jsonDecode(jsonStr) as List;
      return rawList
          .map((item) =>
              MigrationLog.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Create an in-memory backup snapshot of all active engine Hive boxes.
  Future<Map<String, Map<String, String>>> createBackupSnapshot() async {
    final boxNames = [
      'engine_exams',
      'engine_papers',
      'engine_questions',
      'engine_explanations',
      'engine_attempts',
      'engine_bookmarks',
      'engine_user_notes',
      'engine_statistics',
      'engine_revisions',
      'engine_dataset_manifests',
    ];

    final Map<String, Map<String, String>> snapshot = {};

    for (final bName in boxNames) {
      final box = await Hive.openBox<String>(bName);
      final Map<String, String> boxMap = {};
      for (final key in box.keys) {
        final val = box.get(key);
        if (val != null) {
          boxMap[key.toString()] = val;
        }
      }
      snapshot[bName] = boxMap;
    }

    return snapshot;
  }

  /// Restore backup snapshot into Hive boxes in case of migration failure.
  Future<void> restoreBackupSnapshot(
      Map<String, Map<String, String>> snapshot) async {
    for (final entry in snapshot.entries) {
      final bName = entry.key;
      final boxMap = entry.value;
      final box = await Hive.openBox<String>(bName);
      await box.clear();
      await box.putAll(boxMap);
    }
  }

  /// Execute sequential schema migrations from current stored version to target version.
  /// Features:
  /// - Automatic pre-migration backup & snapshot
  /// - Downgrade protection exception
  /// - Automatic rollback on migration failure
  /// - Migration history logging
  Future<bool> runMigrations(
      {int targetVersion = currentEngineSchemaVersion}) async {
    final currentVersion = await getCurrentSchemaVersion();

    if (currentVersion == targetVersion) {
      // Schema is up-to-date
      return false;
    }

    if (currentVersion > targetVersion) {
      throw DowngradeNotSupportedException(
        'Cannot downgrade database schema from version $currentVersion to $targetVersion',
      );
    }

    // Filter relevant migration steps
    final steps = _migrations
        .where((m) =>
            m.fromVersion >= currentVersion && m.toVersion <= targetVersion)
        .toList();

    steps.sort((a, b) => a.fromVersion.compareTo(b.fromVersion));

    if (steps.isEmpty) {
      // Update meta version directly if no explicit steps registered
      final metaBox = await _getMetaBox();
      await metaBox.put(schemaVersionKey, targetVersion.toString());
      await metaBox.put(appVersionKey, currentAppVersion);
      await metaBox.put(datasetVersionKey, currentDatasetVersion);
      return true;
    }

    // Step 1: Take Backup Snapshot
    final backupSnapshot = await createBackupSnapshot();

    // Copy snapshot for in-memory migration mutations
    final workingData = Map<String, Map<String, String>>.from(
      backupSnapshot.map(
        (key, value) => MapEntry(key, Map<String, String>.from(value)),
      ),
    );

    int activeVersion = currentVersion;

    for (final step in steps) {
      if (step.fromVersion != activeVersion) {
        throw MigrationFailedException(
          'Broken migration chain: expected step from version $activeVersion, but found ${step.fromVersion}',
        );
      }

      try {
        // Execute forward migration step
        await step.up(workingData);

        // Apply migrated data to Hive storage
        for (final entry in workingData.entries) {
          final bName = entry.key;
          final boxMap = entry.value;
          final box = await Hive.openBox<String>(bName);
          await box.clear();
          await box.putAll(boxMap);
        }

        activeVersion = step.toVersion;

        // Log successful step
        await _logMigrationStep(
          MigrationLog(
            fromVersion: step.fromVersion,
            toVersion: step.toVersion,
            isSuccess: true,
            description: step.description,
          ),
        );
      } catch (error) {
        // Automatic Rollback on failure
        await restoreBackupSnapshot(backupSnapshot);

        await _logMigrationStep(
          MigrationLog(
            fromVersion: step.fromVersion,
            toVersion: step.toVersion,
            isSuccess: false,
            description: step.description,
            error: error.toString(),
          ),
        );

        throw MigrationFailedException(
          'Migration step ${step.fromVersion} -> ${step.toVersion} failed. Rollback executed successfully.',
          error,
        );
      }
    }

    // Save final updated schema version meta
    final metaBox = await _getMetaBox();
    await metaBox.put(schemaVersionKey, activeVersion.toString());
    await metaBox.put(appVersionKey, currentAppVersion);
    await metaBox.put(datasetVersionKey, currentDatasetVersion);

    return true;
  }

  Future<void> _logMigrationStep(MigrationLog log) async {
    final metaBox = await _getMetaBox();
    final logs = await getMigrationHistory();
    logs.add(log);
    final jsonList = logs.map((l) => l.toJson()).toList();
    await metaBox.put(historyKey, jsonEncode(jsonList));
  }
}
