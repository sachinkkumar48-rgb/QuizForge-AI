/// Multi-Exam PYQ Historical Intelligence Engine (Project TITAN - P31).
///
/// Provides deterministic, learner-independent historical analysis:
/// 1. Exam Intelligence Profile (comprehensive exam summary).
/// 2. Subject Weightage (historical representation percentages).
/// 3. Topic Weightage (filterable, ranked topic statistics).
/// 4. Objective Coverage (curriculum coverage analysis).
/// 5. Year Distribution (year-level breakdowns with subject/topic detail).
/// 6. Year-over-Year Trend (absolute/percentage change).
/// 7. Recency Analysis (explicit caller-supplied windows).
/// 8. Recurrence Analysis (multi-year topic/objective profiles).
/// 9. Cross-Exam Comparison (deterministic side-by-side comparison).
/// 10. Corpus Quality (metadata completeness, mapping coverage).
/// 11. Evidence Thresholds (avoids misleading conclusions from tiny datasets).
///
/// Invariants:
/// - Pure corpus intelligence — zero learner mastery inference.
/// - Never makes predictions ("will appear", "likely to appear").
/// - No DateTime.now() — all windows are caller-supplied.
/// - Deterministic: identical inputs always produce identical outputs.
/// - Safe for empty/sparse corpora: no NaN, no Infinity, no fabricated stats.
/// - Explicit stable sort ordering with documented tie-breakers.
library;

import 'dart:math' as math;

import 'package:meta/meta.dart';

import '../multi_exam/multi_exam_pyq_intelligence.dart';

// ============================================================================
// 1. WEIGHTED DISTRIBUTION ENTRY
// ============================================================================

/// A single entry in a ranked distribution (subject, topic, paper, language).
@immutable
class WeightageEntry {
  /// The category identifier (e.g. subject name, topic name).
  final String category;

  /// Absolute question count.
  final int count;

  /// Percentage share of the total (0.0–100.0). Zero when total is zero.
  final double percentage;

  /// 1-based rank. Ties share the same rank.
  final int rank;

  const WeightageEntry({
    required this.category,
    required this.count,
    required this.percentage,
    required this.rank,
  });

  Map<String, dynamic> toJson() => {
        'category': category,
        'count': count,
        'percentage': percentage,
        'rank': rank,
      };
}

// ============================================================================
// 2. SUBJECT WEIGHTAGE
// ============================================================================

/// Historical subject representation across the corpus.
@immutable
class SubjectWeightage {
  final int totalQuestions;
  final List<WeightageEntry> entries;

  const SubjectWeightage({
    required this.totalQuestions,
    required this.entries,
  });

  Map<String, dynamic> toJson() => {
        'totalQuestions': totalQuestions,
        'entries': entries.map((e) => e.toJson()).toList(),
      };
}

// ============================================================================
// 3. TOPIC WEIGHTAGE
// ============================================================================

/// Filterable topic weightage with optional exam/year/subject scoping.
@immutable
class TopicWeightage {
  final int totalQuestions;
  final String? examFilter;
  final int? startYearFilter;
  final int? endYearFilter;
  final String? subjectFilter;
  final String? paperFilter;
  final List<WeightageEntry> entries;

  const TopicWeightage({
    required this.totalQuestions,
    this.examFilter,
    this.startYearFilter,
    this.endYearFilter,
    this.subjectFilter,
    this.paperFilter,
    required this.entries,
  });

  Map<String, dynamic> toJson() => {
        'totalQuestions': totalQuestions,
        'examFilter': examFilter,
        'startYearFilter': startYearFilter,
        'endYearFilter': endYearFilter,
        'subjectFilter': subjectFilter,
        'paperFilter': paperFilter,
        'entries': entries.map((e) => e.toJson()).toList(),
      };
}

// ============================================================================
// 4. OBJECTIVE COVERAGE
// ============================================================================

/// Coverage profile for a single curriculum objective.
@immutable
class ObjectiveCoverageEntry {
  final String objectiveId;
  final int questionCount;
  final double percentage;
  final List<int> yearsRepresented;
  final List<String> subjectsRepresented;

  const ObjectiveCoverageEntry({
    required this.objectiveId,
    required this.questionCount,
    required this.percentage,
    required this.yearsRepresented,
    required this.subjectsRepresented,
  });

  Map<String, dynamic> toJson() => {
        'objectiveId': objectiveId,
        'questionCount': questionCount,
        'percentage': percentage,
        'yearsRepresented': yearsRepresented,
        'subjectsRepresented': subjectsRepresented,
      };
}

/// Aggregate objective coverage report.
@immutable
class ObjectiveCoverageReport {
  final int totalQuestions;
  final int mappedQuestions;
  final double mappingCoveragePercentage;
  final List<ObjectiveCoverageEntry> coveredObjectives;
  final List<String> uncoveredObjectiveIds;

  const ObjectiveCoverageReport({
    required this.totalQuestions,
    required this.mappedQuestions,
    required this.mappingCoveragePercentage,
    required this.coveredObjectives,
    required this.uncoveredObjectiveIds,
  });

  Map<String, dynamic> toJson() => {
        'totalQuestions': totalQuestions,
        'mappedQuestions': mappedQuestions,
        'mappingCoveragePercentage': mappingCoveragePercentage,
        'coveredObjectives': coveredObjectives.map((e) => e.toJson()).toList(),
        'uncoveredObjectiveIds': uncoveredObjectiveIds,
      };
}

// ============================================================================
// 5. YEAR DISTRIBUTION
// ============================================================================

