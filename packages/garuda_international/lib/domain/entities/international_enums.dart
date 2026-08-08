library;

/// Institutional character of an international body.
enum InternationalBodyType {
  organisation,
  treatyBody,
  financialInstitution,
  developmentBank,
  forum,
  grouping,
  alliance,
  regulatoryCoordinatingInstitution,
  conventionFramework,
  initiative,
  specialisedAgency,
  programme,
  fund,
}

extension InternationalBodyTypeExtension on InternationalBodyType {
  String get displayName {
    switch (this) {
      case InternationalBodyType.organisation:
        return 'Organisation';
      case InternationalBodyType.treatyBody:
        return 'Treaty Body';
      case InternationalBodyType.financialInstitution:
        return 'Financial Institution';
      case InternationalBodyType.developmentBank:
        return 'Development Bank';
      case InternationalBodyType.forum:
        return 'Forum';
      case InternationalBodyType.grouping:
        return 'Grouping';
      case InternationalBodyType.alliance:
        return 'Alliance';
      case InternationalBodyType.regulatoryCoordinatingInstitution:
        return 'Regulatory / Coordinating Institution';
      case InternationalBodyType.conventionFramework:
        return 'Convention / Framework';
      case InternationalBodyType.initiative:
        return 'Initiative';
      case InternationalBodyType.specialisedAgency:
        return 'UN Specialised Agency';
      case InternationalBodyType.programme:
        return 'UN Programme / Fund';
      case InternationalBodyType.fund:
        return 'Fund';
    }
  }
}

/// Broad institutional category of an international body.
enum InternationalCategory {
  unitedNations,
  brettonWoods,
  tradeOrganization,
  economicGovernance,
  regionalGrouping,
  securityAlliance,
  climateEnvironment,
  developmentBank,
  specializedAgency,
  forum,
  financialInstitution,
  treatyBody,
  disarmament,
  initiative,
}

extension InternationalCategoryExtension on InternationalCategory {
  String get displayName {
    switch (this) {
      case InternationalCategory.unitedNations:
        return 'United Nations System';
      case InternationalCategory.brettonWoods:
        return 'Bretton Woods / Global Financial Institution';
      case InternationalCategory.tradeOrganization:
        return 'Trade Organisation';
      case InternationalCategory.economicGovernance:
        return 'Economic Governance';
      case InternationalCategory.regionalGrouping:
        return 'Regional / Political Grouping';
      case InternationalCategory.securityAlliance:
        return 'Security / Strategic Organisation';
      case InternationalCategory.climateEnvironment:
        return 'Climate / Environment Institution';
      case InternationalCategory.developmentBank:
        return 'Development Bank';
      case InternationalCategory.specializedAgency:
        return 'Specialised Agency';
      case InternationalCategory.forum:
        return 'Forum';
      case InternationalCategory.financialInstitution:
        return 'Financial Institution';
      case InternationalCategory.treatyBody:
        return 'Treaty Body';
      case InternationalCategory.disarmament:
        return 'Disarmament / Non-Proliferation';
      case InternationalCategory.initiative:
        return 'Initiative';
    }
  }
}

/// Type of membership an entity holds in an international body.
enum MembershipType {
  fullMember,
  observer,
  partner,
  associate,
  nonMember,
}

extension MembershipTypeExtension on MembershipType {
  String get displayName {
    switch (this) {
      case MembershipType.fullMember:
        return 'Full Member';
      case MembershipType.observer:
        return 'Observer';
      case MembershipType.partner:
        return 'Partner';
      case MembershipType.associate:
        return 'Associate';
      case MembershipType.nonMember:
        return 'Non-Member';
    }
  }
}

/// Geographic/structural scope of membership.
enum MembershipScope {
  global,
  regional,
  subRegional,
  selective,
  indiaCentric,
}

extension MembershipScopeExtension on MembershipScope {
  String get displayName {
    switch (this) {
      case MembershipScope.global:
        return 'Global';
      case MembershipScope.regional:
        return 'Regional';
      case MembershipScope.subRegional:
        return 'Sub-regional';
      case MembershipScope.selective:
        return 'Selective / Closed';
      case MembershipScope.indiaCentric:
        return 'India-centric Initiative';
    }
  }
}

/// Status of India in the body.
enum IndiaRelationshipStatus {
  foundingMember,
  fullMember,
  observer,
  dialoguePartner,
  strategicPartner,
  associationMember,
  nonMember,
  notApplicable,
}

extension IndiaRelationshipStatusExtension on IndiaRelationshipStatus {
  String get displayName {
    switch (this) {
      case IndiaRelationshipStatus.foundingMember:
        return 'Founding Member';
      case IndiaRelationshipStatus.fullMember:
        return 'Full Member';
      case IndiaRelationshipStatus.observer:
        return 'Observer';
      case IndiaRelationshipStatus.dialoguePartner:
        return 'Dialogue Partner';
      case IndiaRelationshipStatus.strategicPartner:
        return 'Strategic Partner';
      case IndiaRelationshipStatus.associationMember:
        return 'Association Member';
      case IndiaRelationshipStatus.nonMember:
        return 'Non-Member';
      case IndiaRelationshipStatus.notApplicable:
        return 'Not Applicable';
    }
  }
}

