library;

import '../domain/entities/index_knowledge_object.dart';
import '../domain/entities/indicator_knowledge_object.dart';
import '../domain/entities/report_knowledge_object.dart';
import '../domain/entities/survey_knowledge_object.dart';
import '../repositories/report_repository.dart';
import '../services/report_editorial_service.dart';
import '../validators/report_validator.dart';

class ReportIngestionResult {
  final int totalProcessed;
  final int totalValidated;
  final List<ReportKnowledgeObject> objects;
  final List<ReportValidationReport> validationReports;

  const ReportIngestionResult({
    required this.totalProcessed,
    required this.totalValidated,
    required this.objects,
    required this.validationReports,
  });
}

/// Detailed import statistics with deduplication, versioning and failure
/// reporting for a report ingestion batch.
class ReportImportSummary {
  final int totalProcessed;
  final int imported;
  final int updated;
  final int duplicate;
  final int failed;
  final List<ReportKnowledgeObject> importedObjects;
  final List<ReportValidationReport> validationReports;
  final List<String> failureMessages;

  const ReportImportSummary({
    required this.totalProcessed,
    required this.imported,
    required this.updated,
    required this.duplicate,
    required this.failed,
    required this.importedObjects,
    required this.validationReports,
    required this.failureMessages,
  });
}

/// Ingestion pipeline for Reports, Indices and Surveys.
/// Supports raw JSON payloads, CSV rows, government publication metadata and
/// future official-PDF/OCR extraction (adapter point reserved).
class ReportIngestionPipeline {
  final ReportRepository repository;
  final ReportEditorialService editorialService;

  ReportIngestionPipeline({
    required this.repository,
    ReportEditorialService? editorialService,
  }) : editorialService = editorialService ?? ReportEditorialService();

  /// Process raw Report JSON maps through the full ingestion pipeline.
  Future<ReportIngestionResult> ingestRawPayloads(
    List<Map<String, dynamic>> rawPayloads,
  ) async {
    final summary = await importBatch(rawPayloads);
    return ReportIngestionResult(
      totalProcessed: summary.totalProcessed,
      totalValidated: summary.imported + summary.updated,
      objects: summary.importedObjects,
      validationReports: summary.validationReports,
    );
  }

  /// Enhanced ingestion with deduplication, version detection, import
  /// statistics, failure reporting and resumable batch processing.
  ///
  /// Each payload is processed independently (resumable): a validation or
  /// mapping failure on one item does not abort the batch. Duplicates (same
  /// title + year) are skipped; re-ingesting an existing ID with changed
  /// content increments the version and updates the record.
  Future<ReportImportSummary> importBatch(
    List<Map<String, dynamic>> rawPayloads, {
    bool updateExisting = true,
  }) async {
    final existing = await repository.getAllReports();
    final knownIndices = await repository.getAllIndices();
    final knownSurveys = await repository.getAllSurveys();
    final knownIndicators = await repository.getAllIndicators();

    final inBatch = <ReportKnowledgeObject>[];
    final reports = <ReportValidationReport>[];
    final failures = <String>[];
    final keyed = <String, ReportKnowledgeObject>{
      for (final r in existing) r.id: r,
    };
    final titleYearKey = <String, String>{
      for (final r in existing)
        '${r.officialTitle.toLowerCase().trim()}|${r.publicationYear}': r.id,
    };

    int imported = 0;
    int updated = 0;
    int duplicate = 0;

    for (var i = 0; i < rawPayloads.length; i++) {
      final payload = rawPayloads[i];
      ReportKnowledgeObject obj;
      try {
        obj = ReportKnowledgeObject.fromJson(payload);
      } catch (_) {
        failures.add('Item ${i + 1}: malformed payload rejected.');
        continue;
      }

      // Version detection: same ID re-ingested with different content updates.
      final existingById = keyed[obj.id];
      if (existingById != null) {
        final contentChanged =
            existingById.officialTitle != obj.officialTitle ||
                existingById.publicationYear != obj.publicationYear ||
                existingById.executiveSummary != obj.executiveSummary;
        if (!contentChanged) {
          duplicate++;
          reports.add(ReportValidationReport(isValid: false, issues: [
            ReportValidationIssue(
              field: 'duplicate',
              message: 'Validation Failed: Duplicate report ID "${obj.id}".',
            ),
          ]));
          continue;
        }
        if (updateExisting) {
          obj = obj.copyWith(version: existingById.version + 1);
        }
      } else {
        // Deduplicate by title + year against repository and in-batch items.
        final key = '${obj.officialTitle.toLowerCase().trim()}|${obj.publicationYear}';
        final existingIdForTitle = titleYearKey[key];
        final inBatchDuplicate = inBatch.any((r) =>
            r.officialTitle.toLowerCase().trim() ==
                obj.officialTitle.toLowerCase().trim() &&
            r.publicationYear == obj.publicationYear);
        if (existingIdForTitle != null || inBatchDuplicate) {
          duplicate++;
          reports.add(const ReportValidationReport(isValid: false, issues: [
            ReportValidationIssue(
              field: 'duplicate',
              message:
                  'Validation Failed: Duplicate report detected with matching title and year.',
            ),
          ]));
          continue;
        }
      }

      final valReport = ReportValidator.validate(
        obj,
        existingReports: [...existing, ...inBatch],
        knownIndices: knownIndices,
        knownSurveys: knownSurveys,
        knownIndicators: knownIndicators,
      );
      reports.add(valReport);

      if (!valReport.isValid) {
        failures.add(
            'Item ${i + 1} ("${obj.officialTitle}"): ${valReport.issues.map((e) => e.message).join('; ')}');
        continue;
      }

      editorialService.submitToEditorialWorkflow(obj);
      inBatch.add(obj);
      await repository.saveReport(obj);
      keyed[obj.id] = obj;
      titleYearKey['${obj.officialTitle.toLowerCase().trim()}|${obj.publicationYear}'] =
          obj.id;
      if (existingById != null) {
        updated++;
      } else {
        imported++;
      }
    }

    return ReportImportSummary(
      totalProcessed: rawPayloads.length,
      imported: imported,
      updated: updated,
      duplicate: duplicate,
      failed: failures.length,
      importedObjects: inBatch,
      validationReports: reports,
      failureMessages: failures,
    );
  }

