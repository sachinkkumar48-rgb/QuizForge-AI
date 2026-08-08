library;

import 'package:garuda_editor/garuda_editor.dart';
import 'package:meta/meta.dart';
import 'international_enums.dart';
import 'international_relationship.dart';

/// Permanent, interconnected International Organisation Knowledge Object in the
/// GARUDA International Organisations, Groupings & Global Institutions Library.
/// Every organisation is modelled as an independent, searchable, evidence-backed
/// Knowledge Object with India-specific and UPSC-specific intelligence, linked
/// to the Constitution, Acts, Cases, Doctrines, Committees, Reports, Schemes,
/// Current Affairs, PYQs, treaties, SDGs and related organisations.
@immutable
class InternationalKnowledgeObject {
  final String id;
  final String officialName;
  final String shortName;
  final String acronym;
  final InternationalBodyType bodyType;
  final InternationalCategory category;
  final InstitutionalStatus institutionalStatus;
  final TreatyStatus treatyStatus;
  final MembershipType membershipType;
  final MembershipScope membershipScope;
  final DecisionMakingModel decisionMakingModel;
  final FundingModel fundingModel;
  final String headquarters;
  final HeadquartersRegion headquartersRegion;
  final int establishedYear;
  final String foundingTreaty;
  final String legalBasis;
  final String secretariat;
  final int? membershipCount;
  final String principalOrgans;
  final String leadershipStructure;
  final String votingMechanism;
  final String mandate;
  final List<String> objectives;
  final List<String> functions;
  final List<String> powers;
  final String fundingMechanism;
  final List<String> importantProgrammes;
  final List<String> importantConventions;
  final GeographicalRegion geographicalRegion;
  final List<GlobalIssueArea> issueAreas;
  final IndiaRelationshipStatus indiaMembership;
  final int? indiaJoiningYear;
  final String indiaRole;
  final String observerStatus;
  final List<String> indiaHostedEvents;
  final List<String> indiaInitiatives;
  final String currentRelevance;
  final String indiaRelevance;
  final UpscRelevanceLevel upscRelevance;
  final RelevanceLevel prelimsRelevance;
  final RelevanceLevel mainsRelevance;
  final RelevanceLevel interviewRelevance;
  final List<String> prelimsTraps;
  final List<String> mainsThemes;
  final List<String> essayThemes;
  final List<String> interviewAreas;
  final List<String> relatedArticleIds;
  final List<String> relatedActIds;
  final List<String> relatedCaseLawIds;
  final List<String> relatedDoctrineIds;
  final List<String> relatedCommitteeIds;
  final List<String> relatedReportIds;
  final List<String> relatedSchemeIds;
  final List<String> relatedCurrentAffairsIds;
  final List<String> relatedPyqIds;
  final List<String> relatedOrganisationIds;
  final List<String> sdgGoals;
  final List<InternationalRelationship> relationships;
  final String officialSource;
  final List<String> evidenceIds;
  final String lastVerifiedDate;
  final List<String> keywords;
  final int version;
  final EditorialStatus editorialStatus;
  final Map<String, dynamic> metadata;

