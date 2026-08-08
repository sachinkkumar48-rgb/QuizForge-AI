library;

import '../domain/entities/international_knowledge_object.dart';
import '../repositories/international_repository.dart';
import '../services/international_editorial_service.dart';
import '../validators/international_validator.dart';

/// Result of an international-organisation ingestion run.
class InternationalIngestionResult {
  final int totalProcessed;
  final int totalValidated;
  final List<InternationalKnowledgeObject> objects;
  final List<InternationalValidationReport> validationReports;

  const InternationalIngestionResult({
    required this.totalProcessed,
    required this.totalValidated,
    required this.objects,
    required this.validationReports,
  });
}

/// Production ingestion pipeline for International Knowledge Objects.
///
/// Official Source → Load → Parse → Normalize → Knowledge Object Mapping →
/// Validation → Relationship Resolution → Repository Registration → GARUDA
/// Editorial Queue → Publication.
///
/// Supports raw JSON payloads, CSV rows (resumable batch ingestion), and an
/// official-source adapter point for future treaty/institutional-portal
/// ingestion without redesign.
class InternationalIngestionPipeline {
  final InternationalRepository repository;
  final InternationalEditorialService editorialService;

  InternationalIngestionPipeline({
    required this.repository,
    InternationalEditorialService? editorialService,
  }) : editorialService = editorialService ?? InternationalEditorialService();

  /// Process raw International JSON maps through the full ingestion pipeline.
  Future<InternationalIngestionResult> ingestRawPayloads(
    List<Map<String, dynamic>> rawPayloads,
  ) async {
    final objects = <InternationalKnowledgeObject>[];
    final reports = <InternationalValidationReport>[];

    final existing = await repository.getAllOrganisations();

    for (final payload in rawPayloads) {
      final obj = InternationalKnowledgeObject.fromJson(payload);

      final valReport = InternationalValidator.validate(
        obj,
        existingOrganisations: [...existing, ...objects],
      );
      reports.add(valReport);

      // Editorial queue registration (shared GARUDA knowledge registry/index).
      editorialService.submitToEditorialWorkflow(obj);

      if (valReport.isValid) {
        objects.add(obj);
        await repository.saveOrganisation(obj);
      }
    }

    return InternationalIngestionResult(
      totalProcessed: rawPayloads.length,
      totalValidated: objects.length,
      objects: objects,
      validationReports: reports,
    );
  }

  /// Ingest Organisations from a simple CSV string (header + data rows).
  /// Expected headers: id, officialName, shortName, acronym, bodyType,
  /// category, establishedYear, headquarters, foundingTreaty, mandate,
  /// officialSource, evidenceIds (semicolon-separated), keywords
  /// (semicolon-separated), objectives (semicolon-separated), functions
  /// (semicolon-separated), issueAreas (semicolon-separated),
  /// importantConventions (semicolon-separated), relatedOrganisationIds
  /// (semicolon-separated), relatedArticleIds (semicolon-separated),
  /// relatedActIds (semicolon-separated).
  Future<InternationalIngestionResult> ingestCsv(String csv) async {
    final lines = csv
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return const InternationalIngestionResult(
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
        'keywords',
        'objectives',
        'functions',
        'powers',
        'importantProgrammes',
        'importantConventions',
        'issueAreas',
        'prelimsTraps',
        'mainsThemes',
        'essayThemes',
        'interviewAreas',
        'indiaHostedEvents',
        'indiaInitiatives',
        'relatedArticleIds',
        'relatedActIds',
        'relatedCaseLawIds',
        'relatedDoctrineIds',
        'relatedCommitteeIds',
        'relatedReportIds',
        'relatedSchemeIds',
        'relatedCurrentAffairsIds',
        'relatedPyqIds',
        'relatedOrganisationIds',
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
      if (payload.containsKey('establishedYear')) {
        payload['establishedYear'] =
            int.tryParse('${payload['establishedYear']}') ?? 0;
      }
      payloads.add(payload);
    }

    return ingestRawPayloads(payloads);
  }

  /// Adapter point for future treaty/institutional-portal ingestion. Accepts
  /// extracted metadata and returns the International Knowledge Object.
  InternationalKnowledgeObject fromOfficialSource({
    required String id,
    required String officialName,
    required String acronym,
    Map<String, dynamic>? extractedFields,
  }) {
    return InternationalKnowledgeObject.fromJson({
      'id': id,
      'officialName': officialName,
      'acronym': acronym,
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
