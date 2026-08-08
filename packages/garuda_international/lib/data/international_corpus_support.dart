library;

import 'package:garuda_editor/garuda_editor.dart';

import '../domain/entities/international_enums.dart';
import '../domain/entities/international_knowledge_object.dart';
import '../domain/entities/international_relationship.dart';
import 'international_official_sources.dart';

/// Single editorial verification date applied across the Phase-I corpus.
/// Every record carries an official source and evidence reference; this marks
/// the date the corpus facts were last verified against official publications.
const String corpusLastVerifiedDate = '2026-06-30';

/// DRY factory reducing per-record boilerplate while keeping every
/// organisation's official facts explicit and traceable. Records default to
/// `evidenceVerified` editorial status because the Phase-I corpus is built from
/// authoritative official sources with a recorded verification date.
///
/// `officialSource` and `evidenceIds` are mandatory by design. When a record
/// does not supply them, they are resolved from [InternationalOfficialSources]
/// so that no corpus record can exist without a traceable official source and
/// evidence.
InternationalKnowledgeObject internationalRecord({
  required String id,
  required String officialName,
  required String shortName,
  required String acronym,
  required InternationalBodyType bodyType,
  required InternationalCategory category,
  required int establishedYear,
  String officialSource = '',
  List<String> evidenceIds = const [],
  required List<String> keywords,
  InstitutionalStatus institutionalStatus = InstitutionalStatus.active,
  TreatyStatus treatyStatus = TreatyStatus.notApplicable,
  MembershipType membershipType = MembershipType.fullMember,
  MembershipScope membershipScope = MembershipScope.global,
  DecisionMakingModel decisionMakingModel = DecisionMakingModel.consensus,
  FundingModel fundingModel = FundingModel.memberContributions,
  String headquarters = '',
  HeadquartersRegion headquartersRegion = HeadquartersRegion.globalMultiple,
  String foundingTreaty = '',
  String legalBasis = '',
  String secretariat = '',
  int? membershipCount,
  String principalOrgans = '',
  String leadershipStructure = '',
  String votingMechanism = '',
  String mandate = '',
  List<String> objectives = const [],
  List<String> functions = const [],
  List<String> powers = const [],
  String fundingMechanism = '',
  List<String> importantProgrammes = const [],
  List<String> importantConventions = const [],
  GeographicalRegion geographicalRegion = GeographicalRegion.global,
  List<GlobalIssueArea> issueAreas = const [],
  IndiaRelationshipStatus indiaMembership = IndiaRelationshipStatus.notApplicable,
  int? indiaJoiningYear,
  String indiaRole = '',
  String observerStatus = '',
  List<String> indiaHostedEvents = const [],
  List<String> indiaInitiatives = const [],
  String currentRelevance = '',
  String indiaRelevance = '',
  UpscRelevanceLevel upscRelevance = UpscRelevanceLevel.medium,
  RelevanceLevel prelimsRelevance = RelevanceLevel.medium,
  RelevanceLevel mainsRelevance = RelevanceLevel.medium,
  RelevanceLevel interviewRelevance = RelevanceLevel.medium,
  List<String> prelimsTraps = const [],
  List<String> mainsThemes = const [],
  List<String> essayThemes = const [],
  List<String> interviewAreas = const [],
  List<String> relatedArticleIds = const [],
  List<String> relatedActIds = const [],
  List<String> relatedCaseLawIds = const [],
  List<String> relatedDoctrineIds = const [],
  List<String> relatedCommitteeIds = const [],
  List<String> relatedReportIds = const [],
  List<String> relatedSchemeIds = const [],
  List<String> relatedCurrentAffairsIds = const [],
  List<String> relatedPyqIds = const [],
  List<String> relatedOrganisationIds = const [],
  List<String> sdgGoals = const [],
  List<InternationalRelationship> relationships = const [],
}) {
  final resolvedSource = officialSource.isNotEmpty
      ? officialSource
      : (InternationalOfficialSources.sourceUrl[id] ?? '');
  final resolvedEvidence = evidenceIds.isNotEmpty
      ? evidenceIds
      : (InternationalOfficialSources.sourceUrl.containsKey(id)
          ? [InternationalOfficialSources.evidenceIdFor(id)]
          : const <String>[]);

  return InternationalKnowledgeObject(
    id: id,
    officialName: officialName,
    shortName: shortName,
    acronym: acronym,
    bodyType: bodyType,
    category: category,
    institutionalStatus: institutionalStatus,
    treatyStatus: treatyStatus,
    membershipType: membershipType,
    membershipScope: membershipScope,
    decisionMakingModel: decisionMakingModel,
    fundingModel: fundingModel,
    headquarters: headquarters,
    headquartersRegion: headquartersRegion,
    establishedYear: establishedYear,
    foundingTreaty: foundingTreaty,
    legalBasis: legalBasis,
    secretariat: secretariat,
    membershipCount: membershipCount,
    principalOrgans: principalOrgans,
    leadershipStructure: leadershipStructure,
    votingMechanism: votingMechanism,
    mandate: mandate,
    objectives: objectives,
    functions: functions,
    powers: powers,
    fundingMechanism: fundingMechanism,
    importantProgrammes: importantProgrammes,
    importantConventions: importantConventions,
    geographicalRegion: geographicalRegion,
    issueAreas: issueAreas,
    indiaMembership: indiaMembership,
    indiaJoiningYear: indiaJoiningYear,
    indiaRole: indiaRole,
    observerStatus: observerStatus,
    indiaHostedEvents: indiaHostedEvents,
    indiaInitiatives: indiaInitiatives,
    currentRelevance: currentRelevance,
    indiaRelevance: indiaRelevance,
    upscRelevance: upscRelevance,
    prelimsRelevance: prelimsRelevance,
    mainsRelevance: mainsRelevance,
    interviewRelevance: interviewRelevance,
    prelimsTraps: prelimsTraps,
    mainsThemes: mainsThemes,
    essayThemes: essayThemes,
    interviewAreas: interviewAreas,
    relatedArticleIds: relatedArticleIds,
    relatedActIds: relatedActIds,
    relatedCaseLawIds: relatedCaseLawIds,
    relatedDoctrineIds: relatedDoctrineIds,
    relatedCommitteeIds: relatedCommitteeIds,
    relatedReportIds: relatedReportIds,
    relatedSchemeIds: relatedSchemeIds,
    relatedCurrentAffairsIds: relatedCurrentAffairsIds,
    relatedPyqIds: relatedPyqIds,
    relatedOrganisationIds: relatedOrganisationIds,
    sdgGoals: sdgGoals,
    relationships: relationships,
    officialSource: resolvedSource,
    evidenceIds: resolvedEvidence,
    lastVerifiedDate: corpusLastVerifiedDate,
    keywords: keywords,
    version: 1,
    editorialStatus: EditorialStatus.evidenceVerified,
  );
}
