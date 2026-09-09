/// Academic Transcript Domain Entities (TITAN-KO-051.0 P51).
///
/// Production domain models representing official institutional academic transcripts,
/// deterministic sorting, immutable versioning lifecycle (DRAFT, OFFICIAL, REISSUED, VOID),
/// and audit linkages.
library;

import 'package:meta/meta.dart';

/// Minimal immutable lifecycle status for an academic transcript.
enum TranscriptStatus {
  /// Internal or provisional transcript, not externally authoritative.
  draft,

  /// Valid, official institutional transcript.
  official,

  /// Historically valid transcript that has been superseded by a newer official revision.
  reissued,

  /// Formally voided or invalidated transcript.
  voidRecord,
}

/// Single assessment outcome entry represented on an official academic transcript.
@immutable
class TranscriptAssessmentEntry {
  /// Canonical assessment identifier.
  final String assessmentId;

  /// Human-readable title of the assessment.
  final String assessmentTitle;

  /// Official final score achieved.
  final double score;

  /// Maximum possible marks.
  final double maxScore;

  /// Calculated percentage.
  final double percentage;

  /// Official letter grade symbol.
  final String letterGrade;

  /// Whether the score satisfies institutional passing criteria.
  final bool isPassed;

  /// Whether this score resulted from an administrative or pedagogical override.
  final bool isOverridden;

  /// Date when the underlying grade was published.
  final DateTime? publishedAt;

  const TranscriptAssessmentEntry({
    required this.assessmentId,
    required this.assessmentTitle,
    required this.score,
    required this.maxScore,
    required this.percentage,
    required this.letterGrade,
    required this.isPassed,
    this.isOverridden = false,
    this.publishedAt,
  });

  Map<String, dynamic> toJson() => {
        'assessmentId': assessmentId,
        'assessmentTitle': assessmentTitle,
        'score': score,
        'maxScore': maxScore,
        'percentage': percentage,
        'letterGrade': letterGrade,
        'isPassed': isPassed,
        'isOverridden': isOverridden,
        if (publishedAt != null) 'publishedAt': publishedAt!.toIso8601String(),
      };

  factory TranscriptAssessmentEntry.fromJson(Map<String, dynamic> json) =>
      TranscriptAssessmentEntry(
        assessmentId: json['assessmentId'] as String? ?? '',
        assessmentTitle: json['assessmentTitle'] as String? ?? '',
        score: (json['score'] as num?)?.toDouble() ?? 0.0,
        maxScore: (json['maxScore'] as num?)?.toDouble() ?? 100.0,
        percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
        letterGrade: json['letterGrade'] as String? ?? 'F',
        isPassed: json['isPassed'] as bool? ?? false,
        isOverridden: json['isOverridden'] as bool? ?? false,
        publishedAt: json['publishedAt'] != null
            ? DateTime.parse(json['publishedAt'] as String).toUtc()
            : null,
      );
}

/// Authoritative academic transcript document.
///
/// Implements deterministic generation, strict immutability upon issuance,
/// and explicit versioning.
@immutable
class AcademicTranscript {
  /// Unique canonical transcript identifier (e.g. 'tr_cohort1_learner1_v1').
  final String transcriptId;

  /// Sequential revision version (starts at 1).
  final int version;

  /// Multi-tenant identifier.
  final String tenantId;

  /// Target learner identifier.
  final String learnerId;

  /// Formal issuing institution name.
  final String institutionName;

  /// Academic program or course title.
  final String? programName;

  /// Associated cohort identifier.
  final String? cohortId;

  /// Academic period/term identifier.
  final String? academicPeriod;

  /// Current lifecycle status.
  final TranscriptStatus status;

  /// Stably and deterministically ordered assessment entries.
  final List<TranscriptAssessmentEntry> entries;

  /// Aggregated overall percentage across official assessments.
  final double overallPercentage;

  /// Aggregated overall letter grade.
  final String overallGrade;

  /// Overall program/cohort completion status.
  final bool isCompleted;

  /// UTC issuance timestamp.
  final DateTime issuedAt;

  /// Identifier of the authorized faculty/admin actor who issued this transcript.
  final String issuedByFacultyId;

  /// If this transcript reissued an earlier version, the predecessor ID.
  final String? reissuedFromTranscriptId;