  InternationalKnowledgeObject({
    required this.id,
    required this.officialName,
    required this.shortName,
    required this.acronym,
    this.bodyType = InternationalBodyType.organisation,
    this.category = InternationalCategory.unitedNations,
    this.institutionalStatus = InstitutionalStatus.active,
    this.treatyStatus = TreatyStatus.notApplicable,
    this.membershipType = MembershipType.fullMember,
    this.membershipScope = MembershipScope.global,
    this.decisionMakingModel = DecisionMakingModel.consensus,
    this.fundingModel = FundingModel.memberContributions,
    this.headquarters = '',
    this.headquartersRegion = HeadquartersRegion.globalMultiple,
    this.establishedYear = 0,
    this.foundingTreaty = '',
    this.legalBasis = '',
    this.secretariat = '',
    this.membershipCount,
    this.principalOrgans = '',
    this.leadershipStructure = '',
    this.votingMechanism = '',
    this.mandate = '',
    this.objectives = const [],
    this.functions = const [],
    this.powers = const [],
    this.fundingMechanism = '',
    this.importantProgrammes = const [],
    this.importantConventions = const [],
    this.geographicalRegion = GeographicalRegion.global,
    this.issueAreas = const [],
    this.indiaMembership = IndiaRelationshipStatus.notApplicable,
    this.indiaJoiningYear,
    this.indiaRole = '',
    this.observerStatus = '',
    this.indiaHostedEvents = const [],
    this.indiaInitiatives = const [],
    this.currentRelevance = '',
    this.indiaRelevance = '',
    this.upscRelevance = UpscRelevanceLevel.medium,
    this.prelimsRelevance = RelevanceLevel.medium,
    this.mainsRelevance = RelevanceLevel.medium,
    this.interviewRelevance = RelevanceLevel.medium,
    this.prelimsTraps = const [],
    this.mainsThemes = const [],
    this.essayThemes = const [],
    this.interviewAreas = const [],
    this.relatedArticleIds = const [],
    this.relatedActIds = const [],
    this.relatedCaseLawIds = const [],
    this.relatedDoctrineIds = const [],
    this.relatedCommitteeIds = const [],
    this.relatedReportIds = const [],
    this.relatedSchemeIds = const [],
    this.relatedCurrentAffairsIds = const [],
    this.relatedPyqIds = const [],
    this.relatedOrganisationIds = const [],
    this.sdgGoals = const [],
    this.relationships = const [],
    this.officialSource = '',
    this.evidenceIds = const [],
    this.lastVerifiedDate = '',
    this.keywords = const [],
    this.version = 1,
    this.editorialStatus = EditorialStatus.imported,
    Map<String, dynamic>? metadata,
  }) : metadata = Map<String, dynamic>.from(metadata ?? const {});

  /// Bridge helper converting to the base GARUDA KnowledgeObject for the
  /// Editorial Production Engine (shared GARUDA knowledge registry/index).
  KnowledgeObject toGarudaKnowledgeObject() {
    return KnowledgeObject(
      id: id,
      title: officialName,
      subject: '${bodyType.displayName} — ${category.displayName}',
      topic: acronym.isNotEmpty ? acronym : shortName,
      subtopic: headquarters,
      summary: mandate.isNotEmpty ? mandate : officialName,
      content:
          'Organisation: $officialName ($acronym). Type: ${bodyType.displayName}. Category: ${category.displayName}. Founded: $establishedYear. HQ: $headquarters. Mandate: $mandate. Functions: ${functions.join("; ")}. India: ${indiaMembership.displayName}.',
      officialSource: officialSource,
      evidenceIds: evidenceIds,
      status: editorialStatus,
      version: version,
      package: 'garuda_international',
      knowledgeType: 'InternationalKnowledgeObject',
      relatedArticles: relatedArticleIds,
      relatedCaseLaws: relatedCaseLawIds,
      tags: keywords,
      isVerified: evidenceIds.isNotEmpty &&
          editorialStatus == EditorialStatus.published,
      metadata: {
        ...metadata,
        'bodyType': bodyType.name,
        'category': category.name,
        'establishedYear': establishedYear,
        'headquarters': headquarters,
        'indiaMembership': indiaMembership.name,
        'indiaJoiningYear': indiaJoiningYear,
        'relatedActIds': relatedActIds,
        'relatedCommitteeIds': relatedCommitteeIds,
        'relatedReportIds': relatedReportIds,
        'relatedSchemeIds': relatedSchemeIds,
        'relatedOrganisationIds': relatedOrganisationIds,
        'relatedPyqIds': relatedPyqIds,
        'relatedCurrentAffairsIds': relatedCurrentAffairsIds,
        'officialSource': officialSource,
        'lastVerifiedDate': lastVerifiedDate,
      },
    );
  }

