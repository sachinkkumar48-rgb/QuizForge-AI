library;

import '../domain/entities/scheme_knowledge_object.dart';
import '../repositories/scheme_repository.dart';
import '../services/scheme_editorial_service.dart';
import '../validators/scheme_validator.dart';

/// Result of a scheme ingestion run.
class SchemeIngestionResult {
  final int totalProcessed;
  final int totalValidated;
  final List<SchemeKnowledgeObject> objects;
  final List<SchemeValidationReport> validationReports;

  const SchemeIngestionResult({
    required this.totalProcessed,
    required this.totalValidated,
    required this.objects,
    required this.validationReports,
  });
}

/// Production ingestion pipeline for Government Scheme Knowledge Objects.
///
/// Official Source → Raw Payload → Knowledge Object Mapping → Validation →
/// Relationship Resolution (cross-package reference check) → Repository
/// Registration → GARUDA Editorial Queue → Publication.
///
/// Supports raw JSON payloads and CSV rows, and exposes an adapter point for
/// future official-notification/portal ingestion without redesign.
class SchemeIngestionPipeline {
  final SchemeRepository repository;
  final SchemeEditorialService editorialService;

  SchemeIngestionPipeline({
    required this.repository,
    SchemeEditorialService? editorialService,
  }) : editorialService = editorialService ?? SchemeEditorialService();

  /// Process raw Scheme JSON maps through the full ingestion pipeline.
  Future<SchemeIngestionResult> ingestRawPayloads(
    List<Map<String, dynamic>> rawPayloads,
  ) async {
    final objects = <SchemeKnowledgeObject>[];
    final reports = <SchemeValidationReport>[];

    final existing = await repository.getAllSchemes();

    for (final payload in rawPayloads) {
      final obj = SchemeKnowledgeObject.fromJson(payload);

      final valReport = SchemeValidator.validate(
        obj,
        existingSchemes: [...existing, ...objects],
      );
      reports.add(valReport);

      // Editorial queue registration (shared GARUDA knowledge registry/index).
      editorialService.submitToEditorialWorkflow(obj);

      if (valReport.isValid) {
        objects.add(obj);
        await repository.saveScheme(obj);
      }
    }

    return SchemeIngestionResult(
      totalProcessed: rawPayloads.length,
      totalValidated: objects.length,
      objects: objects,
      validationReports: reports,
    );
  }

  /// Ingest Schemes from a simple CSV string (header + data rows).
  /// Expected headers: id, officialName, shortName, ministry, category, sector,
  /// schemeType, status, launchDate, fundingPattern, centralShare, stateShare,
  /// financialAssistance, budgetOutlay, department, implementingAgency,
  /// coverage, geographicScope (semicolon-separated), ruralUrbanScope,
  /// beneficiaries (semicolon-separated), targetBeneficiaries
  /// (semicolon-separated), eligibility (semicolon-separated),
  /// objectives (semicolon-separated), keyFeatures (semicolon-separated),
  /// keywords (semicolon-separated), relatedSchemeIds (semicolon-separated),
  /// relatedArticleIds (semicolon-separated), relatedActIds
  /// (semicolon-separated), sdgGoals (semicolon-separated).
  Future<SchemeIngestionResult> ingestCsv(String csv) async {
    final lines = csv
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return const SchemeIngestionResult(
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
        'geographicScope',
        'beneficiaries',
        'targetBeneficiaries',
        'eligibility',
        'objectives',
        'keyFeatures',
        'keywords',
        'relatedSchemeIds',
        'relatedArticleIds',
        'relatedActIds',
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
      payloads.add(payload);
    }

    return ingestRawPayloads(payloads);
  }

  /// Adapter point for future official-notification / portal ingestion.
  /// Accepts extracted metadata and returns the Scheme Knowledge Object.
  SchemeKnowledgeObject fromOfficialSource({
    required String id,
    required String officialName,
    Map<String, dynamic>? extractedFields,
  }) {
    return SchemeKnowledgeObject.fromJson({
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