/// Year-level distribution detail.
@immutable
class YearDistributionEntry {
  final int year;
  final int questionCount;
  final Map<String, int> subjectDistribution;
  final Map<String, int> topicDistribution;

  const YearDistributionEntry({
    required this.year,
    required this.questionCount,
    required this.subjectDistribution,
    required this.topicDistribution,
  });

  Map<String, dynamic> toJson() => {
        'year': year,
        'questionCount': questionCount,
        'subjectDistribution': subjectDistribution,
        'topicDistribution': topicDistribution,
      };
}

/// Year distribution report supporting arbitrary year ranges.
@immutable
class YearDistributionReport {
  final int totalQuestions;
  final int? startYear;
  final int? endYear;
  final List<YearDistributionEntry> entries;

  const YearDistributionReport({
    required this.totalQuestions,
    this.startYear,
    this.endYear,
    required this.entries,
  });

  Map<String, dynamic> toJson() => {
        'totalQuestions': totalQuestions,
        'startYear': startYear,
        'endYear': endYear,
        'entries': entries.map((e) => e.toJson()).toList(),
      };
}

// ============================================================================
// 6. YEAR-OVER-YEAR TREND
// ============================================================================

/// Trend data point for a single category (topic or objective) across years.
@immutable
class YearOverYearTrendEntry {
  final String category;
  final Map<int, int> yearCounts;
  final int totalCount;

  /// Year-over-year absolute changes (year -> change from previous year).
  /// First observed year has change of 0.
  final Map<int, int> absoluteChanges;

  /// Year-over-year percentage changes (year -> % change from previous year).
  /// First observed year has change of 0.0.
  /// Division-safe: if previous year count was 0, percentage change is 0.0.
  final Map<int, double> percentageChanges;

  /// Number of distinct years with at least one question.
  final int multiYearFrequency;

  const YearOverYearTrendEntry({
    required this.category,
    required this.yearCounts,
    required this.totalCount,
    required this.absoluteChanges,
    required this.percentageChanges,
    required this.multiYearFrequency,
  });

  Map<String, dynamic> toJson() => {
        'category': category,
        'yearCounts': yearCounts.map((k, v) => MapEntry(k.toString(), v)),
        'totalCount': totalCount,
        'absoluteChanges':
            absoluteChanges.map((k, v) => MapEntry(k.toString(), v)),
        'percentageChanges':
            percentageChanges.map((k, v) => MapEntry(k.toString(), v)),
        'multiYearFrequency': multiYearFrequency,
      };
}

// ============================================================================
// 7. RECENCY ANALYSIS
// ============================================================================

/// Recency analysis using explicit caller-supplied windows.
@immutable
class RecencyAnalysis {
  final String category;
  final int recentCount;
  final int historicalCount;

  /// Share of recent questions as a proportion of total (0.0–1.0).
  /// Zero when total is zero.
  final double recentShare;

  final int windowStartYear;
  final int windowEndYear;

  const RecencyAnalysis({
    required this.category,
    required this.recentCount,
    required this.historicalCount,
    required this.recentShare,
    required this.windowStartYear,
    required this.windowEndYear,
  });

  int get totalCount => recentCount + historicalCount;

  Map<String, dynamic> toJson() => {
        'category': category,
        'recentCount': recentCount,
        'historicalCount': historicalCount,
        'recentShare': recentShare,
        'windowStartYear': windowStartYear,
        'windowEndYear': windowEndYear,
        'totalCount': totalCount,
      };
}

// ============================================================================
// 8. RECURRENCE ANALYSIS
// ============================================================================

/// Profile for a recurring topic/objective across multiple years.
@immutable
class RecurringProfile {
  final String id;
  final List<int> yearsPresent;
  final int yearCount;
  final int questionCount;
  final int firstYear;
  final int lastYear;

  const RecurringProfile({
    required this.id,
    required this.yearsPresent,
    required this.yearCount,
    required this.questionCount,
    required this.firstYear,
    required this.lastYear,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'yearsPresent': yearsPresent,
        'yearCount': yearCount,
        'questionCount': questionCount,
        'firstYear': firstYear,
        'lastYear': lastYear,
      };
}

// ============================================================================
// 9. CROSS-EXAM COMPARISON
// ============================================================================

/// Side-by-side exam intelligence comparison.
@immutable
class ExamComparisonEntry {
  final String examId;
  final int corpusSize;
  final int yearCoverage;
  final int? minYear;
  final int? maxYear;
  final Map<String, int> subjectDistribution;
  final Map<String, int> topicDistribution;
  final int objectivesCovered;
  final Map<String, int> languageDistribution;

  const ExamComparisonEntry({
    required this.examId,
    required this.corpusSize,
    required this.yearCoverage,
    this.minYear,
    this.maxYear,
    required this.subjectDistribution,
    required this.topicDistribution,
    required this.objectivesCovered,
    required this.languageDistribution,
  });

  Map<String, dynamic> toJson() => {
        'examId': examId,
        'corpusSize': corpusSize,
        'yearCoverage': yearCoverage,
        'minYear': minYear,
        'maxYear': maxYear,
        'subjectDistribution': subjectDistribution,
        'topicDistribution': topicDistribution,
        'objectivesCovered': objectivesCovered,
        'languageDistribution': languageDistribution,
      };
}

/// Cross-exam comparison report.
@immutable
class CrossExamComparison {
  final String examIdA;
  final String examIdB;
  final ExamComparisonEntry entryA;
  final ExamComparisonEntry entryB;

