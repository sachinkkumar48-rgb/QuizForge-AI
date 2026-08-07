library;

import '../domain/entities/report_knowledge_object.dart';
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
    final objects = <ReportKnowledgeObject>[];
    final reports = <ReportValidationReport>[];

    final existing = await repository.getAllReports();
    final knownIndices = await repository.getAllIndices();
    final knownSurveys = await repository.getAllSurveys();
    final knownIndicators = await repository.getAllIndicators();

    for (final payload in rawPayloads) {
      final obj = ReportKnowledgeObject.fromJson(payload);

      final valReport = ReportValidator.validate(
        obj,
        existingReports: [...existing, ...objects],
        knownIndices: knownIndices,
        knownSurveys: knownSurveys,
        knownIndicators: knownIndicators,
      );
      reports.add(valReport);

      editorialService.submitToEditorialWorkflow(obj);

      if (valReport.isValid) {
        objects.add(obj);
        await repository.saveReport(obj);
      }
    }

    return ReportIngestionResult(
      totalProcessed: rawPayloads.length,
      totalValidated: objects.length,
      objects: objects,
      validationReports: reports,
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