/// Region in which the body's headquarters is located.
enum HeadquartersRegion {
  northAmerica,
  europe,
  africa,
  asia,
  southAsia,
  middleEast,
  latinAmerica,
  oceania,
  globalMultiple,
  india,
}

extension HeadquartersRegionExtension on HeadquartersRegion {
  String get displayName {
    switch (this) {
      case HeadquartersRegion.northAmerica:
        return 'North America';
      case HeadquartersRegion.europe:
        return 'Europe';
      case HeadquartersRegion.africa:
        return 'Africa';
      case HeadquartersRegion.asia:
        return 'Asia';
      case HeadquartersRegion.southAsia:
        return 'South Asia';
      case HeadquartersRegion.middleEast:
        return 'Middle East / West Asia';
      case HeadquartersRegion.latinAmerica:
        return 'Latin America';
      case HeadquartersRegion.oceania:
        return 'Oceania';
      case HeadquartersRegion.globalMultiple:
        return 'No Fixed HQ / Rotating';
      case HeadquartersRegion.india:
        return 'India';
    }
  }
}

/// Primary decision-making model of the body.
enum DecisionMakingModel {
  consensus,
  weightedVoting,
  oneMemberOneVote,
  vetoBased,
  executiveBoard,
  hybrid,
}

extension DecisionMakingModelExtension on DecisionMakingModel {
  String get displayName {
    switch (this) {
      case DecisionMakingModel.consensus:
        return 'Consensus';
      case DecisionMakingModel.weightedVoting:
        return 'Weighted Voting';
      case DecisionMakingModel.oneMemberOneVote:
        return 'One Member, One Vote';
      case DecisionMakingModel.vetoBased:
        return 'Veto-based (Permanent Members)';
      case DecisionMakingModel.executiveBoard:
        return 'Executive Board';
      case DecisionMakingModel.hybrid:
        return 'Hybrid';
    }
  }
}

/// Funding model of the body.
enum FundingModel {
  assessedContributions,
  voluntaryContributions,
  memberContributions,
  capitalSubscriptions,
  combination,
  selfFinancing,
  notApplicable,
}

extension FundingModelExtension on FundingModel {
  String get displayName {
    switch (this) {
      case FundingModel.assessedContributions:
        return 'Assessed Contributions';
      case FundingModel.voluntaryContributions:
        return 'Voluntary Contributions';
      case FundingModel.memberContributions:
        return 'Member Contributions';
      case FundingModel.capitalSubscriptions:
        return 'Capital Subscriptions';
      case FundingModel.combination:
        return 'Combination';
      case FundingModel.selfFinancing:
        return 'Self-financing';
      case FundingModel.notApplicable:
        return 'Not Applicable';
    }
  }
}

/// Treaty/legal status of the body.
enum TreatyStatus {
  establishedByCharter,
  establishedByConvention,
  establishedByTreaty,
  establishedByResolution,
  establishedByAgreement,
  notApplicable,
}

extension TreatyStatusExtension on TreatyStatus {
  String get displayName {
    switch (this) {
      case TreatyStatus.establishedByCharter:
        return 'Established by Charter';
      case TreatyStatus.establishedByConvention:
        return 'Established by Convention';
      case TreatyStatus.establishedByTreaty:
        return 'Established by Treaty';
      case TreatyStatus.establishedByResolution:
        return 'Established by Resolution';
      case TreatyStatus.establishedByAgreement:
        return 'Established by Agreement';
      case TreatyStatus.notApplicable:
        return 'Not Applicable';
    }
  }
}

/// Operational status of the body.
enum InstitutionalStatus {
  active,
  suspended,
  defunct,
  reformed,
}

extension InstitutionalStatusExtension on InstitutionalStatus {
  String get displayName {
    switch (this) {
      case InstitutionalStatus.active:
        return 'Active';
      case InstitutionalStatus.suspended:
        return 'Suspended';
      case InstitutionalStatus.defunct:
        return 'Defunct / Superseded';
      case InstitutionalStatus.reformed:
        return 'Reformed';
    }
  }
}

/// Broad geographical region of the body's scope.
enum GeographicalRegion {
  global,
  europe,
  asia,
  africa,
  middleEast,
  latinAmerica,
  indoPacific,
  eurasia,
  southAsia,
  northAmerica,
  oceania,
}

