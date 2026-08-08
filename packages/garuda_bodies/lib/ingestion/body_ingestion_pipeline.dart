library;

import '../domain/entities/body_knowledge_object.dart';
import '../repositories/body_repository.dart';
import '../services/body_editorial_service.dart';
import '../validators/body_validator.dart';

/// Result of a body ingestion run.
class BodyIngestionResult {
  final int totalProcessed;
  final int totalValidated;
  final List<BodyKnowledgeObject> objects;
  final List<BodyValidationReport> validationReports;

  const BodyIngestionResult({
    required this.totalProcessed,
    required this.totalValidated,
    required this.objects,
    required this.validationReports,
  });
}

/// Production ingestion pipeline for Body Knowledge Objects.
///
/// Official Source → Raw Payload → Normalize → Knowledge Object Mapping →
/// Validation → Relationship Resolution → Repository Registration → GARUDA
/// Editorial Queue → Publication.
///
/// Supports raw JSON payloads and CSV rows, and exposes an official-source
/// adapter point for future statutory-notification/portal ingestion without
/// redesign.
class BodyIngestionPipeline {
  final BodyRepository repository;
  final BodyEditorialService editorialService;

  BodyIngestionPipeline({
    required this.repository,
    BodyEditorialService? editorialService,
  }) : editorialService = editorialService ?? BodyEditorialService();

  /// Process raw Body JSON maps through the full ingestion pipeline.
  Future<BodyIngestionResult> ingestRawPayloads(
    List<Map<String, dynamic>> rawPayloads,
  ) async {
    final objects = <BodyKnowledgeObject>[];
    final reports = <BodyValidationReport>[];

    final existing = await repository.getAllBodies();

    for (final payload in rawPayloads) {
      final obj = BodyKnowledgeObject.fromJson(payload);

      final valReport = BodyValidator.validate(
        obj,
        existingBodies: [...existing, ...objects],
      );
      reports.add(valReport);

      // Editorial queue registration (shared GARUDA knowledge registry/index).
      editorialService.submitToEditorialWorkflow(obj);

      if (valReport.isValid) {
        objects.add(obj);
        await repository.saveBody(obj);
      }
    }

    return BodyIngestionResult(
      totalProcessed: rawPayloads.length,
      totalValidated: objects.length,
      objects: objects,
      validationReports: reports,
    );
  }

  /// Ingest Bodies from a simple CSV string (header + data rows).
  /// Expected headers: id, officialName, shortName, bodyType, category,
  /// constitutionalBasis, statutoryBasis, bodyStatus, yearEstablished,
  /// parentMinistry, headquarters, jurisdiction, mandate,
  /// establishingArticleIds (semicolon-separated), establishingActIds
  /// (semicolon-separated), powers (semicolon-separated), functions
  /// (semicolon-separated), composition, appointmentMechanism,
  /// appointmentAuthority, tenure, tenureType, removalMechanism,
  /// reportingAuthority, officialSource, evidenceIds (semicolon-separated),
  /// keywords (semicolon-separated), relatedArticleIds
  /// (semicolon-separated), relatedActIds (semicolon-separated),
  /// relatedBodyIds (semicolon-separated).
  Future<BodyIngestionResult> ingestCsv(String csv) async {
    final lines = csv
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return const BodyIngestionResult(
        totalProcessed: 0,
        totalValidated: 0,
        objects: [],
        validationReports: [],
      );
    }

    final headers = _splitCsvLine(lines.first);
    final payloads = <Map<String, dynamic>>[];

    for (final line in lines.skip(1)) {
      final cells = _splitCsvLine(line);
      final payload = <String, dynamic>{};
      for (var i = 0; i < headers.length && i < cells.length; i++) {
        payload[headers[i]] = cells[i];
      }
      // Semicolon-separated list columns
      for (final listCol in const [
        'evidenceIds',
        'establishingArticleIds',
        'establishingActIds',
        'powers',
        'functions',
        'eligibilityQualifications',
        'importantProvisions',
        'keywords',
        'relatedArticleIds',
        'relatedActIds',
        'relatedCaseLawIds',
        'relatedDoctrineIds',
        'relatedCommitteeIds',
        'relatedReportIds',
        'relatedSchemeIds',
        'relatedCurrentAffairsIds',
        'relatedPyqIds',
        'relatedBodyIds',
        'sdgGoals',
      ]) {
        final raw = payload[listCol];
        if (raw is String && raw.isNotEmpty) {
          payload[listCol] = raw
              .split(';')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      }
      if (payload.containsKey('yearEstablished')) {
        payload['yearEstablished'] =
            int.tryParse('${payload['yearEstablished']}') ?? 0;
      }
      payloads.add(payload);
    }

    return ingestRawPayloads(payloads);
  }

  /// Adapter point for future statutory-notification / official-portal
  /// ingestion. Accepts extracted metadata and returns the Body Knowledge
  /// Object.
  BodyKnowledgeObject fromOfficialSource({
    required String id,
    required String officialName,
    Map<String, dynamic>? extractedFields,
  }) {
    return BodyKnowledgeObject.fromJson({
      'id': id,
      'officialName': officialName,
      ...?extractedFields,
    });
  }

  List<String> _splitCsvLine(String line) {
    final cells = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        inQuotes = !inQuotes;
      } else if (ch == ',' && !inQuotes) {
        cells.add(buffer.toString().trim());
        buffer.clear();
      } else {
        buffer.write(ch);
      }
    }
    cells.add(buffer.toString().trim());
    return cells;
  }
}