  /// Ingest Reports from a simple CSV string (header + data rows).
  /// Expected headers include: id, officialTitle, shortName, category,
  /// publishingOrganisation, publishingMinistry, publicationYear, edition,
  /// officialUrl, evidenceIds (semicolon-separated), keywords (semicolon-separated).
  Future<ReportIngestionResult> ingestCsv(String csv) async {
    final lines = csv
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return const ReportIngestionResult(
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
      for (final listCol in const ['evidenceIds', 'keywords']) {
        final raw = payload[listCol];
        if (raw is String && raw.isNotEmpty) {
          payload[listCol] = raw
              .split(';')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      }
      if (payload.containsKey('publicationYear')) {
        payload['publicationYear'] =
            int.tryParse('${payload['publicationYear']}') ?? 0;
      }
      payloads.add(payload);
    }

    return ingestRawPayloads(payloads);
  }

  /// Adapter point for future official-PDF and OCR ingestion.
  /// Accepts extracted document metadata and returns the Report Knowledge Object.
  ReportKnowledgeObject fromPdfMetadata({
    required String id,
    required String officialTitle,
    Map<String, dynamic>? extractedFields,
  }) {
    return ReportKnowledgeObject.fromJson({
      'id': id,
      'officialTitle': officialTitle,
      ...?extractedFields,
    });
  }

  /// Ingest Indices from raw JSON payloads with validation, version detection
  /// and duplicate reporting. Returns the resulting Index knowledge objects.
  Future<List<IndexKnowledgeObject>> importIndices(
    List<Map<String, dynamic>> rawPayloads, {
    bool updateExisting = true,
  }) async {
    final imported = <IndexKnowledgeObject>[];
    final knownReports = await repository.getAllReports();
    final existing = await repository.getAllIndices();
    final keyed = {for (final i in existing) i.id: i};

    for (final payload in rawPayloads) {
      final IndexKnowledgeObject obj;
      try {
        obj = IndexKnowledgeObject.fromJson(payload);
      } catch (_) {
        continue;
      }
      final existingById = keyed[obj.id];
      if (existingById != null &&
          existingById.indexName == obj.indexName &&
          existingById.latestEditionYear == obj.latestEditionYear) {
        continue; // unchanged duplicate
      }
      final valid = ReportValidator.validateIndex(
        obj,
        existingIndices: existing,
        knownReports: knownReports,
      );
      if (!valid.isValid) continue;
      final resolved = existingById != null && updateExisting
          ? obj.copyWith(version: existingById.version + 1)
          : obj;
      editorialService
          .submitKnowledgeObject(resolved.toGarudaKnowledgeObject());
      await repository.saveIndex(resolved);
      imported.add(resolved);
      keyed[obj.id] = resolved;
    }
    return imported;
  }

  /// Ingest Surveys from raw JSON payloads with validation and duplicate
  /// detection. Returns the resulting Survey knowledge objects.
  Future<List<SurveyKnowledgeObject>> importSurveys(
    List<Map<String, dynamic>> rawPayloads, {
    bool updateExisting = true,
  }) async {
    final imported = <SurveyKnowledgeObject>[];
    final knownReports = await repository.getAllReports();
    final existing = await repository.getAllSurveys();
    final keyed = {for (final s in existing) s.id: s};

    for (final payload in rawPayloads) {
      final SurveyKnowledgeObject obj;
      try {
        obj = SurveyKnowledgeObject.fromJson(payload);
      } catch (_) {
        continue;
      }
      final existingById = keyed[obj.id];
      if (existingById != null &&
          existingById.officialTitle == obj.officialTitle &&
          existingById.surveyYear == obj.surveyYear) {
        continue; // unchanged duplicate
      }
      final valid = ReportValidator.validateSurvey(
        obj,
        existingSurveys: existing,
        knownReports: knownReports,
      );
      if (!valid.isValid) continue;
      final resolved = existingById != null && updateExisting
          ? obj.copyWith(version: existingById.version + 1)
          : obj;
      editorialService
          .submitKnowledgeObject(resolved.toGarudaKnowledgeObject());
      await repository.saveSurvey(resolved);
      imported.add(resolved);
      keyed[obj.id] = resolved;
    }
    return imported;
  }

  /// Ingest Indicators from raw JSON payloads with validation and duplicate
  /// detection. Returns the resulting Indicator knowledge objects.
  Future<List<IndicatorKnowledgeObject>> importIndicators(
    List<Map<String, dynamic>> rawPayloads, {
    bool updateExisting = true,
  }) async {
    final imported = <IndicatorKnowledgeObject>[];
    final knownReports = await repository.getAllReports();
    final existing = await repository.getAllIndicators();
    final keyed = {for (final i in existing) i.id: i};

    for (final payload in rawPayloads) {
      final IndicatorKnowledgeObject obj;
      try {
        obj = IndicatorKnowledgeObject.fromJson(payload);
      } catch (_) {
        continue;
      }
      final existingById = keyed[obj.id];
      if (existingById != null &&
          existingById.value == obj.value &&
          existingById.referenceYear == obj.referenceYear) {
        continue; // unchanged duplicate
      }
      final valid = ReportValidator.validateIndicator(
        obj,
        existingIndicators: existing,
        knownReports: knownReports,
      );
      if (!valid.isValid) continue;
      final resolved = existingById != null && updateExisting
          ? obj.copyWith(version: existingById.version + 1)
          : obj;
      editorialService
          .submitKnowledgeObject(resolved.toGarudaKnowledgeObject());
      await repository.saveIndicator(resolved);
      imported.add(resolved);
      keyed[obj.id] = resolved;
    }
    return imported;
  }

  /// Ingest a structured mixed-type payload stream. Each payload is routed to
  /// Report, Index, Survey or Indicator ingestion based on its
  /// `objectType` (defaults to `report`).
  Future<void> ingestStructured(List<Map<String, dynamic>> payloads) async {
    final reports = <Map<String, dynamic>>[];
    final indices = <Map<String, dynamic>>[];
    final surveys = <Map<String, dynamic>>[];
    final indicators = <Map<String, dynamic>>[];

    for (final payload in payloads) {
      final type = (payload['objectType'] as String? ?? 'report').toLowerCase();
      switch (type) {
        case 'index':
          indices.add(payload);
        case 'survey':
          surveys.add(payload);
        case 'indicator':
          indicators.add(payload);
        default:
          reports.add(payload);
      }
    }

    if (reports.isNotEmpty) {
      await importBatch(reports);
    }
    if (indices.isNotEmpty) {
      await importIndices(indices);
    }
    if (surveys.isNotEmpty) {
      await importSurveys(surveys);
    }
    if (indicators.isNotEmpty) {
      await importIndicators(indicators);
    }
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
