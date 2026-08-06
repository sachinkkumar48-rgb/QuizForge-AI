import 'package:meta/meta.dart';

/// Active Session context for a bulk ingestion operation.
@immutable
class KnowledgeImportSession {
  final String sessionId;
  final DateTime startTime;
  final String packageName;
  final Map<String, dynamic> metadata;

  const KnowledgeImportSession({
    required this.sessionId,
    required this.startTime,
    this.packageName = 'default_ingestion',
    this.metadata = const {},
  });

  factory KnowledgeImportSession.create({
    String? sessionId,
    String packageName = 'default_ingestion',
    Map<String, dynamic> metadata = const {},
  }) {
    final id = sessionId ?? 'SESSION-${DateTime.now().millisecondsSinceEpoch}';
    return KnowledgeImportSession(
      sessionId: id,
      startTime: DateTime.now(),
      packageName: packageName,
      metadata: metadata,
    );
  }
}
