// ============================================================================
// PROJECT TITAN — GARUDA LEARNING OPERATING SYSTEM
// Multi-Exam PYQ Acquisition, Ingestion & Source Pipeline (TITAN P30)
//
// Clean Architecture Layer: Domain, Ingestion, Fetcher & Source Pipeline
//
// Target Flow:
// SOURCE (PyqSourceDescriptor)
//   ↓
// SOURCE FETCHER / ADAPTER (PyqSourceFetcher)
//   ↓
// FETCH / LOAD
//   ↓
// RAW ARTIFACT (RawArtifact: bytes/text, checksum, MIME type, metadata)
//   ↓
// ARTIFACT PARSER (PyqArtifactParser: JSON, CSV, HTML, PlainText, PDF)
//   ↓
// RAW QUESTION RECORD (RawQuestionInput)
//   ↓
// P29 NORMALIZATION (PyqNormalizationPipeline)
//   ↓
// P29 DETERMINISTIC QUESTION IDENTITY (DeterministicQuestionId)
//   ↓
// P29 DEDUPLICATION (DeterministicDuplicateDetector)
//   ↓
// PROVENANCE (PyqSourceReference & QuestionSource)
//   ↓
// REPOSITORY / INDEX (MultiExamPyqIntelligenceService)
//   ↓
// EXAM INTELLIGENCE (PyqCorpusIntelligence & PyqTrendAnalyzer)
//
// Invariants:
// 1. 100% Offline execution without live HTTP dependencies.
// 2. Generic acquisition engine — zero exam-specific fetcher duplication.
// 3. Deterministic SHA-256 artifact checksum & question identity.
// 4. Idempotent repeated ingestion across restarts.
// 5. Failure isolation: Malformed records never crash valid batches.
// 6. Multi-language preservation: English and Hindi variants are never
//    accidentally collapsed as duplicates.
// 7. Strict provenance tracking for every accepted question.
// ============================================================================

import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';

import '../models/source_model.dart';
import '../multi_exam/multi_exam_pyq_intelligence.dart';

// ============================================================================
// 1. SOURCE CONTRACT & DESCRIPTORS
// ============================================================================

/// Supported source artifact data formats.
enum PyqSourceFormat {
  json,
  csv,
  html,
  plainText,
  pdfText,
  custom;

  static PyqSourceFormat fromExtensionOrMime(String pathOrMime) {
    final lower = pathOrMime.toLowerCase();
    if (lower.endsWith('.json') || lower.contains('application/json')) {
      return PyqSourceFormat.json;
    }
    if (lower.endsWith('.csv') || lower.contains('text/csv')) {
      return PyqSourceFormat.csv;
    }
    if (lower.endsWith('.html') ||
        lower.endsWith('.htm') ||
        lower.contains('text/html')) {
      return PyqSourceFormat.html;
    }
    if (lower.endsWith('.txt') || lower.contains('text/plain')) {
      return PyqSourceFormat.plainText;
    }
    if (lower.endsWith('.pdf') || lower.contains('application/pdf')) {
      return PyqSourceFormat.pdfText;
    }
    return PyqSourceFormat.custom;
  }
}

/// Source availability tier.
enum SourceAvailability {
  available,
  restricted,
  archived,
  deprecated,
}

/// Generic source descriptor representing an authoritative PYQ source.
@immutable
class PyqSourceDescriptor {
  final String sourceId;
  final String sourceName;
  final String examId;
  final String publisher;
  final SourceType sourceType;
  final PyqSourceFormat format;
  final List<int> years;
  final List<String> languages;
  final String uriOrPath;
  final SourceAvailability availability;
  final Map<String, dynamic> metadata;

  const PyqSourceDescriptor({
    required this.sourceId,
    required this.sourceName,
    required this.examId,
    required this.publisher,
    required this.sourceType,
    required this.format,
    required this.years,
    required this.languages,
    required this.uriOrPath,
    this.availability = SourceAvailability.available,
    this.metadata = const {},
  });

  /// Validates descriptor invariants. Throws [ArgumentError] on invalid state.
  void validate() {
    if (sourceId.trim().isEmpty) {
      throw ArgumentError.value(
          sourceId, 'sourceId', 'sourceId cannot be empty');
    }
    if (sourceName.trim().isEmpty) {
      throw ArgumentError.value(
          sourceName, 'sourceName', 'sourceName cannot be empty');
    }
    if (examId.trim().isEmpty) {
      throw ArgumentError.value(examId, 'examId', 'examId cannot be empty');
    }
    if (publisher.trim().isEmpty) {
      throw ArgumentError.value(
          publisher, 'publisher', 'publisher cannot be empty');
    }
    if (years.isEmpty) {
      throw ArgumentError.value(
          years, 'years', 'Source must specify at least one supported year');
    }
    for (final year in years) {
      if (year < 1900 || year > 2100) {
        throw ArgumentError.value(
            year, 'year', 'Year must be between 1900 and 2100');
      }
    }
  }