  const CrossExamComparison({
    required this.examIdA,
    required this.examIdB,
    required this.entryA,
    required this.entryB,
  });

  Map<String, dynamic> toJson() => {
        'examIdA': examIdA,
        'examIdB': examIdB,
        'entryA': entryA.toJson(),
        'entryB': entryB.toJson(),
      };
}

// ============================================================================
// 10. CORPUS QUALITY PROFILE
// ============================================================================

/// Dataset quality metrics (NOT learner scores).
@immutable
class CorpusQualityProfile {
  final int totalQuestions;

  /// Fraction of questions with non-default subject (0.0–1.0).
  final double subjectCompleteness;

  /// Fraction of questions with non-empty topic (0.0–1.0).
  final double topicCompleteness;

  /// Fraction of questions with at least one objective mapping (0.0–1.0).
  final double objectiveMappingCoverage;

  /// Fraction of questions with topic != 'General' (0.0–1.0).
  final double topicMappingCoverage;

  /// Fraction of questions with valid year > 0 (0.0–1.0).
  final double yearCoverage;

  /// Fraction of questions with non-empty source provenance (0.0–1.0).
  final double provenanceCoverage;

  /// Fraction of duplicate questions detected during ingestion (0.0–1.0).
  final double duplicateRatio;

  const CorpusQualityProfile({
    required this.totalQuestions,
    required this.subjectCompleteness,
    required this.topicCompleteness,
    required this.objectiveMappingCoverage,
    required this.topicMappingCoverage,
    required this.yearCoverage,
    required this.provenanceCoverage,
    required this.duplicateRatio,
  });

  Map<String, dynamic> toJson() => {
        'totalQuestions': totalQuestions,
        'subjectCompleteness': subjectCompleteness,
        'topicCompleteness': topicCompleteness,
        'objectiveMappingCoverage': objectiveMappingCoverage,
        'topicMappingCoverage': topicMappingCoverage,
        'yearCoverage': yearCoverage,
        'provenanceCoverage': provenanceCoverage,
        'duplicateRatio': duplicateRatio,
      };
}

// ============================================================================
// 11. EVIDENCE THRESHOLDS
// ============================================================================

/// Configurable evidence thresholds to avoid misleading conclusions
/// from tiny datasets.
///
/// Documented thresholds:
/// - [minimumQuestionsForWeightage]: Minimum corpus size to produce
///   meaningful percentage-based weightage (default: 5).
/// - [minimumYearsForTrend]: Minimum distinct years needed for
///   year-over-year trend analysis (default: 2).
/// - [minimumQuestionsForRecurrence]: Minimum questions for a
///   topic/objective to be considered "recurring" (default: 2).
@immutable
class EvidenceThresholds {
  final int minimumQuestionsForWeightage;
  final int minimumYearsForTrend;
  final int minimumQuestionsForRecurrence;

  const EvidenceThresholds({
    this.minimumQuestionsForWeightage = 5,
    this.minimumYearsForTrend = 2,
    this.minimumQuestionsForRecurrence = 2,
  });

  Map<String, dynamic> toJson() => {
        'minimumQuestionsForWeightage': minimumQuestionsForWeightage,
        'minimumYearsForTrend': minimumYearsForTrend,
        'minimumQuestionsForRecurrence': minimumQuestionsForRecurrence,
      };
}

// ============================================================================
// 12. EXAM INTELLIGENCE PROFILE
// ============================================================================

/// Comprehensive intelligence profile for a single exam.
@immutable
class ExamIntelligenceProfile {
  final String examId;
  final int questionCount;
  final int? minYear;
  final int? maxYear;
  final SubjectWeightage subjectWeightage;
  final TopicWeightage topicWeightage;
  final ObjectiveCoverageReport objectiveCoverage;
  final YearDistributionReport yearDistribution;
  final Map<String, int> paperDistribution;
  final Map<String, int> languageDistribution;
  final List<RecurringProfile> topicRecurrence;
  final List<RecurringProfile> objectiveRecurrence;
  final CorpusQualityProfile qualityProfile;
  final EvidenceThresholds thresholds;
  final bool sufficientEvidence;

  const ExamIntelligenceProfile({
    required this.examId,
    required this.questionCount,
    this.minYear,
    this.maxYear,
    required this.subjectWeightage,
    required this.topicWeightage,
    required this.objectiveCoverage,
    required this.yearDistribution,
    required this.paperDistribution,
    required this.languageDistribution,
    required this.topicRecurrence,
    required this.objectiveRecurrence,
    required this.qualityProfile,
    required this.thresholds,
    required this.sufficientEvidence,
  });

  Map<String, dynamic> toJson() => {
        'examId': examId,
        'questionCount': questionCount,
        'minYear': minYear,
        'maxYear': maxYear,
        'subjectWeightage': subjectWeightage.toJson(),
        'topicWeightage': topicWeightage.toJson(),
        'objectiveCoverage': objectiveCoverage.toJson(),
        'yearDistribution': yearDistribution.toJson(),
        'paperDistribution': paperDistribution,
        'languageDistribution': languageDistribution,
        'topicRecurrence': topicRecurrence.map((e) => e.toJson()).toList(),
        'objectiveRecurrence':
            objectiveRecurrence.map((e) => e.toJson()).toList(),
        'qualityProfile': qualityProfile.toJson(),
        'thresholds': thresholds.toJson(),
        'sufficientEvidence': sufficientEvidence,
      };
}

// ============================================================================
// 13. HISTORICAL INTELLIGENCE ENGINE
// ============================================================================

/// Deterministic historical intelligence engine.
///
/// Consumes the P29 normalized corpus and produces comprehensive
/// exam-level and cross-exam intelligence without any learner inference.
///
/// All analysis is:
/// - Deterministic (identical inputs produce identical outputs).
/// - Learner-independent (zero mastery/ability inference).
/// - Non-predictive (describes history, never predicts future).
/// - Safe for empty/sparse datasets (no NaN, no Infinity).
/// - Efficiently indexed (reuses P29 corpus data).
class PyqHistoricalIntelligenceEngine {
  final EvidenceThresholds thresholds;

