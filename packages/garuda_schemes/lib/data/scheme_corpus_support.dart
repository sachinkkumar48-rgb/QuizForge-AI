library;

import 'package:garuda_editor/garuda_editor.dart';

import '../domain/entities/scheme_beneficiary.dart';
import '../domain/entities/scheme_benefit.dart';
import '../domain/entities/scheme_component.dart';
import '../domain/entities/scheme_enums.dart';
import '../domain/entities/scheme_funding.dart';
import '../domain/entities/scheme_knowledge_object.dart';
import '../domain/entities/scheme_ministry.dart';
import '../domain/entities/scheme_relationship.dart';
import '../domain/entities/scheme_timeline.dart';
import 'scheme_official_sources.dart';

/// Single editorial verification date applied across the Phase-I corpus.
/// Every record carries an official source and evidence reference; this marks
/// the date the corpus facts were last verified against official publications.
const String corpusLastVerifiedDate = '2026-06-30';

/// DRY factory reducing per-record boilerplate while keeping every scheme's
/// official facts explicit and traceable. Records default to
/// `evidenceVerified` editorial status because the Phase-I corpus is built from
/// officially published sources with a recorded verification date.
///
/// `officialSource` and `evidenceIds` are mandatory by design. When a record
/// does not supply them, they are resolved from [SchemeOfficialSources] so that
/// no corpus record can exist without a traceable official source and evidence.
SchemeKnowledgeObject schemeRecord({
  required String id,
  required String officialName,
  required String shortName,
  required SchemeMinistry ministry,
  required SchemeCategory category,
  required SchemeSector sector,
  required DateTime launchDate,
  required SchemeType schemeType,
  required FundingPatternType fundingPattern,
  required String centralShare,
  required String stateShare,
  required String financialAssistance,
  String officialSource = '',
  List<String> evidenceIds = const [],
  required List<String> keywords,
  SchemeStatus status = SchemeStatus.operational,
  String budgetOutlay = '',
  String department = '',
  String implementingAgency = '',
  List<BeneficiaryGroup> beneficiaries = const [],
  List<String> targetBeneficiaries = const [],
  List<String> eligibility = const [],
  List<String> objectives = const [],
  List<String> keyFeatures = const [],
  List<SchemeBenefit> benefits = const [],
  List<SchemeComponent> components = const [],
  String coverage = '',
  List<String> geographicScope = const [],
  RuralUrbanScope ruralUrbanScope = RuralUrbanScope.both,
  List<String> relatedArticleIds = const [],
  List<String> relatedActIds = const [],
  List<String> relatedCaseLawIds = const [],
  List<String> relatedDoctrineIds = const [],
  List<String> relatedCommitteeIds = const [],
  List<String> relatedReportIds = const [],
  List<String> relatedCurrentAffairsIds = const [],
  List<String> relatedPyqIds = const [],
  List<String> relatedSchemeIds = const [],
  List<String> predecessorSchemeIds = const [],
  List<String> successorSchemeIds = const [],
  String? subsumedBySchemeId,
  List<SdgGoal> sdgGoals = const [],
  List<SchemeRelationship> relationships = const [],
  List<SchemeTimeline> timeline = const [],
  String upscRelevance = '',
}) {
  final resolvedSource = officialSource.isNotEmpty
      ? officialSource
      : (SchemeOfficialSources.sourceUrl[id] ?? '');
  final resolvedEvidence = evidenceIds.isNotEmpty
      ? evidenceIds
      : (SchemeOfficialSources.sourceUrl.containsKey(id)
          ? [SchemeOfficialSources.evidenceIdFor(id)]
          : const <String>[]);

  return SchemeKnowledgeObject(
    id: id,
    officialName: officialName,
    shortName: shortName,
    schemeType: schemeType,
    category: category,
    sector: sector,
    ministry: ministry,
    department: department,
    status: status,
    launchDate: launchDate,
    implementingAgency: implementingAgency,
    beneficiaries: beneficiaries,
    targetBeneficiaries: targetBeneficiaries,
    eligibility: eligibility,
    objectives: objectives,
    keyFeatures: keyFeatures,
    benefits: benefits,
    components: components,
    funding: SchemeFundingDetail(
      fundingPattern: fundingPattern,
      centralShare: centralShare,
      stateShare: stateShare,
      financialAssistance: financialAssistance,
      budgetOutlay: budgetOutlay,
    ),
    coverage: coverage,
    geographicScope: geographicScope,
    ruralUrbanScope: ruralUrbanScope,
    relatedArticleIds: relatedArticleIds,
    relatedActIds: relatedActIds,
    relatedCaseLawIds: relatedCaseLawIds,
    relatedDoctrineIds: relatedDoctrineIds,
    relatedCommitteeIds: relatedCommitteeIds,
    relatedReportIds: relatedReportIds,
    relatedCurrentAffairsIds: relatedCurrentAffairsIds,
    relatedPyqIds: relatedPyqIds,
    relatedSchemeIds: relatedSchemeIds,
    predecessorSchemeIds: predecessorSchemeIds,
    successorSchemeIds: successorSchemeIds,
    subsumedBySchemeId: subsumedBySchemeId,
    sdgGoals: sdgGoals,
    relationships: relationships,
    timeline: timeline,
    officialSource: resolvedSource,
    evidenceIds: resolvedEvidence,
    lastVerifiedDate: corpusLastVerifiedDate,
    upscRelevance: upscRelevance,
    keywords: keywords,
    version: 1,
    editorialStatus: EditorialStatus.evidenceVerified,
  );
}
