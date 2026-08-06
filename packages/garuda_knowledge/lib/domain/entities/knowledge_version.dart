import 'package:meta/meta.dart';

/// Immutable entity representing the version history snapshot of a knowledge object.
@immutable
class KnowledgeVersion {
  final int versionNumber;
  final String commitMessage;
  final String author;
  final DateTime timestamp;

  const KnowledgeVersion({
    required this.versionNumber,
    required this.commitMessage,
    required this.author,
    required this.timestamp,
  });

  String get versionString => 'v$versionNumber';

  Map<String, dynamic> toJson() => {
        'versionNumber': versionNumber,
        'commitMessage': commitMessage,
        'author': author,
        'timestamp': timestamp.toIso8601String(),
      };

  factory KnowledgeVersion.fromJson(Map<String, dynamic> json) {
    return KnowledgeVersion(
      versionNumber: json['versionNumber'] as int? ?? 1,
      commitMessage: json['commitMessage'] as String? ?? 'Initial version',
      author: json['author'] as String? ?? 'System',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KnowledgeVersion &&
          runtimeType == other.runtimeType &&
          versionNumber == other.versionNumber &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(versionNumber, timestamp);
}