  InternationalKnowledgeObject copyWith({
    String? id,
    String? officialName,
    String? shortName,
    String? acronym,
    InternationalBodyType? bodyType,
    InternationalCategory? category,
    InstitutionalStatus? institutionalStatus,
    TreatyStatus? treatyStatus,
    MembershipType? membershipType,
    MembershipScope? membershipScope,
    DecisionMakingModel? decisionMakingModel,
    FundingModel? fundingModel,
    String? headquarters,
    HeadquartersRegion? headquartersRegion,
    int? establishedYear,
    String? foundingTreaty,
    String? legalBasis,
    String? secretariat,
    int? membershipCount,
    String? principalOrgans,
    String? leadershipStructure,
    String? votingMechanism,
    String? mandate,
    List<String>? objectives,
    List<String>? functions,
    List<String>? powers,
    String? fundingMechanism,
    List<String>? importantProgrammes,
    List<String>? importantConventions,
    GeographicalRegion? geographicalRegion,
    List<GlobalIssueArea>? issueAreas,
    IndiaRelationshipStatus? indiaMembership,
    int? indiaJoiningYear,
    String? indiaRole,
    String? observerStatus,
    List<String>? indiaHostedEvents,
    List<String>? indiaInitiatives,
    String? currentRelevance,
    String? indiaRelevance,
    UpscRelevanceLevel? upscRelevance,
    RelevanceLevel? prelimsRelevance,
    RelevanceLevel? mainsRelevance,
    RelevanceLevel? interviewRelevance,
    List<String>? prelimsTraps,
    List<String>? mainsThemes,
    List<String>? essayThemes,
    List<String>? interviewAreas,
    List<String>? relatedArticleIds,
    List<String>? relatedActIds,
    List<String>? relatedCaseLawIds,
    List<String>? relatedDoctrineIds,
    List<String>? relatedCommitteeIds,
    List<String>? relatedReportIds,
    List<String>? relatedSchemeIds,
    List<String>? relatedCurrentAffairsIds,
    List<String>? relatedPyqIds,
    List<String>? relatedOrganisationIds,
    List<String>? sdgGoals,
    List<InternationalRelationship>? relationships,
    String? officialSource,
    List<String>? evidenceIds,
    String? lastVerifiedDate,
    List<String>? keywords,
    int? version,
    EditorialStatus? editorialStatus,
    Map<String, dynamic>? metadata,
  }) {
    return InternationalKnowledgeObject(
      id: id ?? this.id,
      officialName: officialName ?? this.officialName,
      shortName: shortName ?? this.shortName,
      acronym: acronym ?? this.acronym,
      bodyType: bodyType ?? this.bodyType,
      category: category ?? this.category,
      institutionalStatus: institutionalStatus ?? this.institutionalStatus,
      treatyStatus: treatyStatus ?? this.treatyStatus,
      membershipType: membershipType ?? this.membershipType,
      membershipScope: membershipScope ?? this.membershipScope,
      decisionMakingModel: decisionMakingModel ?? this.decisionMakingModel,
      fundingModel: fundingModel ?? this.fundingModel,
      headquarters: headquarters ?? this.headquarters,
      headquartersRegion: headquartersRegion ?? this.headquartersRegion,
      establishedYear: establishedYear ?? this.establishedYear,
      foundingTreaty: foundingTreaty ?? this.foundingTreaty,
      legalBasis: legalBasis ?? this.legalBasis,
      secretariat: secretariat ?? this.secretariat,
      membershipCount: membershipCount ?? this.membershipCount,
      principalOrgans: principalOrgans ?? this.principalOrgans,
      leadershipStructure: leadershipStructure ?? this.leadershipStructure,
      votingMechanism: votingMechanism ?? this.votingMechanism,
      mandate: mandate ?? this.mandate,
      objectives: objectives ?? List.from(this.objectives),
      functions: functions ?? List.from(this.functions),
      powers: powers ?? List.from(this.powers),
      fundingMechanism: fundingMechanism ?? this.fundingMechanism,
      importantProgrammes:
          importantProgrammes ?? List.from(this.importantProgrammes),
      importantConventions:
          importantConventions ?? List.from(this.importantConventions),
      geographicalRegion: geographicalRegion ?? this.geographicalRegion,
      issueAreas: issueAreas ?? List.from(this.issueAreas),
      indiaMembership: indiaMembership ?? this.indiaMembership,
      indiaJoiningYear: indiaJoiningYear ?? this.indiaJoiningYear,
      indiaRole: indiaRole ?? this.indiaRole,
      observerStatus: observerStatus ?? this.observerStatus,
      indiaHostedEvents: indiaHostedEvents ?? List.from(this.indiaHostedEvents),
      indiaInitiatives: indiaInitiatives ?? List.from(this.indiaInitiatives),
      currentRelevance: currentRelevance ?? this.currentRelevance,
      indiaRelevance: indiaRelevance ?? this.indiaRelevance,
      upscRelevance: upscRelevance ?? this.upscRelevance,
      prelimsRelevance: prelimsRelevance ?? this.prelimsRelevance,
      mainsRelevance: mainsRelevance ?? this.mainsRelevance,
      interviewRelevance: interviewRelevance ?? this.interviewRelevance,
      prelimsTraps: prelimsTraps ?? List.from(this.prelimsTraps),
      mainsThemes: mainsThemes ?? List.from(this.mainsThemes),
      essayThemes: essayThemes ?? List.from(this.essayThemes),
      interviewAreas: interviewAreas ?? List.from(this.interviewAreas),
      relatedArticleIds: relatedArticleIds ?? List.from(this.relatedArticleIds),
      relatedActIds: relatedActIds ?? List.from(this.relatedActIds),
      relatedCaseLawIds: relatedCaseLawIds ?? List.from(this.relatedCaseLawIds),
      relatedDoctrineIds:
          relatedDoctrineIds ?? List.from(this.relatedDoctrineIds),
      relatedCommitteeIds:
          relatedCommitteeIds ?? List.from(this.relatedCommitteeIds),
      relatedReportIds: relatedReportIds ?? List.from(this.relatedReportIds),
      relatedSchemeIds: relatedSchemeIds ?? List.from(this.relatedSchemeIds),
      relatedCurrentAffairsIds:
          relatedCurrentAffairsIds ?? List.from(this.relatedCurrentAffairsIds),
      relatedPyqIds: relatedPyqIds ?? List.from(this.relatedPyqIds),
      relatedOrganisationIds:
          relatedOrganisationIds ?? List.from(this.relatedOrganisationIds),
      sdgGoals: sdgGoals ?? List.from(this.sdgGoals),
      relationships: relationships ?? List.from(this.relationships),
      officialSource: officialSource ?? this.officialSource,
      evidenceIds: evidenceIds ?? List.from(this.evidenceIds),
      lastVerifiedDate: lastVerifiedDate ?? this.lastVerifiedDate,
      keywords: keywords ?? List.from(this.keywords),
      version: version ?? this.version,
      editorialStatus: editorialStatus ?? this.editorialStatus,
      metadata: metadata ?? Map.from(this.metadata),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'officialName': officialName,
        'shortName': shortName,
        'acronym': acronym,
        'bodyType': bodyType.name,
        'category': category.name,
        'institutionalStatus': institutionalStatus.name,
        'treatyStatus': treatyStatus.name,
        'membershipType': membershipType.name,
        'membershipScope': membershipScope.name,
        'decisionMakingModel': decisionMakingModel.name,
        'fundingModel': fundingModel.name,
        'headquarters': headquarters,
        'headquartersRegion': headquartersRegion.name,
        'establishedYear': establishedYear,
        'foundingTreaty': foundingTreaty,
        'legalBasis': legalBasis,
        'secretariat': secretariat,
        'membershipCount': membershipCount,
        'principalOrgans': principalOrgans,
        'leadershipStructure': leadershipStructure,
        'votingMechanism': votingMechanism,
        'mandate': mandate,
        'objectives': objectives,
        'functions': functions,
        'powers': powers,
        'fundingMechanism': fundingMechanism,
        'importantProgrammes': importantProgrammes,
        'importantConventions': importantConventions,
        'geographicalRegion': geographicalRegion.name,
        'issueAreas': issueAreas.map((a) => a.name).toList(),
        'indiaMembership': indiaMembership.name,
        'indiaJoiningYear': indiaJoiningYear,
        'indiaRole': indiaRole,
        'observerStatus': observerStatus,
        'indiaHostedEvents': indiaHostedEvents,
        'indiaInitiatives': indiaInitiatives,
        'currentRelevance': currentRelevance,
        'indiaRelevance': indiaRelevance,
        'upscRelevance': upscRelevance.name,
        'prelimsRelevance': prelimsRelevance.name,
        'mainsRelevance': mainsRelevance.name,
        'interviewRelevance': interviewRelevance.name,
        'prelimsTraps': prelimsTraps,
        'mainsThemes': mainsThemes,
        'essayThemes': essayThemes,
        'interviewAreas': interviewAreas,
        'relatedArticleIds': relatedArticleIds,
        'relatedActIds': relatedActIds,
        'relatedCaseLawIds': relatedCaseLawIds,
        'relatedDoctrineIds': relatedDoctrineIds,
        'relatedCommitteeIds': relatedCommitteeIds,
        'relatedReportIds': relatedReportIds,
        'relatedSchemeIds': relatedSchemeIds,
        'relatedCurrentAffairsIds': relatedCurrentAffairsIds,
        'relatedPyqIds': relatedPyqIds,
        'relatedOrganisationIds': relatedOrganisationIds,
        'sdgGoals': sdgGoals,
        'relationships': relationships.map((r) => r.toJson()).toList(),
        'officialSource': officialSource,
        'evidenceIds': evidenceIds,
        'lastVerifiedDate': lastVerifiedDate,
        'keywords': keywords,
        'version': version,
        'editorialStatus': editorialStatus.name,
        'metadata': metadata,
      };

  factory InternationalKnowledgeObject.fromJson(Map<String, dynamic> json) =>
      InternationalKnowledgeObject(
        id: json['id'] as String? ?? '',
        officialName: json['officialName'] as String? ?? '',
        shortName: json['shortName'] as String? ?? '',
        acronym: json['acronym'] as String? ?? '',
        bodyType: InternationalBodyType.values.firstWhere(
          (t) => t.name == json['bodyType'],
          orElse: () => InternationalBodyType.organisation,
        ),
        category: InternationalCategory.values.firstWhere(
          (c) => c.name == json['category'],
          orElse: () => InternationalCategory.unitedNations,
        ),
        institutionalStatus: InstitutionalStatus.values.firstWhere(
          (s) => s.name == json['institutionalStatus'],
          orElse: () => InstitutionalStatus.active,
        ),
        treatyStatus: TreatyStatus.values.firstWhere(
          (t) => t.name == json['treatyStatus'],
          orElse: () => TreatyStatus.notApplicable,
        ),
        membershipType: MembershipType.values.firstWhere(
          (m) => m.name == json['membershipType'],
          orElse: () => MembershipType.fullMember,
        ),
        membershipScope: MembershipScope.values.firstWhere(
          (m) => m.name == json['membershipScope'],
          orElse: () => MembershipScope.global,
        ),
        decisionMakingModel: DecisionMakingModel.values.firstWhere(
          (d) => d.name == json['decisionMakingModel'],
          orElse: () => DecisionMakingModel.consensus,
        ),
        fundingModel: FundingModel.values.firstWhere(
          (f) => f.name == json['fundingModel'],
          orElse: () => FundingModel.memberContributions,
        ),
        headquarters: json['headquarters'] as String? ?? '',
        headquartersRegion: HeadquartersRegion.values.firstWhere(
          (h) => h.name == json['headquartersRegion'],
          orElse: () => HeadquartersRegion.globalMultiple,
        ),
        establishedYear: (json['establishedYear'] as num?)?.toInt() ?? 0,
        foundingTreaty: json['foundingTreaty'] as String? ?? '',
        legalBasis: json['legalBasis'] as String? ?? '',
        secretariat: json['secretariat'] as String? ?? '',
        membershipCount: (json['membershipCount'] as num?)?.toInt(),
        principalOrgans: json['principalOrgans'] as String? ?? '',
        leadershipStructure: json['leadershipStructure'] as String? ?? '',
        votingMechanism: json['votingMechanism'] as String? ?? '',
        mandate: json['mandate'] as String? ?? '',
        objectives:
            (json['objectives'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        functions:
            (json['functions'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        powers: (json['powers'] as List?)?.map((e) => e.toString()).toList() ??
            const [],
        fundingMechanism: json['fundingMechanism'] as String? ?? '',
        importantProgrammes: (json['importantProgrammes'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        importantConventions: (json['importantConventions'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        geographicalRegion: GeographicalRegion.values.firstWhere(
          (g) => g.name == json['geographicalRegion'],
          orElse: () => GeographicalRegion.global,
        ),
        issueAreas: (json['issueAreas'] as List?)
                ?.map((e) => GlobalIssueArea.values.firstWhere(
                      (a) => a.name == e,
                      orElse: () => GlobalIssueArea.governance,
                    ))
                .toList() ??
            const [],
        indiaMembership: IndiaRelationshipStatus.values.firstWhere(
          (s) => s.name == json['indiaMembership'],
          orElse: () => IndiaRelationshipStatus.notApplicable,
        ),
        indiaJoiningYear: (json['indiaJoiningYear'] as num?)?.toInt(),
        indiaRole: json['indiaRole'] as String? ?? '',
        observerStatus: json['observerStatus'] as String? ?? '',
        indiaHostedEvents: (json['indiaHostedEvents'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        indiaInitiatives: (json['indiaInitiatives'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        currentRelevance: json['currentRelevance'] as String? ?? '',
        indiaRelevance: json['indiaRelevance'] as String? ?? '',
        upscRelevance: UpscRelevanceLevel.values.firstWhere(
          (u) => u.name == json['upscRelevance'],
          orElse: () => UpscRelevanceLevel.medium,
        ),
        prelimsRelevance: RelevanceLevel.values.firstWhere(
          (r) => r.name == json['prelimsRelevance'],
          orElse: () => RelevanceLevel.medium,
        ),
        mainsRelevance: RelevanceLevel.values.firstWhere(
          (r) => r.name == json['mainsRelevance'],
          orElse: () => RelevanceLevel.medium,
        ),
        interviewRelevance: RelevanceLevel.values.firstWhere(
          (r) => r.name == json['interviewRelevance'],
          orElse: () => RelevanceLevel.medium,
        ),
        prelimsTraps: (json['prelimsTraps'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        mainsThemes: (json['mainsThemes'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        essayThemes: (json['essayThemes'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        interviewAreas: (json['interviewAreas'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        relatedArticleIds: (json['relatedArticleIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        relatedActIds: (json['relatedActIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        relatedCaseLawIds: (json['relatedCaseLawIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        relatedDoctrineIds: (json['relatedDoctrineIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        relatedCommitteeIds: (json['relatedCommitteeIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        relatedReportIds: (json['relatedReportIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        relatedSchemeIds: (json['relatedSchemeIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        relatedCurrentAffairsIds: (json['relatedCurrentAffairsIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        relatedPyqIds: (json['relatedPyqIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        relatedOrganisationIds: (json['relatedOrganisationIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        sdgGoals:
            (json['sdgGoals'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        relationships: (json['relationships'] as List?)
                ?.map((r) => InternationalRelationship.fromJson(
                    Map<String, dynamic>.from(r as Map)))
                .toList() ??
            const [],
        officialSource: json['officialSource'] as String? ?? '',
        evidenceIds: (json['evidenceIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        lastVerifiedDate: json['lastVerifiedDate'] as String? ?? '',
        keywords:
            (json['keywords'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        version: (json['version'] as num?)?.toInt() ?? 1,
        editorialStatus: EditorialStatus.values.firstWhere(
          (s) => s.name == json['editorialStatus'],
          orElse: () => EditorialStatus.imported,
        ),
        metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      );
}