  const PyqHistoricalIntelligenceEngine({
    this.thresholds = const EvidenceThresholds(),
  });

  // --------------------------------------------------------------------------
  // SUBJECT WEIGHTAGE
  // --------------------------------------------------------------------------

  /// Calculates subject weightage from a list of questions.
  ///
  /// Sort: percentage DESC, count DESC, category ASC (tie-breaker).
  SubjectWeightage computeSubjectWeightage(
    List<NormalizedQuestion> questions,
  ) {
    if (questions.isEmpty) {
      return const SubjectWeightage(totalQuestions: 0, entries: []);
    }

    final counts = <String, int>{};
    for (final q in questions) {
      counts[q.subject] = (counts[q.subject] ?? 0) + 1;
    }

    final total = questions.length;
    final sorted = counts.entries.toList()
      ..sort((a, b) {
        final cmp = b.value.compareTo(a.value);
        if (cmp != 0) return cmp;
        return a.key.compareTo(b.key);
      });

    int rank = 0;
    int prevCount = -1;
    final entries = <WeightageEntry>[];
    for (final e in sorted) {
      if (e.value != prevCount) {
        rank = entries.length + 1;
        prevCount = e.value;
      }
      entries.add(WeightageEntry(
        category: e.key,
        count: e.value,
        percentage: _safePct(e.value, total),
        rank: rank,
      ));
    }

    return SubjectWeightage(totalQuestions: total, entries: entries);
  }

  // --------------------------------------------------------------------------
  // TOPIC WEIGHTAGE
  // --------------------------------------------------------------------------

  /// Calculates topic weightage with optional filtering.
  ///
  /// Sort: percentage DESC, count DESC, category ASC (tie-breaker).
  TopicWeightage computeTopicWeightage(
    List<NormalizedQuestion> questions, {
    String? examId,
    int? startYear,
    int? endYear,
    String? subject,
    String? paper,
  }) {
    var pool = questions;
    if (examId != null) {
      final eid = examId.trim().toLowerCase();
      pool = pool.where((q) => q.examId == eid).toList();
    }
    if (startYear != null) {
      pool = pool.where((q) => q.year >= startYear).toList();
    }
    if (endYear != null) {
      pool = pool.where((q) => q.year <= endYear).toList();
    }
    if (subject != null) {
      final sub = subject.trim().toLowerCase();
      pool = pool.where((q) => q.subject.toLowerCase() == sub).toList();
    }
    if (paper != null) {
      final p = paper.trim().toLowerCase();
      pool = pool.where((q) => q.paper.toLowerCase() == p).toList();
    }

    if (pool.isEmpty) {
      return TopicWeightage(
        totalQuestions: 0,
        examFilter: examId,
        startYearFilter: startYear,
        endYearFilter: endYear,
        subjectFilter: subject,
        paperFilter: paper,
        entries: const [],
      );
    }

    final counts = <String, int>{};
    for (final q in pool) {
      counts[q.topic] = (counts[q.topic] ?? 0) + 1;
    }

    final total = pool.length;
    final sorted = counts.entries.toList()
      ..sort((a, b) {
        final cmp = b.value.compareTo(a.value);
        if (cmp != 0) return cmp;
        return a.key.compareTo(b.key);
      });

    int rank = 0;
    int prevCount = -1;
    final entries = <WeightageEntry>[];
    for (final e in sorted) {
      if (e.value != prevCount) {
        rank = entries.length + 1;
        prevCount = e.value;
      }
      entries.add(WeightageEntry(
        category: e.key,
        count: e.value,
        percentage: _safePct(e.value, total),
        rank: rank,
      ));
    }

    return TopicWeightage(
      totalQuestions: total,
      examFilter: examId,
      startYearFilter: startYear,
      endYearFilter: endYear,
      subjectFilter: subject,
      paperFilter: paper,
      entries: entries,
    );
  }

  // --------------------------------------------------------------------------
  // OBJECTIVE COVERAGE
  // --------------------------------------------------------------------------