  PyqSourceDescriptor copyWith({
    String? sourceId,
    String? sourceName,
    String? examId,
    String? publisher,
    SourceType? sourceType,
    PyqSourceFormat? format,
    List<int>? years,
    List<String>? languages,
    String? uriOrPath,
    SourceAvailability? availability,
    Map<String, dynamic>? metadata,
  }) {
    return PyqSourceDescriptor(
      sourceId: sourceId ?? this.sourceId,
      sourceName: sourceName ?? this.sourceName,
      examId: examId ?? this.examId,
      publisher: publisher ?? this.publisher,
      sourceType: sourceType ?? this.sourceType,
      format: format ?? this.format,
      years: years ?? this.years,
      languages: languages ?? this.languages,
      uriOrPath: uriOrPath ?? this.uriOrPath,
      availability: availability ?? this.availability,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'sourceId': sourceId,
        'sourceName': sourceName,
        'examId': examId,
        'publisher': publisher,
        'sourceType': sourceType.name,
        'format': format.name,
        'years': years,
        'languages': languages,
        'uriOrPath': uriOrPath,
        'availability': availability.name,
        'metadata': metadata,
      };

  factory PyqSourceDescriptor.fromJson(Map<String, dynamic> json) {
    return PyqSourceDescriptor(
      sourceId: json['sourceId'] as String,
      sourceName: json['sourceName'] as String,
      examId: json['examId'] as String,
      publisher: json['publisher'] as String,
      sourceType: SourceType.values.firstWhere(
        (e) => e.name == json['sourceType'],
        orElse: () => SourceType.verifiedArchive,
      ),
      format: PyqSourceFormat.values.firstWhere(
        (e) => e.name == json['format'],
        orElse: () => PyqSourceFormat.json,
      ),
      years: (json['years'] as List<dynamic>).map((e) => e as int).toList(),
      languages: (json['languages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const ['en'],
      uriOrPath: json['uriOrPath'] as String? ?? '',
      availability: SourceAvailability.values.firstWhere(
        (e) => e.name == json['availability'],
        orElse: () => SourceAvailability.available,
      ),
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PyqSourceDescriptor &&
          runtimeType == other.runtimeType &&
          sourceId == other.sourceId &&
          examId == other.examId &&
          format == other.format;

  @override
  int get hashCode => sourceId.hashCode ^ examId.hashCode ^ format.hashCode;

  @override
  String toString() =>
      'PyqSourceDescriptor($sourceId, exam: $examId, format: ${format.name}, years: $years)';
}

// ============================================================================
// 2. RAW ARTIFACT MODEL
// ============================================================================

/// Represents a raw, unparsed source artifact retrieved by a fetcher.
@immutable
class RawArtifact {
  final String artifactId;
  final PyqSourceDescriptor sourceDescriptor;
  final String text;
  final Uint8List? rawBytes;
  final String checksum;
  final DateTime retrievalTimestamp;
  final String contentType;
  final Map<String, dynamic> metadata;

  const RawArtifact._({
    required this.artifactId,
    required this.sourceDescriptor,
    required this.text,
    required this.rawBytes,
    required this.checksum,
    required this.retrievalTimestamp,
    required this.contentType,
    required this.metadata,
  });

  /// Constructs a [RawArtifact] from a text string with deterministic SHA-256 checksum.
  factory RawArtifact.fromText({
    required PyqSourceDescriptor sourceDescriptor,
    required String text,
    String? contentType,
    DateTime? timestamp,
    Map<String, dynamic> metadata = const {},
  }) {
    final encoded = utf8.encode(text);
    final checksum = sha256.convert(encoded).toString();
    final effectiveTimestamp = timestamp ?? DateTime.now().toUtc();
    final effectiveContentType =
        contentType ?? _inferContentType(sourceDescriptor.format);
    final id = 'ART_${sourceDescriptor.sourceId}_${checksum.substring(0, 10)}';

    return RawArtifact._(
      artifactId: id,
      sourceDescriptor: sourceDescriptor,
      text: text,
      rawBytes: Uint8List.fromList(encoded),
      checksum: checksum,
      retrievalTimestamp: effectiveTimestamp,
      contentType: effectiveContentType,
      metadata: metadata,
    );
  }

  /// Constructs a [RawArtifact] from binary bytes.
  factory RawArtifact.fromBytes({
    required PyqSourceDescriptor sourceDescriptor,
    required Uint8List bytes,
    String? contentType,
    DateTime? timestamp,
    Map<String, dynamic> metadata = const {},
  }) {
    final checksum = sha256.convert(bytes).toString();
    final text = utf8.decode(bytes, allowMalformed: true);
    final effectiveTimestamp = timestamp ?? DateTime.now().toUtc();
    final effectiveContentType =
        contentType ?? _inferContentType(sourceDescriptor.format);
    final id = 'ART_${sourceDescriptor.sourceId}_${checksum.substring(0, 10)}';

    return RawArtifact._(
      artifactId: id,
      sourceDescriptor: sourceDescriptor,
      text: text,
      rawBytes: bytes,
      checksum: checksum,
      retrievalTimestamp: effectiveTimestamp,
      contentType: effectiveContentType,
      metadata: metadata,
    );
  }

  static String _inferContentType(PyqSourceFormat format) {
    switch (format) {
      case PyqSourceFormat.json:
        return 'application/json';
      case PyqSourceFormat.csv:
        return 'text/csv';
      case PyqSourceFormat.html:
        return 'text/html';
      case PyqSourceFormat.plainText:
        return 'text/plain';
      case PyqSourceFormat.pdfText:
        return 'application/pdf';
      case PyqSourceFormat.custom:
        return 'application/octet-stream';
    }
  }

  Map<String, dynamic> toJson() => {
        'artifactId': artifactId,
        'sourceDescriptor': sourceDescriptor.toJson(),
        'text': text,
        'checksum': checksum,
        'retrievalTimestamp': retrievalTimestamp.toIso8601String(),
        'contentType': contentType,
        'metadata': metadata,
      };

  factory RawArtifact.fromJson(Map<String, dynamic> json) {
    return RawArtifact.fromText(
      sourceDescriptor: PyqSourceDescriptor.fromJson(
          json['sourceDescriptor'] as Map<String, dynamic>),
      text: json['text'] as String,
      contentType: json['contentType'] as String?,
      timestamp: DateTime.parse(json['retrievalTimestamp'] as String),
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
    );
  }

  @override
  String toString() =>
      'RawArtifact($artifactId, checksum: ${checksum.substring(0, 8)}, chars: ${text.length})';
}

// ============================================================================
// 3. FETCH / LOAD ABSTRACTION
// ============================================================================

/// Exception thrown when a source cannot be fetched or loaded.
class SourceFetchException implements Exception {
  final String sourceId;
  final String message;
  final Object? cause;

  const SourceFetchException({
    required this.sourceId,
    required this.message,
    this.cause,
  });

  @override
  String toString() =>
      'SourceFetchException(source: $sourceId): $message${cause != null ? ' (cause: $cause)' : ''}';
}

/// Abstract contract for acquiring raw artifacts from sources.
abstract class PyqSourceFetcher {
  /// Checks whether this fetcher can handle the given descriptor.
  bool canFetch(PyqSourceDescriptor descriptor);

  /// Fetches or loads the raw artifact for the descriptor.
  Future<RawArtifact> fetch(PyqSourceDescriptor descriptor);
}

/// In-memory fixture fetcher for deterministic, 100% offline unit and integration tests.
class InMemorySourceFetcher implements PyqSourceFetcher {
  final Map<String, RawArtifact> _artifacts = {};

  InMemorySourceFetcher([Map<String, RawArtifact>? initialArtifacts]) {
    if (initialArtifacts != null) {
      _artifacts.addAll(initialArtifacts);
    }
  }

  /// Registers a pre-built [RawArtifact].
  void registerArtifact(RawArtifact artifact) {
    _artifacts[artifact.sourceDescriptor.sourceId] = artifact;
  }

  /// Registers a source with raw string content.
  void registerText(
    PyqSourceDescriptor descriptor,
    String text, {
    Map<String, dynamic> metadata = const {},
  }) {
    final artifact = RawArtifact.fromText(
      sourceDescriptor: descriptor,
      text: text,
      metadata: metadata,
    );
    _artifacts[descriptor.sourceId] = artifact;
  }

  @override
  bool canFetch(PyqSourceDescriptor descriptor) =>
      _artifacts.containsKey(descriptor.sourceId) ||
      descriptor.uriOrPath.startsWith('memory:');

  @override
  Future<RawArtifact> fetch(PyqSourceDescriptor descriptor) async {
    final artifact = _artifacts[descriptor.sourceId];
    if (artifact == null) {
      throw SourceFetchException(
        sourceId: descriptor.sourceId,
        message:
            'No in-memory artifact registered for source "${descriptor.sourceId}"',
      );
    }
    return artifact;
  }

  void clear() => _artifacts.clear();
}

/// Composite source fetcher delegating to child fetchers in priority order.
class CompositeSourceFetcher implements PyqSourceFetcher {
  final List<PyqSourceFetcher> _fetchers;

  const CompositeSourceFetcher(this._fetchers);

  @override
  bool canFetch(PyqSourceDescriptor descriptor) =>
      _fetchers.any((f) => f.canFetch(descriptor));

  @override
  Future<RawArtifact> fetch(PyqSourceDescriptor descriptor) async {
    for (final fetcher in _fetchers) {
      if (fetcher.canFetch(descriptor)) {
        return fetcher.fetch(descriptor);
      }
    }
    throw SourceFetchException(
      sourceId: descriptor.sourceId,
      message: 'No fetcher available to handle source "${descriptor.sourceId}"',
    );
  }
}

// ============================================================================
// 4. DIAGNOSTICS & QUALITY SUMMARY
// ============================================================================

/// Diagnostic severity levels.
enum DiagnosticSeverity {
  info,
  warning,
  error,
}

/// Diagnostic record emitted during parsing, normalization, or ingestion.
@immutable
class PyqImportDiagnostic {
  final DiagnosticSeverity severity;
  final int? recordIndex;
  final String? rawRecordId;
  final String message;
  final Map<String, dynamic>? details;

  const PyqImportDiagnostic({
    required this.severity,
    this.recordIndex,
    this.rawRecordId,
    required this.message,
    this.details,
  });

  Map<String, dynamic> toJson() => {
        'severity': severity.name,
        'recordIndex': recordIndex,
        'rawRecordId': rawRecordId,
        'message': message,
        'details': details,
      };

  @override
  String toString() =>
      '[${severity.name.toUpperCase()}]${recordIndex != null ? ' (row $recordIndex)' : ''}: $message';
}

/// Machine-readable import quality summary.
@immutable
class ImportQualitySummary {
  final String sourceId;
  final String examId;
  final int recordsRead;
  final int recordsAccepted;
  final int recordsDuplicate;
  final int recordsMalformed;
  final int recordsUnmapped;
  final double acceptanceRate;
  final int processingTimeMs;
  final double provenanceCompleteRate;

  const ImportQualitySummary({
    required this.sourceId,
    required this.examId,
    required this.recordsRead,
    required this.recordsAccepted,
    required this.recordsDuplicate,
    required this.recordsMalformed,
    required this.recordsUnmapped,
    required this.acceptanceRate,
    required this.processingTimeMs,
    required this.provenanceCompleteRate,
  });

  Map<String, dynamic> toJson() => {
        'sourceId': sourceId,
        'examId': examId,
        'recordsRead': recordsRead,
        'recordsAccepted': recordsAccepted,
        'recordsDuplicate': recordsDuplicate,
        'recordsMalformed': recordsMalformed,
        'recordsUnmapped': recordsUnmapped,
        'acceptanceRate': acceptanceRate,
        'processingTimeMs': processingTimeMs,
        'provenanceCompleteRate': provenanceCompleteRate,
      };

  String formatReport() {
    final buffer = StringBuffer();
    buffer.writeln('========================================');
    buffer.writeln('PYQ INGESTION QUALITY SUMMARY');
    buffer.writeln('Source ID: $sourceId | Exam: $examId');
    buffer.writeln('Records Read:      $recordsRead');
    buffer.writeln(
        'Records Accepted:  $recordsAccepted (${(acceptanceRate * 100).toStringAsFixed(1)}%)');
    buffer.writeln('Duplicates:        $recordsDuplicate');
    buffer.writeln('Malformed/Skipped: $recordsMalformed');
    buffer.writeln('Unmapped:          $recordsUnmapped');
    buffer.writeln(
        'Provenance Rate:   ${(provenanceCompleteRate * 100).toStringAsFixed(1)}%');
    buffer.writeln('Processing Time:   ${processingTimeMs}ms');
    buffer.writeln('========================================');
    return buffer.toString();
  }

  @override
  String toString() => formatReport();
}

// ============================================================================
// 5. PARSER ARCHITECTURE
// ============================================================================

/// Abstract parser interface converting a [RawArtifact] into permissive [RawQuestionInput] records.
abstract class PyqArtifactParser {
  /// Checks whether this parser handles the given format and content type.
  bool canParse(PyqSourceFormat format, String contentType);

  /// Parses the raw artifact into a list of [RawQuestionInput] DTOs.
  /// Collects diagnostics without failing the entire batch on malformed records.
  List<RawQuestionInput> parse(
    RawArtifact artifact, {
    List<PyqImportDiagnostic>? diagnostics,
  });
}

/// JSON parser supporting standard arrays, wrapped objects, and multilingual entries.
class JsonPyqParser implements PyqArtifactParser {
  const JsonPyqParser();

  @override
  bool canParse(PyqSourceFormat format, String contentType) =>
      format == PyqSourceFormat.json ||
      contentType.contains('application/json');

  @override
  List<RawQuestionInput> parse(
    RawArtifact artifact, {
    List<PyqImportDiagnostic>? diagnostics,
  }) {
    final results = <RawQuestionInput>[];
    dynamic decoded;

    try {
      decoded = jsonDecode(artifact.text);
    } catch (e) {
      diagnostics?.add(PyqImportDiagnostic(
        severity: DiagnosticSeverity.error,
        message: 'Invalid JSON document syntax: $e',
      ));
      return const [];
    }

    List<dynamic> items;
    if (decoded is List) {
      items = decoded;
    } else if (decoded is Map<String, dynamic> &&
        decoded.containsKey('questions')) {
      items = decoded['questions'] as List<dynamic>;
    } else if (decoded is Map<String, dynamic>) {
      // Single question item
      items = [decoded];
    } else {
      diagnostics?.add(const PyqImportDiagnostic(
        severity: DiagnosticSeverity.error,
        message:
            'JSON structure must be an array of questions or an object with a "questions" key',
      ));
      return const [];
    }

    final descriptor = artifact.sourceDescriptor;

    for (var i = 0; i < items.length; i++) {
      final rawItem = items[i];
      if (rawItem is! Map<String, dynamic>) {
        diagnostics?.add(PyqImportDiagnostic(
          severity: DiagnosticSeverity.warning,
          recordIndex: i,
          message: 'Item at index $i is not a JSON object, skipping',
        ));
        continue;
      }

      try {
        final parsed = _parseJsonQuestion(
            rawItem, descriptor, artifact.checksum, i, diagnostics);
        if (parsed != null) {
          results.add(parsed);
        }
      } catch (e) {
        diagnostics?.add(PyqImportDiagnostic(
          severity: DiagnosticSeverity.warning,
          recordIndex: i,
          message: 'Malformed question at index $i: $e',
        ));
      }
    }

    return results;
  }

  RawQuestionInput? _parseJsonQuestion(
    Map<String, dynamic> json,
    PyqSourceDescriptor descriptor,
    String artifactChecksum,
    int index,
    List<PyqImportDiagnostic>? diagnostics,
  ) {
    final text = (json['questionText'] ??
        json['question'] ??
        json['originalQuestion'] ??
        json['text']) as String?;

    if (text == null || text.trim().isEmpty) {
      diagnostics?.add(PyqImportDiagnostic(
        severity: DiagnosticSeverity.warning,
        recordIndex: index,
        message: 'Question at index $index missing questionText, skipping',
      ));
      return null;
    }

    // Extract options
    final rawOptions = json['options'];
    final List<String> options = [];
    if (rawOptions is List) {
      for (final opt in rawOptions) {
        if (opt is String) {
          options.add(opt);
        } else if (opt is Map<String, dynamic>) {
          final optText = opt['text'] as String? ?? '';
          final optKey = opt['key'] as String?;
          options.add(optKey != null ? '($optKey) $optText' : optText);
        }
      }
    }

    if (options.length < 2) {
      diagnostics?.add(PyqImportDiagnostic(
        severity: DiagnosticSeverity.warning,
        recordIndex: index,
        message:
            'Question at index $index has fewer than 2 options (${options.length}), skipping',
      ));
      return null;
    }

    // Extract correct answer
    final rawCorrect = json['correctAnswer'] ??
        json['correctOption'] ??
        json['correctKey'] ??
        json['answer'];
    String correctAnswer = 'A';
    if (rawCorrect is String && rawCorrect.trim().isNotEmpty) {
      correctAnswer = rawCorrect.trim();
    } else if (rawCorrect is Map<String, dynamic>) {
      final keys = rawCorrect['correctOptionKeys'];
      if (keys is List && keys.isNotEmpty) {
        correctAnswer = keys.first.toString().trim();
      }
    }

    final examId =
        (json['examId'] ?? json['exam'] ?? descriptor.examId) as String;
    final year = (json['year'] as num?)?.toInt() ?? descriptor.years.first;
    final paper = (json['paper'] ?? json['stage'] ?? 'GS1') as String;
    final qNum = (json['questionNumber'] as num?)?.toInt() ?? (index + 1);
    final subject = (json['subject'] ?? 'General Studies') as String;
    final topic = (json['topic'] ?? 'General') as String;
    final explanation =
        (json['explanation'] ?? json['garudaExplanation']) as String?;
    final language = (json['language'] ??
        json['languageCode'] ??
        descriptor.languages.first) as String;
    final difficulty = json['difficulty'] as String?;

    // Objectives
    final rawObjs = json['objectiveIds'] ?? json['objectives'];
    final List<String> objectiveIds = [];
    if (rawObjs is List) {
      for (final o in rawObjs) {
        if (o != null) objectiveIds.add(o.toString());
      }
    }

    // Provenance
    final sourceRef = PyqSourceReference(
      sourceId: descriptor.sourceId,
      sourceType: descriptor.sourceType.name,
      sourceTitle: descriptor.sourceName,
      sourceUrl: descriptor.uriOrPath,
      publisher: descriptor.publisher,
      retrievedAt: DateTime.now().toUtc(),
      checksum: artifactChecksum,
    );

    return RawQuestionInput(
      rawId: json['id'] as String?,
      examId: examId,
      year: year,
      paper: paper,
      questionNumber: qNum,
      subject: subject,
      topic: topic,
      questionText: text,
      options: options,
      correctAnswer: correctAnswer,
      explanation: explanation,
      language: language,
      difficulty: difficulty,
      objectiveIds: objectiveIds,
      source: sourceRef,
      metadata: json,
    );
  }
}

/// RFC-compliant CSV parser handling quoted fields, commas inside quotes, and headers.
class CsvPyqParser implements PyqArtifactParser {
  const CsvPyqParser();

  @override
  bool canParse(PyqSourceFormat format, String contentType) =>
      format == PyqSourceFormat.csv || contentType.contains('text/csv');

  @override
  List<RawQuestionInput> parse(
    RawArtifact artifact, {
    List<PyqImportDiagnostic>? diagnostics,
  }) {
    final rows = _tokenizeCsv(artifact.text);
    if (rows.isEmpty) return const [];

    final descriptor = artifact.sourceDescriptor;
    final results = <RawQuestionInput>[];

    // Detect header
    var headerRowIndex = -1;
    Map<String, int> columnMap = {};

    final firstRow = rows.first.map((c) => c.trim().toLowerCase()).toList();
    if (firstRow.any(
        (c) => c.contains('question') || c.contains('exam') || c == 'id')) {
      headerRowIndex = 0;
      for (var col = 0; col < firstRow.length; col++) {
        columnMap[firstRow[col]] = col;
      }
    }

    final startIndex = headerRowIndex >= 0 ? headerRowIndex + 1 : 0;

    for (var i = startIndex; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty || (row.length == 1 && row.first.trim().isEmpty)) {
        continue;
      }

      try {
        final parsed = _parseCsvRow(
            row, columnMap, descriptor, artifact.checksum, i, diagnostics);
        if (parsed != null) {
          results.add(parsed);
        }
      } catch (e) {
        diagnostics?.add(PyqImportDiagnostic(
          severity: DiagnosticSeverity.warning,
          recordIndex: i,
          message: 'Malformed CSV row $i: $e',
        ));
      }
    }

    return results;
  }

  RawQuestionInput? _parseCsvRow(
    List<String> row,
    Map<String, int> colMap,
    PyqSourceDescriptor descriptor,
    String artifactChecksum,
    int rowIndex,
    List<PyqImportDiagnostic>? diagnostics,
  ) {
    String getCol(String name, [int fallbackIndex = -1]) {
      final idx = colMap[name.toLowerCase()];
      if (idx != null && idx < row.length) {
        return row[idx].trim();
      }
      if (fallbackIndex >= 0 && fallbackIndex < row.length) {
        return row[fallbackIndex].trim();
      }
      return '';
    }

    final text = colMap.isNotEmpty
        ? (getCol('questiontext').isNotEmpty
            ? getCol('questiontext')
            : getCol('question').isNotEmpty
                ? getCol('question')
                : getCol('text'))
        : (row.length > 6
            ? row[6].trim()
            : (row.isNotEmpty ? row[0].trim() : ''));

    if (text.isEmpty) {
      diagnostics?.add(PyqImportDiagnostic(
        severity: DiagnosticSeverity.warning,
        recordIndex: rowIndex,
        message: 'CSV row $rowIndex missing question text, skipping',
      ));
      return null;
    }

    final options = <String>[];
    if (colMap.isNotEmpty) {
      final a = getCol('optiona');
      final b = getCol('optionb');
      final c = getCol('optionc');
      final d = getCol('optiond');
      if (a.isNotEmpty) options.add(a);
      if (b.isNotEmpty) options.add(b);
      if (c.isNotEmpty) options.add(c);
      if (d.isNotEmpty) options.add(d);
    } else if (row.length >= 11) {
      if (row[7].trim().isNotEmpty) options.add(row[7].trim());
      if (row[8].trim().isNotEmpty) options.add(row[8].trim());
      if (row[9].trim().isNotEmpty) options.add(row[9].trim());
      if (row[10].trim().isNotEmpty) options.add(row[10].trim());
    }

    if (options.length < 2) {
      diagnostics?.add(PyqImportDiagnostic(
        severity: DiagnosticSeverity.warning,
        recordIndex: rowIndex,
        message: 'CSV row $rowIndex has fewer than 2 options, skipping',
      ));
      return null;
    }

    final rawId = colMap.isNotEmpty
        ? getCol('id')
        : (row.isNotEmpty ? row[0].trim() : null);
    final examId = (colMap.isNotEmpty ? getCol('examid') : '')
        .ifEmptyThen(descriptor.examId);
    final rawYear = colMap.isNotEmpty
        ? getCol('year')
        : (row.length > 2 ? row[2].trim() : '');
    final year = int.tryParse(rawYear) ?? descriptor.years.first;
    final paper = (colMap.isNotEmpty
            ? getCol('paper')
            : (row.length > 3 ? row[3].trim() : ''))
        .ifEmptyThen('GS1');
    final subject = (colMap.isNotEmpty
            ? getCol('subject')
            : (row.length > 4 ? row[4].trim() : ''))
        .ifEmptyThen('General Studies');
    final topic = (colMap.isNotEmpty
            ? getCol('topic')
            : (row.length > 5 ? row[5].trim() : ''))
        .ifEmptyThen('General');
    final correctRaw = colMap.isNotEmpty
        ? (getCol('correctkey').isNotEmpty
            ? getCol('correctkey')
            : getCol('correct'))
        : (row.length > 11 ? row[11].trim() : 'A');
    final correct = correctRaw.isNotEmpty ? correctRaw : 'A';

    final explanation = colMap.isNotEmpty
        ? getCol('explanation')
        : (row.length > 12 ? row[12].trim() : null);
    final language = (colMap.isNotEmpty
            ? getCol('language')
            : (row.length > 13 ? row[13].trim() : ''))
        .ifEmptyThen(descriptor.languages.first);

    final sourceRef = PyqSourceReference(
      sourceId: descriptor.sourceId,
      sourceType: descriptor.sourceType.name,
      sourceTitle: descriptor.sourceName,
      sourceUrl: descriptor.uriOrPath,
      publisher: descriptor.publisher,
      retrievedAt: DateTime.now().toUtc(),
      checksum: artifactChecksum,
    );

    return RawQuestionInput(
      rawId: rawId,
      examId: examId,
      year: year,
      paper: paper,
      questionNumber: int.tryParse(rawId ?? '') ?? (rowIndex + 1),
      subject: subject,
      topic: topic,
      questionText: text,
      options: options,
      correctAnswer: correct,
      explanation: explanation,
      language: language,
      source: sourceRef,
    );
  }

  /// Lightweight RFC-4180 tokenizer supporting quotes, escaped quotes, and newlines in cells.
  static List<List<String>> _tokenizeCsv(String input) {
    final rows = <List<String>>[];
    final currentRow = <String>[];
    final currentCell = StringBuffer();
    bool inQuotes = false;

    for (var i = 0; i < input.length; i++) {
      final char = input[i];

      if (char == '"') {
        if (inQuotes && i + 1 < input.length && input[i + 1] == '"') {
          currentCell.write('"');
          i++; // Skip escaped quote
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        currentRow.add(currentCell.toString());
        currentCell.clear();
      } else if ((char == '\n' || char == '\r') && !inQuotes) {
        if (char == '\r' && i + 1 < input.length && input[i + 1] == '\n') {
          i++; // Handle CRLF
        }
        currentRow.add(currentCell.toString());
        currentCell.clear();
        if (currentRow.any((c) => c.trim().isNotEmpty)) {
          rows.add(List.of(currentRow));
        }
        currentRow.clear();
      } else {
        currentCell.write(char);
      }
    }

    if (currentCell.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(currentCell.toString());
      if (currentRow.any((c) => c.trim().isNotEmpty)) {
        rows.add(currentRow);
      }
    }

    return rows;
  }
}

/// HTML parser for structured web fixtures and portal extractions.
class HtmlPyqParser implements PyqArtifactParser {
  const HtmlPyqParser();

  @override
  bool canParse(PyqSourceFormat format, String contentType) =>
      format == PyqSourceFormat.html || contentType.contains('text/html');

  @override
  List<RawQuestionInput> parse(
    RawArtifact artifact, {
    List<PyqImportDiagnostic>? diagnostics,
  }) {
    final results = <RawQuestionInput>[];
    final descriptor = artifact.sourceDescriptor;

    final blockRegex = RegExp(
      r'<div[^>]*class="[^"]*(?:question-block|pyq-card|question)[^"]*"[^>]*>(.*?)<\/div>\s*<\/div>',
      caseSensitive: false,
      dotAll: true,
    );

    var matches = blockRegex.allMatches(artifact.text).toList();

    if (matches.isEmpty) {
      final fallbackRegex = RegExp(
        r'<div[^>]*class="[^"]*question[^"]*"[^>]*>(.*?)(?=<div[^>]*class="[^"]*question[^"]*"|$)',
        caseSensitive: false,
        dotAll: true,
      );
      matches = fallbackRegex.allMatches(artifact.text).toList();
    }

    for (var i = 0; i < matches.length; i++) {
      final block = matches[i].group(0) ?? '';
      try {
        final parsed = _parseHtmlBlock(
            block, descriptor, artifact.checksum, i, diagnostics);
        if (parsed != null) {
          results.add(parsed);
        }
      } catch (e) {
        diagnostics?.add(PyqImportDiagnostic(
          severity: DiagnosticSeverity.warning,
          recordIndex: i,
          message: 'Error parsing HTML question block $i: $e',
        ));
      }
    }

    return results;
  }

  RawQuestionInput? _parseHtmlBlock(
    String html,
    PyqSourceDescriptor descriptor,
    String artifactChecksum,
    int index,
    List<PyqImportDiagnostic>? diagnostics,
  ) {
    // 1. Question Text
    final textMatch = RegExp(
      r'<p[^>]*class="[^"]*(?:question-text|q-text)[^"]*"[^>]*>(.*?)<\/p>',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(html);

    String qText = '';
    if (textMatch != null) {
      qText = _stripHtml(textMatch.group(1) ?? '');
    } else {
      final pMatch =
          RegExp(r'<p[^>]*>(.*?)<\/p>', caseSensitive: false, dotAll: true)
              .firstMatch(html);
      if (pMatch != null) {
        qText = _stripHtml(pMatch.group(1) ?? '');
      }
    }

    if (qText.trim().isEmpty) {
      diagnostics?.add(PyqImportDiagnostic(
        severity: DiagnosticSeverity.warning,
        recordIndex: index,
        message: 'HTML question block $index missing question text, skipping',
      ));
      return null;
    }

    // 2. Options
    final optMatches = RegExp(
      r'<li[^>]*>(.*?)<\/li>|<div[^>]*class="[^"]*option[^"]*"[^>]*>(.*?)<\/div>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(html);

    final options = <String>[];
    for (final m in optMatches) {
      final optRaw = m.group(1) ?? m.group(2) ?? '';
      final clean = _stripHtml(optRaw).trim();
      if (clean.isNotEmpty) {
        options.add(clean);
      }
    }

    if (options.length < 2) {
      diagnostics?.add(PyqImportDiagnostic(
        severity: DiagnosticSeverity.warning,
        recordIndex: index,
        message:
            'HTML question block $index has fewer than 2 options, skipping',
      ));
      return null;
    }

    // 3. Correct Answer
    final ansMatch = RegExp(
      r'data-answer="([^"]+)"|class="[^"]*answer[^"]*"[^>]*>(?:Answer:\s*)?([A-Da-d1-4])',
      caseSensitive: false,
    ).firstMatch(html);
    final correct = ansMatch?.group(1) ?? ansMatch?.group(2) ?? 'A';

    // 4. Explanation
    final expMatch = RegExp(
      r'<div[^>]*class="[^"]*explanation[^"]*"[^>]*>(.*?)<\/div>',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(html);
    final explanation =
        expMatch != null ? _stripHtml(expMatch.group(1) ?? '') : null;

    final sourceRef = PyqSourceReference(
      sourceId: descriptor.sourceId,
      sourceType: descriptor.sourceType.name,
      sourceTitle: descriptor.sourceName,
      sourceUrl: descriptor.uriOrPath,
      publisher: descriptor.publisher,
      retrievedAt: DateTime.now().toUtc(),
      checksum: artifactChecksum,
    );

    return RawQuestionInput(
      examId: descriptor.examId,
      year: descriptor.years.first,
      paper: 'GS1',
      questionNumber: index + 1,
      subject: 'General Studies',
      topic: 'General',
      questionText: qText,
      options: options,
      correctAnswer: correct,
      explanation: explanation,
      language: descriptor.languages.first,
      source: sourceRef,
    );
  }

  static String _stripHtml(String html) {
    var text = html.replaceAll(RegExp(r'<[^>]*>'), ' ');
    text = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

/// Plain-text question paper parser recognizing standard examination numbered blocks.
class TextPyqParser implements PyqArtifactParser {
  const TextPyqParser();

  @override
  bool canParse(PyqSourceFormat format, String contentType) =>
      format == PyqSourceFormat.plainText ||
      format == PyqSourceFormat.pdfText ||
      contentType.contains('text/plain');

  @override
  List<RawQuestionInput> parse(
    RawArtifact artifact, {
    List<PyqImportDiagnostic>? diagnostics,
  }) {
    final text = artifact.text;
    if (text.trim().isEmpty) return const [];

    final descriptor = artifact.sourceDescriptor;
    final results = <RawQuestionInput>[];

    final qSplitRegex = RegExp(
      r'(?:^|\n\s*)(?:Q(?:uestion|\.)?\s*(\d+)[\s.:-]+|प्रश्न\s*(\d+)[\s.:-]+|(\d+)\.\s+)',
      multiLine: true,
      caseSensitive: false,
    );

    final matches = qSplitRegex.allMatches(text).toList();
    if (matches.isEmpty) {
      diagnostics?.add(const PyqImportDiagnostic(
        severity: DiagnosticSeverity.warning,
        message: 'No structured question numbers found in plain text document',
      ));
      return const [];
    }

    for (var i = 0; i < matches.length; i++) {
      final currentMatch = matches[i];
      final startIdx = currentMatch.start;
      final endIdx =
          (i + 1 < matches.length) ? matches[i + 1].start : text.length;
      final block = text.substring(startIdx, endIdx).trim();

      final qNumStr = currentMatch.group(1) ??
          currentMatch.group(2) ??
          currentMatch.group(3);
      final qNum = int.tryParse(qNumStr ?? '') ?? (i + 1);

      try {
        final parsed = _parseTextBlock(
            block, qNum, descriptor, artifact.checksum, i, diagnostics);
        if (parsed != null) {
          results.add(parsed);
        }
      } catch (e) {
        diagnostics?.add(PyqImportDiagnostic(
          severity: DiagnosticSeverity.warning,
          recordIndex: i,
          message: 'Error parsing text question $qNum: $e',
        ));
      }
    }

    return results;
  }

  RawQuestionInput? _parseTextBlock(
    String block,
    int questionNumber,
    PyqSourceDescriptor descriptor,
    String artifactChecksum,
    int index,
    List<PyqImportDiagnostic>? diagnostics,
  ) {
    final optRegex = RegExp(
      r'(?:^|\n|\s)\(?([A-Da-d1-4])\)?[\s.:-]+(.*?)(?=\(?([A-Da-d1-4])\)?[\s.:-]+|(?:Ans(?:wer)?|Correct|Exp(?:lanation)?):|$)',
      dotAll: true,
    );

    final optMatches = optRegex.allMatches(block).toList();
    if (optMatches.length < 2) {
      diagnostics?.add(PyqImportDiagnostic(
        severity: DiagnosticSeverity.warning,
        recordIndex: index,
        message:
            'Question $questionNumber has fewer than 2 detected options, skipping',
      ));
      return null;
    }

    final firstOptStart = optMatches.first.start;
    var qText = block.substring(0, firstOptStart).trim();

    qText = qText
        .replaceAll(
          RegExp(
              r'^(?:Q(?:uestion|\.)?\s*\d+[\s.:-]+|प्रश्न\s*\d+[\s.:-]+|\d+\.\s*)',
              caseSensitive: false),
          '',
        )
        .trim();

    if (qText.isEmpty) {
      diagnostics?.add(PyqImportDiagnostic(
        severity: DiagnosticSeverity.warning,
        recordIndex: index,
        message: 'Question $questionNumber has empty prompt text, skipping',
      ));
      return null;
    }

    final options = <String>[];
    for (final m in optMatches) {
      final key = (m.group(1) ?? '').toUpperCase();
      final content = (m.group(2) ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
      options.add('($key) $content');
    }

    final ansMatch = RegExp(r'(?:Ans(?:wer)?|Correct)[\s.:-]+([A-Da-d1-4])',
            caseSensitive: false)
        .firstMatch(block);
    final correct = ansMatch?.group(1)?.toUpperCase() ?? 'A';

    final expMatch = RegExp(r'(?:Exp(?:lanation)?)[\s.:-]+(.*)$',
            caseSensitive: false, dotAll: true)
        .firstMatch(block);
    final explanation = expMatch?.group(1)?.trim();

    final sourceRef = PyqSourceReference(
      sourceId: descriptor.sourceId,
      sourceType: descriptor.sourceType.name,
      sourceTitle: descriptor.sourceName,
      sourceUrl: descriptor.uriOrPath,
      publisher: descriptor.publisher,
      retrievedAt: DateTime.now().toUtc(),
      checksum: artifactChecksum,
    );

    return RawQuestionInput(
      examId: descriptor.examId,
      year: descriptor.years.first,
      paper: 'GS1',
      questionNumber: questionNumber,
      subject: 'General Studies',
      topic: 'General',
      questionText: qText,
      options: options,
      correctAnswer: correct,
      explanation: explanation,
      language: descriptor.languages.first,
      source: sourceRef,
    );
  }
}

/// Composite parser delegating to registered parsers.
class CompositePyqParser implements PyqArtifactParser {
  final List<PyqArtifactParser> _parsers;

  const CompositePyqParser(this._parsers);

  /// Standard default composite parser with all supported formats.
  factory CompositePyqParser.defaultParsers() {
    return const CompositePyqParser([
      JsonPyqParser(),
      CsvPyqParser(),
      HtmlPyqParser(),
      TextPyqParser(),
    ]);
  }

  @override
  bool canParse(PyqSourceFormat format, String contentType) =>
      _parsers.any((p) => p.canParse(format, contentType));

  @override
  List<RawQuestionInput> parse(
    RawArtifact artifact, {
    List<PyqImportDiagnostic>? diagnostics,
  }) {
    for (final parser in _parsers) {
      if (parser.canParse(
          artifact.sourceDescriptor.format, artifact.contentType)) {
        return parser.parse(artifact, diagnostics: diagnostics);
      }
    }
    diagnostics?.add(PyqImportDiagnostic(
      severity: DiagnosticSeverity.error,
      message:
          'No parser available for format "${artifact.sourceDescriptor.format.name}" (Content-Type: ${artifact.contentType})',
    ));
    return const [];
  }
}

// ============================================================================
// 6. IMPORT JOB MODEL
// ============================================================================

/// Status of an import job.
enum ImportJobStatus {
  pending,
  inProgress,
  completed,
  partiallyCompleted,
  failed,
  skippedAlreadyProcessed,
}

/// Represents the execution lifecycle and outcome of an ingestion task.
@immutable
class PyqImportJob {
  final String jobId;
  final PyqSourceDescriptor sourceDescriptor;
  final String sourceChecksum;
  final ImportJobStatus status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int recordsRead;
  final List<NormalizedQuestion> acceptedQuestions;
  final List<NormalizedQuestion> duplicateQuestions;
  final List<PyqImportDiagnostic> diagnostics;
  final ImportQualitySummary summary;

  const PyqImportJob({
    required this.jobId,
    required this.sourceDescriptor,
    required this.sourceChecksum,
    required this.status,
    required this.startedAt,
    this.completedAt,
    required this.recordsRead,
    required this.acceptedQuestions,
    required this.duplicateQuestions,
    required this.diagnostics,
    required this.summary,
  });

  /// Factory creating a deterministic [PyqImportJob] ID.
  static String generateJobId(String sourceId, String checksum) {
    final sub = checksum.length >= 10 ? checksum.substring(0, 10) : checksum;
    return 'JOB_${sourceId}_$sub';
  }

  Map<String, dynamic> toJson() => {
        'jobId': jobId,
        'sourceDescriptor': sourceDescriptor.toJson(),
        'sourceChecksum': sourceChecksum,
        'status': status.name,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'recordsRead': recordsRead,
        'acceptedQuestions': acceptedQuestions.map((q) => q.toJson()).toList(),
        'duplicateQuestions':
            duplicateQuestions.map((q) => q.toJson()).toList(),
        'diagnostics': diagnostics.map((d) => d.toJson()).toList(),
        'summary': summary.toJson(),
      };

  factory PyqImportJob.fromJson(Map<String, dynamic> json) {
    final status = ImportJobStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => ImportJobStatus.completed,
    );
    final descriptor = PyqSourceDescriptor.fromJson(
        json['sourceDescriptor'] as Map<String, dynamic>);
    final accepted = (json['acceptedQuestions'] as List<dynamic>?)
            ?.map((q) => NormalizedQuestion.fromJson(q as Map<String, dynamic>))
            .toList() ??
        const [];
    final duplicates = (json['duplicateQuestions'] as List<dynamic>?)
            ?.map((q) => NormalizedQuestion.fromJson(q as Map<String, dynamic>))
            .toList() ??
        const [];
    final diagnostics = (json['diagnostics'] as List<dynamic>?)
            ?.map((d) => PyqImportDiagnostic(
                  severity: DiagnosticSeverity.values.firstWhere(
                    (s) => s.name == d['severity'],
                    orElse: () => DiagnosticSeverity.info,
                  ),
                  recordIndex: d['recordIndex'] as int?,
                  rawRecordId: d['rawRecordId'] as String?,
                  message: d['message'] as String? ?? '',
                  details: d['details'] as Map<String, dynamic>?,
                ))
            .toList() ??
        const [];

    final summaryMap = json['summary'] as Map<String, dynamic>;
    final summary = ImportQualitySummary(
      sourceId: summaryMap['sourceId'] as String,
      examId: summaryMap['examId'] as String,
      recordsRead: summaryMap['recordsRead'] as int,
      recordsAccepted: summaryMap['recordsAccepted'] as int,
      recordsDuplicate: summaryMap['recordsDuplicate'] as int,
      recordsMalformed: summaryMap['recordsMalformed'] as int,
      recordsUnmapped: summaryMap['recordsUnmapped'] as int,
      acceptanceRate: (summaryMap['acceptanceRate'] as num).toDouble(),
      processingTimeMs: summaryMap['processingTimeMs'] as int,
      provenanceCompleteRate:
          (summaryMap['provenanceCompleteRate'] as num).toDouble(),
    );

    return PyqImportJob(
      jobId: json['jobId'] as String,
      sourceDescriptor: descriptor,
      sourceChecksum: json['sourceChecksum'] as String,
      status: status,
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      recordsRead: json['recordsRead'] as int,
      acceptedQuestions: accepted,
      duplicateQuestions: duplicates,
      diagnostics: diagnostics,
      summary: summary,
    );
  }

  @override
  String toString() =>
      'PyqImportJob($jobId, status: ${status.name}, accepted: ${acceptedQuestions.length}, duplicates: ${duplicateQuestions.length})';
}

// ============================================================================
// 7. HIGH-LEVEL ACQUISITION & INGESTION ENGINE
// ============================================================================

/// Production-grade Acquisition and Ingestion Orchestrator for Project TITAN.
class MultiExamPyqAcquisitionEngine {
  final PyqSourceFetcher fetcher;
  final PyqArtifactParser parser;
  final MultiExamPyqIntelligenceService intelligenceService;

  final Map<String, PyqImportJob> _completedJobsBySourceId = {};
  final Map<String, String> _processedChecksums = {};
  final List<PyqImportJob> _jobHistory = [];

  MultiExamPyqAcquisitionEngine({
    PyqSourceFetcher? fetcher,
    PyqArtifactParser? parser,
    MultiExamPyqIntelligenceService? intelligenceService,
  })  : fetcher = fetcher ?? InMemorySourceFetcher(),
        parser = parser ?? CompositePyqParser.defaultParsers(),
        intelligenceService =
            intelligenceService ?? MultiExamPyqIntelligenceService();

  List<PyqImportJob> get jobHistory => List.unmodifiable(_jobHistory);

  int get totalQuestionsCount => intelligenceService.totalQuestionsCount;

  /// Ingests a single source via its [PyqSourceDescriptor].
  Future<PyqImportJob> ingestSource(
    PyqSourceDescriptor descriptor, {
    bool forceReingest = false,
  }) async {
    descriptor.validate();
    final startTime = DateTime.now();

    final artifact = await fetcher.fetch(descriptor);

    final existingChecksum = _processedChecksums[descriptor.sourceId];
    if (!forceReingest &&
        existingChecksum != null &&
        existingChecksum == artifact.checksum &&
        _completedJobsBySourceId.containsKey(descriptor.sourceId)) {
      final cachedJob = _completedJobsBySourceId[descriptor.sourceId]!;
      final skippedJob = PyqImportJob(
        jobId: cachedJob.jobId,
        sourceDescriptor: descriptor,
        sourceChecksum: artifact.checksum,
        status: ImportJobStatus.skippedAlreadyProcessed,
        startedAt: startTime,
        completedAt: DateTime.now(),
        recordsRead: cachedJob.recordsRead,
        acceptedQuestions: cachedJob.acceptedQuestions,
        duplicateQuestions: cachedJob.duplicateQuestions,
        diagnostics: [
          PyqImportDiagnostic(
            severity: DiagnosticSeverity.info,
            message:
                'Source "${descriptor.sourceId}" with checksum ${artifact.checksum.substring(0, 8)} already processed. Skipped redundant ingestion.',
          ),
        ],
        summary: cachedJob.summary,
      );
      _jobHistory.add(skippedJob);
      return skippedJob;
    }

    return _processArtifactInternal(artifact, startTime);
  }

  /// Ingests multiple sources sequentially.
  Future<List<PyqImportJob>> ingestSources(
    List<PyqSourceDescriptor> descriptors, {
    bool forceReingest = false,
  }) async {
    final jobs = <PyqImportJob>[];
    for (final d in descriptors) {
      jobs.add(await ingestSource(d, forceReingest: forceReingest));
    }
    return jobs;
  }

  /// Ingests an existing [RawArtifact] directly without fetcher invocation.
  PyqImportJob ingestArtifact(
    RawArtifact artifact, {
    bool forceReingest = false,
  }) {
    final startTime = DateTime.now();
    final descriptor = artifact.sourceDescriptor;

    if (!forceReingest &&
        _processedChecksums[descriptor.sourceId] == artifact.checksum &&
        _completedJobsBySourceId.containsKey(descriptor.sourceId)) {
      final cachedJob = _completedJobsBySourceId[descriptor.sourceId]!;
      return PyqImportJob(
        jobId: cachedJob.jobId,
        sourceDescriptor: descriptor,
        sourceChecksum: artifact.checksum,
        status: ImportJobStatus.skippedAlreadyProcessed,
        startedAt: startTime,
        completedAt: DateTime.now(),
        recordsRead: cachedJob.recordsRead,
        acceptedQuestions: cachedJob.acceptedQuestions,
        duplicateQuestions: cachedJob.duplicateQuestions,
        diagnostics: cachedJob.diagnostics,
        summary: cachedJob.summary,
      );
    }

    return _processArtifactInternal(artifact, startTime);
  }

  PyqImportJob _processArtifactInternal(
      RawArtifact artifact, DateTime startTime) {
    final diagnostics = <PyqImportDiagnostic>[];
    final descriptor = artifact.sourceDescriptor;

    // 1. Parse artifact into RawQuestionInput records
    final rawInputs = parser.parse(artifact, diagnostics: diagnostics);
    final recordsRead = rawInputs.length;

    // 2. Normalization & Provenance validation
    final normalizedBatch = <NormalizedQuestion>[];
    int malformedCount = 0;
    int unmappedCount = 0;

    final fallbackSource = PyqSourceReference(
      sourceId: descriptor.sourceId,
      sourceType: descriptor.sourceType.name,
      sourceTitle: descriptor.sourceName,
      sourceUrl: descriptor.uriOrPath,
      publisher: descriptor.publisher,
      retrievedAt: DateTime.now().toUtc(),
      checksum: artifact.checksum,
    );

    for (var i = 0; i < rawInputs.length; i++) {
      final input = rawInputs[i];
      try {
        final normalized = PyqNormalizationPipeline.normalize(
          input,
          fallbackSource: fallbackSource,
        );

        if (normalized.objectiveIds.isEmpty) {
          unmappedCount++;
        }

        normalizedBatch.add(normalized);
      } catch (e) {
        malformedCount++;
        diagnostics.add(PyqImportDiagnostic(
          severity: DiagnosticSeverity.warning,
          recordIndex: i,
          message: 'Failed to normalize record $i: $e',
        ));
      }
    }

    // 3. P29 Deduplication with existing service corpus
    final existingCorpus =
        intelligenceService.getQuestions(const PyqFilterCriteria());
    final dupResult = DeterministicDuplicateDetector.filterDuplicates(
      existingCorpus: existingCorpus,
      incoming: normalizedBatch,
    );

    // 4. Ingest accepted unique questions into P29 Intelligence Service
    final acceptedInputs = <RawQuestionInput>[];
    final acceptedIds = dupResult.uniqueQuestions.map((q) => q.id).toSet();

    for (var i = 0; i < rawInputs.length; i++) {
      final input = rawInputs[i];
      final normText =
          PyqNormalizationPipeline.normalizeQuestionText(input.questionText);
      final normalizedId = input.rawId?.trim().isNotEmpty == true
          ? input.rawId!.trim()
          : DeterministicQuestionId.generate(
              examId: input.examId,
              year: input.year,
              paper: input.paper,
              normalizedQuestionText: normText,
              language: input.language ?? 'en',
              questionNumber: input.questionNumber,
            );
      if (acceptedIds.contains(normalizedId)) {
        acceptedInputs.add(input);
      }
    }

    if (acceptedInputs.isNotEmpty) {
      intelligenceService.ingestRawQuestions(acceptedInputs);
    }

    final endTime = DateTime.now();
    final durationMs = endTime.difference(startTime).inMilliseconds;

    // 5. Calculate provenance completeness
    final provenanceWithChecksum = dupResult.uniqueQuestions
        .where(
          (q) => q.source.checksum.isNotEmpty,
        )
        .length;
    final provRate = dupResult.uniqueQuestions.isNotEmpty
        ? provenanceWithChecksum / dupResult.uniqueQuestions.length
        : 1.0;

    final acceptanceRate =
        recordsRead > 0 ? dupResult.uniqueQuestions.length / recordsRead : 0.0;

    // Total malformed records includes normalization failures and parser-skipped items
    final totalSkippedOrMalformed = malformedCount +
        diagnostics
            .where((d) =>
                d.severity == DiagnosticSeverity.warning ||
                d.severity == DiagnosticSeverity.error)
            .length;

    // 6. Build Quality Summary
    final summary = ImportQualitySummary(
      sourceId: descriptor.sourceId,
      examId: descriptor.examId,
      recordsRead: recordsRead,
      recordsAccepted: dupResult.uniqueQuestions.length,
      recordsDuplicate: dupResult.duplicates.length,
      recordsMalformed: totalSkippedOrMalformed,
      recordsUnmapped: unmappedCount,
      acceptanceRate: acceptanceRate,
      processingTimeMs: durationMs,
      provenanceCompleteRate: provRate,
    );

    // 7. Determine Job Status
    ImportJobStatus status;
    if (totalSkippedOrMalformed > 0 && dupResult.uniqueQuestions.isNotEmpty) {
      status = ImportJobStatus.partiallyCompleted;
    } else if (recordsRead > 0 &&
        dupResult.uniqueQuestions.isEmpty &&
        totalSkippedOrMalformed == recordsRead) {
      status = ImportJobStatus.failed;
    } else {
      status = ImportJobStatus.completed;
    }

    final jobId =
        PyqImportJob.generateJobId(descriptor.sourceId, artifact.checksum);

    final job = PyqImportJob(
      jobId: jobId,
      sourceDescriptor: descriptor,
      sourceChecksum: artifact.checksum,
      status: status,
      startedAt: startTime,
      completedAt: endTime,
      recordsRead: recordsRead,
      acceptedQuestions: dupResult.uniqueQuestions,
      duplicateQuestions: dupResult.duplicates.map((d) => d.duplicate).toList(),
      diagnostics: diagnostics,
      summary: summary,
    );

    _completedJobsBySourceId[descriptor.sourceId] = job;
    _processedChecksums[descriptor.sourceId] = artifact.checksum;
    _jobHistory.add(job);

    return job;
  }

  /// Exports engine state, job history, and underlying intelligence corpus for restart persistence.
  Map<String, dynamic> exportSnapshot() {
    return {
      'version': 'TITAN-P30-v1',
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'completedJobs':
          _completedJobsBySourceId.map((k, v) => MapEntry(k, v.toJson())),
      'processedChecksums': _processedChecksums,
      'jobHistory': _jobHistory.map((j) => j.toJson()).toList(),
      'intelligenceService': intelligenceService.exportSnapshot(),
    };
  }

  /// Restores complete engine state and underlying intelligence corpus across application restarts.
  void restoreSnapshot(Map<String, dynamic> json) {
    _completedJobsBySourceId.clear();
    _processedChecksums.clear();
    _jobHistory.clear();

    if (json.containsKey('completedJobs')) {
      final jobsMap = json['completedJobs'] as Map<String, dynamic>;
      for (final entry in jobsMap.entries) {
        _completedJobsBySourceId[entry.key] =
            PyqImportJob.fromJson(entry.value as Map<String, dynamic>);
      }
    }

    if (json.containsKey('processedChecksums')) {
      final checkMap = json['processedChecksums'] as Map<String, dynamic>;
      for (final entry in checkMap.entries) {
        _processedChecksums[entry.key] = entry.value.toString();
      }
    }

    if (json.containsKey('jobHistory')) {
      final historyList = json['jobHistory'] as List<dynamic>;
      for (final j in historyList) {
        _jobHistory.add(PyqImportJob.fromJson(j as Map<String, dynamic>));
      }
    }

    if (json.containsKey('intelligenceService')) {
      intelligenceService.restoreSnapshot(
        json['intelligenceService'] as Map<String, dynamic>,
      );
    }
  }

  void clear() {
    _completedJobsBySourceId.clear();
    _processedChecksums.clear();
    _jobHistory.clear();
    intelligenceService.clear();
  }
}

// ============================================================================
// 8. EXTENSION HELPERS
// ============================================================================

extension StringEmptyFallback on String {
  String ifEmptyThen(String fallback) => trim().isEmpty ? fallback : this;
}
