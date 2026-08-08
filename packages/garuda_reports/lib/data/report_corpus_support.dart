library;

import 'package:garuda_editor/garuda_editor.dart';

import '../domain/entities/index_knowledge_object.dart';
import '../domain/entities/indicator_knowledge_object.dart';
import '../domain/entities/report_knowledge_object.dart';
import '../domain/entities/survey_knowledge_object.dart';
import 'report_official_sources.dart';

/// Single editorial verification date applied across the Phase-I corpus.
/// Every record carries an official source and evidence reference; this marks
/// the date the corpus facts were last verified against official publications.
const String corpusLastVerifiedDate = ReportOfficialSources.corpusLastVerifiedDate;

/// Enrichment helpers for the Phase-I Reports & Indices corpus.
///
/// Seeded records default to `evidenceVerified` editorial status because the
/// Phase-I corpus is built from officially published sources with a recorded
/// verification date. When a record omits `lastVerifiedDate`, `officialUrl` or
/// `evidenceIds`, they are resolved from [ReportOfficialSources] so that no
/// corpus record can exist without a traceable official source and evidence.
class ReportCorpusSupport {
  ReportCorpusSupport._();

  /// Applies corpus-level defaults to a Report Knowledge Object.
  static ReportKnowledgeObject enrichReport(ReportKnowledgeObject report) {
    final resolvedUrl = report.officialUrl.isNotEmpty
        ? report.officialUrl
        : ReportOfficialSources.sourceUrlFor(report.id);
    final resolvedEvidence = report.evidenceIds.isNotEmpty
        ? report.evidenceIds
        : <String>[if (resolvedUrl.isNotEmpty) 'ev_${report.id}_official'];
    return report.copyWith(
      lastVerifiedDate: report.lastVerifiedDate.isNotEmpty
          ? report.lastVerifiedDate
          : corpusLastVerifiedDate,
      officialUrl: resolvedUrl,
      evidenceIds: resolvedEvidence,
      editorialStatus: _promoteStatus(report.editorialStatus),
    );
  }

  /// Applies corpus-level defaults to an Index Knowledge Object.
  static IndexKnowledgeObject enrichIndex(IndexKnowledgeObject index) {
    final resolvedUrl = index.officialUrl.isNotEmpty
        ? index.officialUrl
        : ReportOfficialSources.sourceUrlFor(index.id);
    final resolvedEvidence = index.evidenceIds.isNotEmpty
        ? index.evidenceIds
        : <String>[if (resolvedUrl.isNotEmpty) 'ev_${index.id}_official'];
    return index.copyWith(
      lastVerifiedDate: index.lastVerifiedDate.isNotEmpty
          ? index.lastVerifiedDate
          : corpusLastVerifiedDate,
      officialUrl: resolvedUrl,
      evidenceIds: resolvedEvidence,
      editorialStatus: _promoteStatus(index.editorialStatus),
    );
  }

  /// Applies corpus-level defaults to a Survey Knowledge Object.
  static SurveyKnowledgeObject enrichSurvey(SurveyKnowledgeObject survey) {
    final resolvedUrl = survey.officialUrl.isNotEmpty
        ? survey.officialUrl
        : ReportOfficialSources.sourceUrlFor(survey.id);
    final resolvedEvidence = survey.evidenceIds.isNotEmpty
        ? survey.evidenceIds
        : <String>[if (resolvedUrl.isNotEmpty) 'ev_${survey.id}_official'];
    return survey.copyWith(
      lastVerifiedDate: survey.lastVerifiedDate.isNotEmpty
          ? survey.lastVerifiedDate
          : corpusLastVerifiedDate,
      officialUrl: resolvedUrl,
      evidenceIds: resolvedEvidence,
      editorialStatus: _promoteStatus(survey.editorialStatus),
    );
  }

  /// Applies corpus-level defaults to an Indicator Knowledge Object.
  static IndicatorKnowledgeObject enrichIndicator(
      IndicatorKnowledgeObject indicator) {
    final resolvedSource = indicator.source.isNotEmpty
        ? indicator.source
        : ReportOfficialSources.sourceUrlFor(indicator.id);
    final resolvedEvidence = indicator.evidenceIds.isNotEmpty
        ? indicator.evidenceIds
        : <String>[if (resolvedSource.isNotEmpty) 'ev_${indicator.id}_official'];
    return indicator.copyWith(
      lastVerifiedDate: indicator.lastVerifiedDate.isNotEmpty
          ? indicator.lastVerifiedDate
          : corpusLastVerifiedDate,
      source: resolvedSource,
      evidenceIds: resolvedEvidence,
      editorialStatus: _promoteStatus(indicator.editorialStatus),
    );
  }

  /// Proportion of the given records whose attached evidence is fully
  /// resolvable against [ReportOfficialSources]. Returns a value in [0, 1].
  static double evidenceCoverage(Iterable<dynamic> objects) {
    final list = objects.toList();
    if (list.isEmpty) return 0;
    var covered = 0;
    for (final object in list) {
      final evidenceIds = _evidenceIdsOf(object);
      if (evidenceIds.isNotEmpty &&
          evidenceIds.every(
              (id) => ReportOfficialSources.evidenceUrlFor(id).isNotEmpty)) {
        covered++;
      }
    }
    return covered / list.length;
  }

  /// Whether a single record's evidence is fully traceable.
  static bool hasResolvableEvidence(dynamic object) =>
      ReportOfficialSources.evidenceResolvable(_evidenceIdsOf(object));

  static List<String> _evidenceIdsOf(dynamic object) {
    if (object is ReportKnowledgeObject) return object.evidenceIds;
    if (object is IndexKnowledgeObject) return object.evidenceIds;
    if (object is SurveyKnowledgeObject) return object.evidenceIds;
    if (object is IndicatorKnowledgeObject) return object.evidenceIds;
    return const [];
  }

  /// Promotes a freshly-seeded record to `evidenceVerified` unless it has
  /// already passed further along the editorial lifecycle.
  static EditorialStatus _promoteStatus(EditorialStatus status) {
    const rawEditorialStatuses = [
      EditorialStatus.imported,
      EditorialStatus.pendingReview,
      EditorialStatus.inReview,
      EditorialStatus.draft,
      EditorialStatus.reviewPending,
    ];
    if (rawEditorialStatuses.contains(status)) {
      return EditorialStatus.evidenceVerified;
    }
    return status;
  }
}