  /// Computes objective coverage against an optional curriculum framework.
  ObjectiveCoverageReport computeObjectiveCoverage(
    List<NormalizedQuestion> questions, {
    List<String> frameworkObjectiveIds = const [],
  }) {
    if (questions.isEmpty) {
      return ObjectiveCoverageReport(
        totalQuestions: 0,
        mappedQuestions: 0,
        mappingCoveragePercentage: 0.0,
        coveredObjectives: const [],
        uncoveredObjectiveIds: List.unmodifiable(frameworkObjectiveIds),
      );
    }

    final objData = <String, _ObjAccumulator>{};
    int mappedCount = 0;

    for (final q in questions) {
      if (q.objectiveIds.isNotEmpty) {
        mappedCount++;
        for (final objId in q.objectiveIds) {
          final acc = objData.putIfAbsent(objId, _ObjAccumulator.new);
          acc.count++;
          acc.years.add(q.year);
          acc.subjects.add(q.subject);
        }
      }
    }

    final total = questions.length;

    // Sort: count DESC, objectiveId ASC
    final sortedIds = objData.keys.toList()
      ..sort((a, b) {
        final cmp = objData[b]!.count.compareTo(objData[a]!.count);
        if (cmp != 0) return cmp;
        return a.compareTo(b);
      });

    final covered = sortedIds.map((objId) {
      final acc = objData[objId]!;
      final yearsList = acc.years.toList()..sort();
      final subjectsList = acc.subjects.toList()..sort();
      return ObjectiveCoverageEntry(
        objectiveId: objId,
        questionCount: acc.count,
        percentage: _safePct(acc.count, total),
        yearsRepresented: List.unmodifiable(yearsList),
        subjectsRepresented: List.unmodifiable(subjectsList),
      );
    }).toList();

    final coveredSet = objData.keys.toSet();
    final uncovered = frameworkObjectiveIds
        .where((id) => !coveredSet.contains(id))
        .toList()
      ..sort();

    final coveragePct = frameworkObjectiveIds.isNotEmpty
        ? _safePct(
            frameworkObjectiveIds.length - uncovered.length,
            frameworkObjectiveIds.length,
          )
        : _safePct(mappedCount, total);

    return ObjectiveCoverageReport(
      totalQuestions: total,
      mappedQuestions: mappedCount,
      mappingCoveragePercentage: coveragePct,
      coveredObjectives: List.unmodifiable(covered),
      uncoveredObjectiveIds: List.unmodifiable(uncovered),
    );
  }

  // --------------------------------------------------------------------------
  // YEAR DISTRIBUTION
  // --------------------------------------------------------------------------

  /// Computes year-level distribution with subject/topic breakdowns.
  ///
  /// Handles missing years, invalid years (<=0 filtered out), and
  /// future years (included if present in corpus).
  /// Sort: year ASC.
  YearDistributionReport computeYearDistribution(
    List<NormalizedQuestion> questions, {
    int? startYear,
    int? endYear,
  }) {
    var pool = questions.where((q) => q.year > 0);
    if (startYear != null) {
      pool = pool.where((q) => q.year >= startYear);
    }
    if (endYear != null) {
      pool = pool.where((q) => q.year <= endYear);
    }
    final filtered = pool.toList();

    if (filtered.isEmpty) {
      return YearDistributionReport(
        totalQuestions: 0,
        startYear: startYear,
        endYear: endYear,
        entries: const [],
      );
    }

    final yearData = <int, _YearAccumulator>{};
    for (final q in filtered) {
      final acc = yearData.putIfAbsent(q.year, _YearAccumulator.new);
      acc.count++;
      acc.subjects[q.subject] = (acc.subjects[q.subject] ?? 0) + 1;
      acc.topics[q.topic] = (acc.topics[q.topic] ?? 0) + 1;
    }

    final sortedYears = yearData.keys.toList()..sort();
    final entries = sortedYears.map((year) {
      final acc = yearData[year]!;
      return YearDistributionEntry(
        year: year,
        questionCount: acc.count,
        subjectDistribution: Map.unmodifiable(
          Map.fromEntries(
            acc.subjects.entries.toList()
              ..sort((a, b) {
                final cmp = b.value.compareTo(a.value);
                if (cmp != 0) return cmp;
                return a.key.compareTo(b.key);
              }),
          ),
        ),
        topicDistribution: Map.unmodifiable(
          Map.fromEntries(
            acc.topics.entries.toList()
              ..sort((a, b) {
                final cmp = b.value.compareTo(a.value);
                if (cmp != 0) return cmp;
                return a.key.compareTo(b.key);
              }),
          ),
        ),
      );
    }).toList();

    return YearDistributionReport(
      totalQuestions: filtered.length,
      startYear: startYear,
      endYear: endYear,
      entries: List.unmodifiable(entries),
    );
  }

  // --------------------------------------------------------------------------
  // YEAR-OVER-YEAR TREND
  // --------------------------------------------------------------------------

  /// Computes year-over-year trend for topics.
  ///
  /// Sort: totalCount DESC, multiYearFrequency DESC, category ASC.
  List<YearOverYearTrendEntry> computeTopicTrends(
    List<NormalizedQuestion> questions,
  ) {
    return _computeYoYTrends(questions, (q) => q.topic);
  }

  /// Computes year-over-year trend for objectives.
  List<YearOverYearTrendEntry> computeObjectiveTrends(
    List<NormalizedQuestion> questions,
  ) {
    final objYearCounts = <String, Map<int, int>>{};
    final objTotals = <String, int>{};

    for (final q in questions) {
      for (final obj in q.objectiveIds) {
        final yearMap = objYearCounts.putIfAbsent(obj, () => <int, int>{});
        yearMap[q.year] = (yearMap[q.year] ?? 0) + 1;
        objTotals[obj] = (objTotals[obj] ?? 0) + 1;
      }
    }

    final entries = <YearOverYearTrendEntry>[];
    for (final objId in objYearCounts.keys) {
      final yearCounts = objYearCounts[objId]!;
      entries.add(_buildTrendEntry(objId, yearCounts, objTotals[objId]!));
    }

    entries.sort((a, b) {
      int cmp = b.totalCount.compareTo(a.totalCount);
      if (cmp != 0) return cmp;
      cmp = b.multiYearFrequency.compareTo(a.multiYearFrequency);
      if (cmp != 0) return cmp;
      return a.category.compareTo(b.category);
    });

    return List.unmodifiable(entries);
  }

