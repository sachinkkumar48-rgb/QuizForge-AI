abstract class SchemaMigration {
  final int fromVersion;
  final int toVersion;
  final String description;

  SchemaMigration({
    required this.fromVersion,
    required this.toVersion,
    required this.description,
  });

  /// Execute the migration step.
  /// Receives a mutable map of box names to their key-value JSON records.
  Future<void> up(Map<String, Map<String, String>> boxesData);

  /// Rollback the migration step if needed.
  Future<void> down(Map<String, Map<String, String>> boxesData);
}

class MigrationLog {
  final int fromVersion;
  final int toVersion;
  final DateTime executedAt;
  final bool isSuccess;
  final String description;
  final String? error;

  MigrationLog({
    required this.fromVersion,
    required this.toVersion,
    DateTime? executedAt,
    required this.isSuccess,
    required this.description,
    this.error,
  }) : executedAt = executedAt ?? DateTime.now();

  factory MigrationLog.fromJson(Map<String, dynamic> json) {
    return MigrationLog(
      fromVersion: json['fromVersion'] as int? ?? 1,
      toVersion: json['toVersion'] as int? ?? 1,
      executedAt: json['executedAt'] != null
          ? DateTime.tryParse(json['executedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      isSuccess: json['isSuccess'] as bool? ?? true,
      description: json['description'] as String? ?? '',
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fromVersion': fromVersion,
      'toVersion': toVersion,
      'executedAt': executedAt.toIso8601String(),
      'isSuccess': isSuccess,
      'description': description,
      if (error != null) 'error': error,
    };
  }
}