extension GeographicalRegionExtension on GeographicalRegion {
  String get displayName {
    switch (this) {
      case GeographicalRegion.global:
        return 'Global';
      case GeographicalRegion.europe:
        return 'Europe';
      case GeographicalRegion.asia:
        return 'Asia';
      case GeographicalRegion.africa:
        return 'Africa';
      case GeographicalRegion.middleEast:
        return 'Middle East / West Asia';
      case GeographicalRegion.latinAmerica:
        return 'Latin America';
      case GeographicalRegion.indoPacific:
        return 'Indo-Pacific';
      case GeographicalRegion.eurasia:
        return 'Eurasia';
      case GeographicalRegion.southAsia:
        return 'South Asia';
      case GeographicalRegion.northAmerica:
        return 'North America';
      case GeographicalRegion.oceania:
        return 'Oceania';
    }
  }
}

/// Global issue area in which the body operates.
enum GlobalIssueArea {
  peaceSecurity,
  disarmament,
  economy,
  trade,
  finance,
  development,
  health,
  environment,
  climate,
  humanRights,
  labour,
  maritime,
  aviation,
  telecom,
  intellectualProperty,
  energy,
  food,
  agriculture,
  technology,
  refugeesMigration,
  education,
  culture,
  governance,
  disasterRisk,
  infrastructure,
  space,
  oceans,
  nuclear,
  biodiversity,
  counterTerrorism,
  antiMoneyLaundering,
  solarEnergy,
}

extension GlobalIssueAreaExtension on GlobalIssueArea {
  String get displayName {
    switch (this) {
      case GlobalIssueArea.peaceSecurity:
        return 'Peace & Security';
      case GlobalIssueArea.disarmament:
        return 'Disarmament & Non-proliferation';
      case GlobalIssueArea.economy:
        return 'Economy';
      case GlobalIssueArea.trade:
        return 'Trade';
      case GlobalIssueArea.finance:
        return 'Finance';
      case GlobalIssueArea.development:
        return 'Development';
      case GlobalIssueArea.health:
        return 'Health';
      case GlobalIssueArea.environment:
        return 'Environment';
      case GlobalIssueArea.climate:
        return 'Climate';
      case GlobalIssueArea.humanRights:
        return 'Human Rights';
      case GlobalIssueArea.labour:
        return 'Labour';
      case GlobalIssueArea.maritime:
        return 'Maritime';
      case GlobalIssueArea.aviation:
        return 'Civil Aviation';
      case GlobalIssueArea.telecom:
        return 'Telecommunications';
      case GlobalIssueArea.intellectualProperty:
        return 'Intellectual Property';
      case GlobalIssueArea.energy:
        return 'Energy';
      case GlobalIssueArea.food:
        return 'Food & Nutrition';
      case GlobalIssueArea.agriculture:
        return 'Agriculture';
      case GlobalIssueArea.technology:
        return 'Technology';
      case GlobalIssueArea.refugeesMigration:
        return 'Refugees & Migration';
      case GlobalIssueArea.education:
        return 'Education';
      case GlobalIssueArea.culture:
        return 'Culture';
      case GlobalIssueArea.governance:
        return 'Governance';
      case GlobalIssueArea.disasterRisk:
        return 'Disaster Risk Reduction';
      case GlobalIssueArea.infrastructure:
        return 'Infrastructure';
      case GlobalIssueArea.space:
        return 'Space';
      case GlobalIssueArea.oceans:
        return 'Oceans';
      case GlobalIssueArea.nuclear:
        return 'Nuclear Governance';
      case GlobalIssueArea.biodiversity:
        return 'Biodiversity';
      case GlobalIssueArea.counterTerrorism:
        return 'Counter-terrorism';
      case GlobalIssueArea.antiMoneyLaundering:
        return 'Anti-money-laundering';
      case GlobalIssueArea.solarEnergy:
        return 'Solar Energy';
    }
  }
}

/// Overall UPSC exam relevance of the body.
enum UpscRelevanceLevel {
  high,
  medium,
  low,
  none,
}

extension UpscRelevanceLevelExtension on UpscRelevanceLevel {
  String get displayName {
    switch (this) {
      case UpscRelevanceLevel.high:
        return 'High';
      case UpscRelevanceLevel.medium:
        return 'Medium';
      case UpscRelevanceLevel.low:
        return 'Low';
      case UpscRelevanceLevel.none:
        return 'None';
    }
  }
}

/// Relevance level for a specific exam stage (Prelims / Mains / Essay / Interview).
enum RelevanceLevel {
  high,
  medium,
  low,
  none,
}

extension RelevanceLevelExtension on RelevanceLevel {
  String get displayName {
    switch (this) {
      case RelevanceLevel.high:
        return 'High';
      case RelevanceLevel.medium:
        return 'Medium';
      case RelevanceLevel.low:
        return 'Low';
      case RelevanceLevel.none:
        return 'None';
    }
  }
}

/// Relationship link types in the International Knowledge Graph.
enum InternationalRelationshipType {
  memberOf,
  observerAt,
  cooperatesWith,
  parentOf,
  fundedBy,
  reportsTo,
  partnerOf,
  successorOf,
  predecessorOf,
  establishedBy,
  linkedToTreaty,
  linkedToConvention,
  regulates,
  relatedTo,
}