  /// If this transcript was superseded by a newer version, the successor ID.
  final String? supersededByTranscriptId;

  /// If voided, the mandatory administrative justification.
  final String? voidReason;

  /// UTC void timestamp.
  final DateTime? voidAt;

  /// Identifier of actor who voided this record.
  final String? voidByFacultyId;

  /// Academic credits if the domain defines credits (null if credit model unavailable).
  final double? credits;

  /// Extensible metadata.
  final Map<String, dynamic> metadata;

  AcademicTranscript({
    required this.transcriptId,
    this.version = 1,
    this.tenantId = 'default_tenant',
    required this.learnerId,
    this.institutionName = 'QuizForge Institute of Technology',
    this.programName,
    this.cohortId,
    this.academicPeriod,
    this.status = TranscriptStatus.official,
    required List<TranscriptAssessmentEntry> entries,
    required this.overallPercentage,
    required this.overallGrade,
    this.isCompleted = false,
    DateTime? issuedAt,
    required this.issuedByFacultyId,
    this.reissuedFromTranscriptId,
    this.supersededByTranscriptId,
    this.voidReason,
    this.voidAt,
    this.voidByFacultyId,
    this.credits,
    Map<String, dynamic>? metadata,
  })  : issuedAt = (issuedAt ?? DateTime.now()).toUtc(),
        // Deterministic stable sorting by assessmentId
        entries = List<TranscriptAssessmentEntry>.unmodifiable(
          List<TranscriptAssessmentEntry>.from(entries)
            ..sort((a, b) => a.assessmentId.compareTo(b.assessmentId)),
        ),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {}) {
    if (transcriptId.trim().isEmpty) {
      throw ArgumentError('transcriptId cannot be empty');
    }
    if (version < 1) {
      throw ArgumentError('version must be at least 1');
    }
    if (tenantId.trim().isEmpty) {
      throw ArgumentError('tenantId cannot be empty');
    }
    if (learnerId.trim().isEmpty) {
      throw ArgumentError('learnerId cannot be empty');
    }
    if (issuedByFacultyId.trim().isEmpty) {
      throw ArgumentError('issuedByFacultyId cannot be empty');
    }
  }

  bool get isOfficial => status == TranscriptStatus.official;
  bool get isReissued => status == TranscriptStatus.reissued;
  bool get isVoid => status == TranscriptStatus.voidRecord;
  bool get isDraft => status == TranscriptStatus.draft;

  /// Generates a standard canonical transcript ID.
  static String generateId({
    required String cohortId,
    required String learnerId,
    required int version,
  }) =>
      'tr_${cohortId.trim()}_${learnerId.trim()}_v$version';

  /// Marks this transcript as reissued (superseded by a newer revision).
  AcademicTranscript markReissued({
    required String supersededByTranscriptId,
    DateTime? reissuedAt,
  }) {
    return copyWith(
      status: TranscriptStatus.reissued,
      supersededByTranscriptId: supersededByTranscriptId.trim(),
    );
  }

  /// Marks this transcript as void with mandatory justification.
  AcademicTranscript markVoid({
    required String voidByFacultyId,
    required String reason,
    DateTime? voidAt,
  }) {
    final cleanReason = reason.trim();
    if (cleanReason.isEmpty) {
      throw ArgumentError('Void reason cannot be empty');
    }
    return copyWith(
      status: TranscriptStatus.voidRecord,
      voidReason: cleanReason,
      voidByFacultyId: voidByFacultyId.trim(),
      voidAt: (voidAt ?? DateTime.now()).toUtc(),
    );
  }

  AcademicTranscript copyWith({
    String? transcriptId,
    int? version,
    String? tenantId,
    String? learnerId,
    String? institutionName,
    String? programName,
    String? cohortId,
    String? academicPeriod,
    TranscriptStatus? status,
    List<TranscriptAssessmentEntry>? entries,
    double? overallPercentage,
    String? overallGrade,
    bool? isCompleted,
    DateTime? issuedAt,
    String? issuedByFacultyId,
    String? reissuedFromTranscriptId,
    String? supersededByTranscriptId,
    String? voidReason,
    DateTime? voidAt,
    String? voidByFacultyId,
    double? credits,
    Map<String, dynamic>? metadata,
  }) {
    return AcademicTranscript(
      transcriptId: transcriptId ?? this.transcriptId,
      version: version ?? this.version,
      tenantId: tenantId ?? this.tenantId,
      learnerId: learnerId ?? this.learnerId,
      institutionName: institutionName ?? this.institutionName,
      programName: programName ?? this.programName,
      cohortId: cohortId ?? this.cohortId,
      academicPeriod: academicPeriod ?? this.academicPeriod,
      status: status ?? this.status,
      entries: entries ?? this.entries,
      overallPercentage: overallPercentage ?? this.overallPercentage,
      overallGrade: overallGrade ?? this.overallGrade,
      isCompleted: isCompleted ?? this.isCompleted,
      issuedAt: issuedAt ?? this.issuedAt,
      issuedByFacultyId: issuedByFacultyId ?? this.issuedByFacultyId,
      reissuedFromTranscriptId:
          reissuedFromTranscriptId ?? this.reissuedFromTranscriptId,
      supersededByTranscriptId:
          supersededByTranscriptId ?? this.supersededByTranscriptId,
      voidReason: voidReason ?? this.voidReason,
      voidAt: voidAt ?? this.voidAt,
      voidByFacultyId: voidByFacultyId ?? this.voidByFacultyId,
      credits: credits ?? this.credits,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'transcriptId': transcriptId,
        'version': version,
        'tenantId': tenantId,
        'learnerId': learnerId,
        'institutionName': institutionName,
        if (programName != null) 'programName': programName,
        if (cohortId != null) 'cohortId': cohortId,
        if (academicPeriod != null) 'academicPeriod': academicPeriod,
        'status': status.name,
        'entries': entries.map((e) => e.toJson()).toList(),
        'overallPercentage': overallPercentage,
        'overallGrade': overallGrade,
        'isCompleted': isCompleted,
        'issuedAt': issuedAt.toIso8601String(),
        'issuedByFacultyId': issuedByFacultyId,
        if (reissuedFromTranscriptId != null)
          'reissuedFromTranscriptId': reissuedFromTranscriptId,
        if (supersededByTranscriptId != null)
          'supersededByTranscriptId': supersededByTranscriptId,
        if (voidReason != null) 'voidReason': voidReason,
        if (voidAt != null) 'voidAt': voidAt!.toIso8601String(),
        if (voidByFacultyId != null) 'voidByFacultyId': voidByFacultyId,
        if (credits != null) 'credits': credits,
        'metadata': metadata,
      };

  factory AcademicTranscript.fromJson(Map<String, dynamic> json) =>
      AcademicTranscript(
        transcriptId: json['transcriptId'] as String? ?? '',
        version: (json['version'] as num?)?.toInt() ?? 1,
        tenantId: json['tenantId'] as String? ?? 'default_tenant',
        learnerId: json['learnerId'] as String? ?? '',
        institutionName: json['institutionName'] as String? ??
            'QuizForge Institute of Technology',
        programName: json['programName'] as String?,
        cohortId: json['cohortId'] as String?,
        academicPeriod: json['academicPeriod'] as String?,
        status: TranscriptStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => TranscriptStatus.official,
        ),
        entries: (json['entries'] as List<dynamic>?)
                ?.map((e) => TranscriptAssessmentEntry.fromJson(
                    e as Map<String, dynamic>))
                .toList() ??
            const [],
        overallPercentage:
            (json['overallPercentage'] as num?)?.toDouble() ?? 0.0,
        overallGrade: json['overallGrade'] as String? ?? 'F',
        isCompleted: json['isCompleted'] as bool? ?? false,
        issuedAt: json['issuedAt'] != null
            ? DateTime.parse(json['issuedAt'] as String).toUtc()
            : null,
        issuedByFacultyId: json['issuedByFacultyId'] as String? ?? '',
        reissuedFromTranscriptId: json['reissuedFromTranscriptId'] as String?,
        supersededByTranscriptId: json['supersededByTranscriptId'] as String?,
        voidReason: json['voidReason'] as String?,
        voidAt: json['voidAt'] != null
            ? DateTime.parse(json['voidAt'] as String).toUtc()
            : null,
        voidByFacultyId: json['voidByFacultyId'] as String?,
        credits: (json['credits'] as num?)?.toDouble(),
        metadata: Map<String, dynamic>.from(
            json['metadata'] as Map? ?? const <String, dynamic>{}),
      );
}