  // --------------------------------------------------------------------------
  // RECENCY ANALYSIS
  // --------------------------------------------------------------------------

  /// Computes recency for topics within an explicit window.
  ///
  /// [windowStartYear] and [windowEndYear] define "recent".
  /// Everything outside is "historical".
  /// No DateTime.now() used.
  ///
  /// Sort: recentShare DESC, recentCount DESC, category ASC.
  List<RecencyAnalysis> computeTopicRecency(
    List<NormalizedQuestion> questions, {
    required int windowStartYear,
    required int windowEndYear,
  }) {
    return _computeRecency(
      questions,
      (q) => q.topic,
      windowStartYear: windowStartYear,
      windowEndYear: windowEndYear,
    );
  }

  /// Computes recency for objectives within an explicit window.
  List<RecencyAnalysis> computeObjectiveRecency(
    List<NormalizedQuestion> questions, {
    required int windowStartYear,
    required int windowEndYear,
  }) {
    final results = <String, _RecencyAccumulator>{};

    for (final q in questions) {
      for (final obj in q.objectiveIds) {
        final acc = results.putIfAbsent(obj, _RecencyAccumulator.new);
        if (q.year >= windowStartYear && q.year <= windowEndYear) {
          acc.recent++;
        } else {
          acc.historical++;
        }
      }
    }

    final entries = results.entries.map((e) {
      final total = e.value.recent + e.value.historical;
      return RecencyAnalysis(
        category: e.key,
        recentCount: e.value.recent,
        historicalCount: e.value.historical,
        recentShare: _safeRatio(e.value.recent, total),
        windowStartYear: windowStartYear,
        windowEndYear: windowEndYear,
      );
    }).toList()
      ..sort((a, b) {
        int cmp = b.recentShare.compareTo(a.recentShare);
        if (cmp != 0) return cmp;
        cmp = b.recentCount.compareTo(a.recentCount);
        if (cmp != 0) return cmp;
        return a.category.compareTo(b.category);
      });

    return List.unmodifiable(entries);
  }

  // --------------------------------------------------------------------------
  // RECURRENCE ANALYSIS
  // --------------------------------------------------------------------------

  /// Identifies topics appearing across multiple years.
  ///
  /// Sort: yearCount DESC, questionCount DESC, id ASC.
  List<RecurringProfile> computeTopicRecurrence(
    List<NormalizedQuestion> questions,
  ) {
    return _computeRecurrence(questions, (q) => q.topic);
  }

  /// Identifies objectives appearing across multiple years.
  List<RecurringProfile> computeObjectiveRecurrence(
    List<NormalizedQuestion> questions,
  ) {
    final data = <String, _RecurrenceAccumulator>{};
    for (final q in questions) {
      for (final obj in q.objectiveIds) {
        final acc = data.putIfAbsent(obj, _RecurrenceAccumulator.new);
        acc.count++;
        acc.years.add(q.year);
      }
    }

    return _buildRecurrenceProfiles(data);
  }

  // --------------------------------------------------------------------------
  // CROSS-EXAM COMPARISON
  // --------------------------------------------------------------------------

  /// Deterministic comparison between two exams.
  CrossExamComparison compareExams(
    List<NormalizedQuestion> questions, {
    required String examIdA,
    required String examIdB,
  }) {
    final eidA = examIdA.trim().toLowerCase();
    final eidB = examIdB.trim().toLowerCase();

    final poolA = questions.where((q) => q.examId == eidA).toList();
    final poolB = questions.where((q) => q.examId == eidB).toList();

    return CrossExamComparison(
      examIdA: eidA,
      examIdB: eidB,
      entryA: _buildComparisonEntry(eidA, poolA),
      entryB: _buildComparisonEntry(eidB, poolB),
    );
  }

  // --------------------------------------------------------------------------
  // CORPUS QUALITY
  // --------------------------------------------------------------------------

  /// Computes corpus quality metrics.
  CorpusQualityProfile computeQualityProfile(
    List<NormalizedQuestion> questions, {
    int knownDuplicateCount = 0,
  }) {
    if (questions.isEmpty) {
      return const CorpusQualityProfile(
        totalQuestions: 0,
        subjectCompleteness: 0.0,
        topicCompleteness: 0.0,
        objectiveMappingCoverage: 0.0,
        topicMappingCoverage: 0.0,
        yearCoverage: 0.0,
        provenanceCoverage: 0.0,
        duplicateRatio: 0.0,
      );
    }

    final total = questions.length;
    int hasSubject = 0;
    int hasTopic = 0;
    int hasObjective = 0;
    int hasNonGenericTopic = 0;
    int hasValidYear = 0;
    int hasProvenance = 0;

    for (final q in questions) {
      if (q.subject.isNotEmpty &&
          q.subject.toLowerCase() != 'general studies') {
        hasSubject++;
      }
      if (q.topic.isNotEmpty) {
        hasTopic++;
      }
      if (q.topic.isNotEmpty && q.topic.toLowerCase() != 'general') {
        hasNonGenericTopic++;
      }
      if (q.objectiveIds.isNotEmpty) {
        hasObjective++;
      }
      if (q.year > 0) {
        hasValidYear++;
      }
      if (q.source.sourceId.isNotEmpty) {
        hasProvenance++;
      }
    }

    final totalWithDups = total + knownDuplicateCount;
    return CorpusQualityProfile(
      totalQuestions: total,
      subjectCompleteness: _safeRatio(hasSubject, total),
      topicCompleteness: _safeRatio(hasTopic, total),
      objectiveMappingCoverage: _safeRatio(hasObjective, total),
      topicMappingCoverage: _safeRatio(hasNonGenericTopic, total),
      yearCoverage: _safeRatio(hasValidYear, total),
      provenanceCoverage: _safeRatio(hasProvenance, total),
      duplicateRatio: totalWithDups > 0
          ? _safeRatio(knownDuplicateCount, totalWithDups)
          : 0.0,
    );
  }

