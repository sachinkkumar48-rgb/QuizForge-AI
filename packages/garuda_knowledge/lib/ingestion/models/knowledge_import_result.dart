import 'package:meta/meta.dart';
import '../../domain/entities/knowledge_object.dart';
import '../../domain/entities/knowledge_relationship.dart';

/// Result status for an individual document import operation.
enum ImportStatus {
  success,
  updated,
  duplicate,
  skipped,
  failed,
}

/// Immutable result object for a single ingested KnowledgeDocument.
@immutable
class KnowledgeImportResult {
  final String documentId;
  final ImportStatus status;
  final String? message;
  final KnowledgeObject? createdObject;
  final List<KnowledgeRelationship> generatedRelationships;
  final List<String> warnings;
  final double durationMs;

  const KnowledgeImportResult({
    required this.documentId,
    required this.status,
    this.message,
    this.createdObject,
    this.generatedRelationships = const [],
    this.warnings = const [],
    this.durationMs = 0.0,
  });

  factory KnowledgeImportResult.success({
    required String documentId,
    required KnowledgeObject object,
    List<KnowledgeRelationship> relationships = const [],
    List<String> warnings = const [],
    double durationMs = 0.0,
  }) {
    return KnowledgeImportResult(
      documentId: documentId,
      status: ImportStatus.success,
      createdObject: object,
      generatedRelationships: relationships,
      warnings: warnings,
      durationMs: durationMs,
    );
  }

  factory KnowledgeImportResult.updated({
    required String documentId,
    required KnowledgeObject object,
    List<KnowledgeRelationship> relationships = const [],
    List<String> warnings = const [],
    double durationMs = 0.0,
  }) {
    return KnowledgeImportResult(
      documentId: documentId,
      status: ImportStatus.updated,
      createdObject: object,
      generatedRelationships: relationships,
      warnings: warnings,
      durationMs: durationMs,
    );
  }

  factory KnowledgeImportResult.duplicate({
    required String documentId,
    String? message,
    double durationMs = 0.0,
  }) {
    return KnowledgeImportResult(
      documentId: documentId,
      status: ImportStatus.duplicate,
      message: message ?? 'Document already ingested (duplicate checksum/id)',
      durationMs: durationMs,
    );
  }

  factory KnowledgeImportResult.failure({
    required String documentId,
    required String message,
    List<String> warnings = const [],
    double durationMs = 0.0,
  }) {
    return KnowledgeImportResult(
      documentId: documentId,
      status: ImportStatus.failed,
      message: message,
      warnings: warnings,
      durationMs: durationMs,
    );
  }

  bool get isSuccess => status == ImportStatus.success || status == ImportStatus.updated;
}