  // --------------------------------------------------------------------------
  // EXAM INTELLIGENCE PROFILE
  // --------------------------------------------------------------------------

  /// Builds a comprehensive intelligence profile for a single exam.
  ExamIntelligenceProfile buildExamProfile(
    List<NormalizedQuestion> allQuestions, {
    required String examId,
    List<String> frameworkObjectiveIds = const [],
    int knownDuplicateCount = 0,
  }) {
    final eid = examId.trim().toLowerCase();
    final pool = allQuestions.where((q) => q.examId == eid).toList();

    final sufficient = pool.length >= thresholds.minimumQuestionsForWeightage;

    int? minY;
    int? maxY;
    if (pool.isNotEmpty) {
      minY = pool.map((q) => q.year).reduce(math.min);
      maxY = pool.map((q) => q.year).reduce(math.max);
    }

    // Paper distribution
    final paperDist = <String, int>{};
    for (final q in pool) {
      paperDist[q.paper] = (paperDist[q.paper] ?? 0) + 1;
    }
    final sortedPaper = Map.fromEntries(
      paperDist.entries.toList()
        ..sort((a, b) {
          final cmp = b.value.compareTo(a.value);
          if (cmp != 0) return cmp;
          return a.key.compareTo(b.key);
        }),
    );

    // Language distribution
    final langDist = <String, int>{};
    for (final q in pool) {
      langDist[q.language] = (langDist[q.language] ?? 0) + 1;
    }
    final sortedLang = Map.fromEntries(
      langDist.entries.toList()
        ..sort((a, b) {
          final cmp = b.value.compareTo(a.value);
          if (cmp != 0) return cmp;
          return a.key.compareTo(b.key);
        }),
    );

    return ExamIntelligenceProfile(
      examId: eid,
      questionCount: pool.length,
      minYear: minY,
      maxYear: maxY,
      subjectWeightage: computeSubjectWeightage(pool),
      topicWeightage: computeTopicWeightage(pool),
      objectiveCoverage: computeObjectiveCoverage(
        pool,
        frameworkObjectiveIds: frameworkObjectiveIds,
      ),
      yearDistribution: computeYearDistribution(pool),
      paperDistribution: Map.unmodifiable(sortedPaper),
      languageDistribution: Map.unmodifiable(sortedLang),
      topicRecurrence: computeTopicRecurrence(pool),
      objectiveRecurrence: computeObjectiveRecurrence(pool),
      qualityProfile: computeQualityProfile(
        pool,
        knownDuplicateCount: knownDuplicateCount,
      ),
      thresholds: thresholds,
      sufficientEvidence: sufficient,
    );
  }

  // ==========================================================================
  // PRIVATE HELPERS
  // ==========================================================================

  static double _safePct(int part, int total) {
    if (total <= 0) return 0.0;
    return (part / total) * 100.0;
  }

  static double _safeRatio(int part, int total) {
    if (total <= 0) return 0.0;
    return part / total;
  }

  List<YearOverYearTrendEntry> _computeYoYTrends(
    List<NormalizedQuestion> questions,
    String Function(NormalizedQuestion) categoryFn,
  ) {
    final catYearCounts = <String, Map<int, int>>{};
    final catTotals = <String, int>{};

    for (final q in questions) {
      final cat = categoryFn(q);
      final yearMap = catYearCounts.putIfAbsent(cat, () => <int, int>{});
      yearMap[q.year] = (yearMap[q.year] ?? 0) + 1;
      catTotals[cat] = (catTotals[cat] ?? 0) + 1;
    }

    final entries = <YearOverYearTrendEntry>[];
    for (final cat in catYearCounts.keys) {
      final yearCounts = catYearCounts[cat]!;
      entries.add(_buildTrendEntry(cat, yearCounts, catTotals[cat]!));
    }

    entries.sort((a, b) {
      int cmp = b.totalCount.compareTo(a.totalCount);
      if (cmp != 0) return cmp;
      cmp = b.multiYearFrequency.compareTo(a.multiYearFrequency);
      if (cmp != 0) return cmp;
      return a.category.compareTo(b.category);
    });

    return List.unmodifiable(entries);
  }

  YearOverYearTrendEntry _buildTrendEntry(
    String category,
    Map<int, int> yearCounts,
    int totalCount,
  ) {
    final sortedYears = yearCounts.keys.toList()..sort();
    final absChanges = <int, int>{};
    final pctChanges = <int, double>{};

    for (int i = 0; i < sortedYears.length; i++) {
      final year = sortedYears[i];
      if (i == 0) {
        absChanges[year] = 0;
        pctChanges[year] = 0.0;
      } else {
        final prev = sortedYears[i - 1];
        final prevCount = yearCounts[prev]!;
        final currCount = yearCounts[year]!;
        absChanges[year] = currCount - prevCount;
        pctChanges[year] =
            prevCount > 0 ? ((currCount - prevCount) / prevCount) * 100.0 : 0.0;
      }
    }

    return YearOverYearTrendEntry(
      category: category,
      yearCounts: Map.unmodifiable(
        Map.fromEntries(
          sortedYears.map((y) => MapEntry(y, yearCounts[y]!)),
        ),
      ),
      totalCount: totalCount,
      absoluteChanges: Map.unmodifiable(absChanges),
      percentageChanges: Map.unmodifiable(pctChanges),
      multiYearFrequency: sortedYears.length,
    );
  }

  List<RecencyAnalysis> _computeRecency(
    List<NormalizedQuestion> questions,
    String Function(NormalizedQuestion) categoryFn, {
    required int windowStartYear,
    required int windowEndYear,
  }) {
    final results = <String, _RecencyAccumulator>{};

    for (final q in questions) {
      final cat = categoryFn(q);
      final acc = results.putIfAbsent(cat, _RecencyAccumulator.new);
      if (q.year >= windowStartYear && q.year <= windowEndYear) {
        acc.recent++;
      } else {
        acc.historical++;
      }
    }

    final entries = results.entries.map((e) {
      final total = e.value.recent + e.value.historical;
      return RecencyAnalysis(
        category: e.key,
        recentCount: e.value.recent,
        historicalCount: e.value.historical,
        recentShare: _safeRatio(e.value.recent, total),
        windowStartYear: windowStartYear,
        windowEndYear: windowEndYear,
      );
    }).toList()
      ..sort((a, b) {
        int cmp = b.recentShare.compareTo(a.recentShare);
        if (cmp != 0) return cmp;
        cmp = b.recentCount.compareTo(a.recentCount);
        if (cmp != 0) return cmp;
        return a.category.compareTo(b.category);
      });

    return List.unmodifiable(entries);
  }

  List<RecurringProfile> _computeRecurrence(
    List<NormalizedQuestion> questions,
    String Function(NormalizedQuestion) categoryFn,
  ) {
    final data = <String, _RecurrenceAccumulator>{};
    for (final q in questions) {
      final cat = categoryFn(q);
      final acc = data.putIfAbsent(cat, _RecurrenceAccumulator.new);
      acc.count++;
      acc.years.add(q.year);
    }

    return _buildRecurrenceProfiles(data);
  }

  List<RecurringProfile> _buildRecurrenceProfiles(
    Map<String, _RecurrenceAccumulator> data,
  ) {
    final profiles = <RecurringProfile>[];
    for (final entry in data.entries) {
      final acc = entry.value;
      final yearsList = acc.years.toList()..sort();
      if (yearsList.isEmpty) continue;
      profiles.add(RecurringProfile(
        id: entry.key,
        yearsPresent: List.unmodifiable(yearsList),
        yearCount: yearsList.length,
        questionCount: acc.count,
        firstYear: yearsList.first,
        lastYear: yearsList.last,
      ));
    }

    // Sort: yearCount DESC, questionCount DESC, id ASC
    profiles.sort((a, b) {
      int cmp = b.yearCount.compareTo(a.yearCount);
      if (cmp != 0) return cmp;
      cmp = b.questionCount.compareTo(a.questionCount);
      if (cmp != 0) return cmp;
      return a.id.compareTo(b.id);
    });

    return List.unmodifiable(profiles);
  }

  ExamComparisonEntry _buildComparisonEntry(
    String examId,
    List<NormalizedQuestion> pool,
  ) {
    if (pool.isEmpty) {
      return ExamComparisonEntry(
        examId: examId,
        corpusSize: 0,
        yearCoverage: 0,
        subjectDistribution: const {},
        topicDistribution: const {},
        objectivesCovered: 0,
        languageDistribution: const {},
      );
    }

    final years = <int>{};
    final subjects = <String, int>{};
    final topics = <String, int>{};
    final objectives = <String>{};
    final languages = <String, int>{};

    for (final q in pool) {
      years.add(q.year);
      subjects[q.subject] = (subjects[q.subject] ?? 0) + 1;
      topics[q.topic] = (topics[q.topic] ?? 0) + 1;
      objectives.addAll(q.objectiveIds);
      languages[q.language] = (languages[q.language] ?? 0) + 1;
    }

    final yearsList = years.toList()..sort();

    return ExamComparisonEntry(
      examId: examId,
      corpusSize: pool.length,
      yearCoverage: years.length,
      minYear: yearsList.first,
      maxYear: yearsList.last,
      subjectDistribution: Map.unmodifiable(Map.fromEntries(
        subjects.entries.toList()
          ..sort((a, b) {
            final cmp = b.value.compareTo(a.value);
            if (cmp != 0) return cmp;
            return a.key.compareTo(b.key);
          }),
      )),
      topicDistribution: Map.unmodifiable(Map.fromEntries(
        topics.entries.toList()
          ..sort((a, b) {
            final cmp = b.value.compareTo(a.value);
            if (cmp != 0) return cmp;
            return a.key.compareTo(b.key);
          }),
      )),
      objectivesCovered: objectives.length,
      languageDistribution: Map.unmodifiable(Map.fromEntries(
        languages.entries.toList()
          ..sort((a, b) {
            final cmp = b.value.compareTo(a.value);
            if (cmp != 0) return cmp;
            return a.key.compareTo(b.key);
          }),
      )),
    );
  }
}

// Private accumulators (mutable during computation, never exposed).
class _ObjAccumulator {
  int count = 0;
  final Set<int> years = {};
  final Set<String> subjects = {};
}

class _YearAccumulator {
  int count = 0;
  final Map<String, int> subjects = {};
  final Map<String, int> topics = {};
}

class _RecencyAccumulator {
  int recent = 0;
  int historical = 0;
}

class _RecurrenceAccumulator {
  int count = 0;
  final Set<int> years = {};
}
