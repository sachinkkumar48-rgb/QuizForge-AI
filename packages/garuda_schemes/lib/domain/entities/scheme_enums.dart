library;

/// Classification of a Government Scheme by the structure of funding &
/// implementation (used to drive the funding graph).
enum SchemeType {
  centralSector,
  centrallySponsored,
  flagshipMission,
  planScheme,
  nonPlanScheme,
  externallyAided,
}

extension SchemeTypeExtension on SchemeType {
  String get displayName {
    switch (this) {
      case SchemeType.centralSector:
        return 'Central Sector Scheme';
      case SchemeType.centrallySponsored:
        return 'Centrally Sponsored Scheme';
      case SchemeType.flagshipMission:
        return 'Flagship Mission';
      case SchemeType.planScheme:
        return 'Plan Scheme';
      case SchemeType.nonPlanScheme:
        return 'Non-Plan Scheme';
      case SchemeType.externallyAided:
        return 'Externally Aided Project';
    }
  }
}

/// Broad sector classification of a Scheme, aligned to the UPSC/State PSC syllabus.
enum SchemeCategory {
  agriculture,
  ruralDevelopment,
  urbanDevelopment,
  health,
  education,
  skillDevelopment,
  employment,
  financialInclusion,
  socialSecurity,
  housing,
  waterSanitation,
  environment,
  energy,
  digitalGovernance,
  industry,
  infrastructure,
  logistics,
  scienceTechnology,
  womenChildDevelopment,
  foodSecurity,
  tribalDevelopment,
}

extension SchemeCategoryExtension on SchemeCategory {
  String get displayName {
    switch (this) {
      case SchemeCategory.agriculture:
        return 'Agriculture & Farmers Welfare';
      case SchemeCategory.ruralDevelopment:
        return 'Rural Development';
      case SchemeCategory.urbanDevelopment:
        return 'Urban Development';
      case SchemeCategory.health:
        return 'Health & Family Welfare';
      case SchemeCategory.education:
        return 'Education & Nutrition';
      case SchemeCategory.skillDevelopment:
        return 'Skill Development & Entrepreneurship';
      case SchemeCategory.employment:
        return 'Employment & Labour';
      case SchemeCategory.financialInclusion:
        return 'Financial Inclusion & Banking';
      case SchemeCategory.socialSecurity:
        return 'Social Security & Insurance';
      case SchemeCategory.housing:
        return 'Housing & Shelter';
      case SchemeCategory.waterSanitation:
        return 'Water & Sanitation';
      case SchemeCategory.environment:
        return 'Environment, Forest & Climate';
      case SchemeCategory.energy:
        return 'Energy & Renewable Energy';
      case SchemeCategory.digitalGovernance:
        return 'Digital Governance & Telecom';
      case SchemeCategory.industry:
        return 'Industry, Manufacturing & Trade';
      case SchemeCategory.infrastructure:
        return 'Infrastructure & Connectivity';
      case SchemeCategory.logistics:
        return 'Logistics & Supply Chain';
      case SchemeCategory.scienceTechnology:
        return 'Science, Innovation & Technology';
      case SchemeCategory.womenChildDevelopment:
        return 'Women & Child Development';
      case SchemeCategory.foodSecurity:
        return 'Food & Public Distribution';
      case SchemeCategory.tribalDevelopment:
        return 'Tribal Development';
    }
  }
}

/// Operational status of a Government Scheme (drives "outdated status" validation).
enum SchemeStatus {
  launched,
  operational,
  restructured,
  subsumed,
  discontinued,
  proposed,
}

extension SchemeStatusExtension on SchemeStatus {
  String get displayName {
    switch (this) {
      case SchemeStatus.launched:
        return 'Launched';
      case SchemeStatus.operational:
        return 'Operational';
      case SchemeStatus.restructured:
        return 'Restructured / Reconfigured';
      case SchemeStatus.subsumed:
        return 'Subsumed into Umbrella Scheme';
      case SchemeStatus.discontinued:
        return 'Discontinued / Closed';
      case SchemeStatus.proposed:
        return 'Proposed / Under Formulation';
    }
  }

  /// True if the scheme is no longer receiving fresh allocations.
  bool get isClosed =>
      this == SchemeStatus.subsumed || this == SchemeStatus.discontinued;
}

/// Structure of cost-sharing between Centre and States (funding graph edge).
enum FundingPatternType {
  fullCentral,
  sharedCentreState,
  primarilyState,
  loanBased,
  subsidyIncentive,
  viabilityGap,
}

extension FundingPatternTypeExtension on FundingPatternType {
  String get displayName {
    switch (this) {
      case FundingPatternType.fullCentral:
        return '100% Central Funding';
      case FundingPatternType.sharedCentreState:
        return 'Centre-State Shared';
      case FundingPatternType.primarilyState:
        return 'Primarily State-funded';
      case FundingPatternType.loanBased:
        return 'Loan / Financing-based';
      case FundingPatternType.subsidyIncentive:
        return 'Subsidy / Incentive-linked';
      case FundingPatternType.viabilityGap:
        return 'Viability Gap Funding';
    }
  }
}

/// Level at which a Scheme is administered (implementation graph edge).
enum SchemeImplementationLevel {
  central,
  state,
  district,
  localBody,
  community,
}

extension SchemeImplementationLevelExtension on SchemeImplementationLevel {
  String get displayName {
    switch (this) {
      case SchemeImplementationLevel.central:
        return 'Central Level';
      case SchemeImplementationLevel.state:
        return 'State Level';
      case SchemeImplementationLevel.district:
        return 'District Level';
      case SchemeImplementationLevel.localBody:
        return 'Local Body / Panchayat / ULB';
      case SchemeImplementationLevel.community:
        return 'Community / SHG / Institution';
    }
  }
}

/// Nature of the benefit delivered to the beneficiary.
enum SchemeBenefitType {
  monetary,
  directBenefitTransfer,
  kind,
  service,
  subsidy,
  insurance,
  credit,
  infrastructure,
}

extension SchemeBenefitTypeExtension on SchemeBenefitType {
  String get displayName {
    switch (this) {
      case SchemeBenefitType.monetary:
        return 'Monetary Transfer';
      case SchemeBenefitType.directBenefitTransfer:
        return 'Direct Benefit Transfer';
      case SchemeBenefitType.kind:
        return 'In-kind Benefit';
      case SchemeBenefitType.service:
        return 'Service Provision';
      case SchemeBenefitType.subsidy:
        return 'Subsidy / Concession';
      case SchemeBenefitType.insurance:
        return 'Insurance Cover';
      case SchemeBenefitType.credit:
        return 'Credit / Loan Access';
      case SchemeBenefitType.infrastructure:
        return 'Infrastructure Provision';
    }
  }
}

/// Manner in which budgeted funds are released / disbursed.
enum BudgetAllocationType {
  allocation,
  revisedEstimate,
  actualExpenditure,
  performanceLinked,
}

/// The 17 United Nations Sustainable Development Goals, as graph link targets.
enum SdgGoal {
  noPoverty,
  zeroHunger,
  goodHealth,
  qualityEducation,
  genderEquality,
  cleanWater,
  affordableCleanEnergy,
  decentWork,
  industryInnovation,
  reducedInequalities,
  sustainableCities,
  responsibleConsumption,
  climateAction,
  lifeBelowWater,
  lifeOnLand,
  peaceJustice,
  partnerships,
}

extension SdgGoalExtension on SdgGoal {
  String get displayName {
    switch (this) {
      case SdgGoal.noPoverty:
        return 'SDG 1 - No Poverty';
      case SdgGoal.zeroHunger:
        return 'SDG 2 - Zero Hunger';
      case SdgGoal.goodHealth:
        return 'SDG 3 - Good Health & Well-being';
      case SdgGoal.qualityEducation:
        return 'SDG 4 - Quality Education';
      case SdgGoal.genderEquality:
        return 'SDG 5 - Gender Equality';
      case SdgGoal.cleanWater:
        return 'SDG 6 - Clean Water & Sanitation';
      case SdgGoal.affordableCleanEnergy:
        return 'SDG 7 - Affordable & Clean Energy';
      case SdgGoal.decentWork:
        return 'SDG 8 - Decent Work & Economic Growth';
      case SdgGoal.industryInnovation:
        return 'SDG 9 - Industry, Innovation & Infrastructure';
      case SdgGoal.reducedInequalities:
        return 'SDG 10 - Reduced Inequalities';
      case SdgGoal.sustainableCities:
        return 'SDG 11 - Sustainable Cities & Communities';
      case SdgGoal.responsibleConsumption:
        return 'SDG 12 - Responsible Consumption & Production';
      case SdgGoal.climateAction:
        return 'SDG 13 - Climate Action';
      case SdgGoal.lifeBelowWater:
        return 'SDG 14 - Life Below Water';
      case SdgGoal.lifeOnLand:
        return 'SDG 15 - Life on Land';
      case SdgGoal.peaceJustice:
        return 'SDG 16 - Peace, Justice & Strong Institutions';
      case SdgGoal.partnerships:
        return 'SDG 17 - Partnerships for the Goals';
    }
  }
}

/// Relationship link types in the Government Schemes Knowledge Graph.
enum SchemeRelationshipType {
  subsumedBy,
  replacedBy,
  restructuredInto,
  predecessorOf,
  fundedBy,
  linkedToAct,
  linkedToArticle,
  linkedToCommittee,
  linkedToReport,
  linkedToCaseLaw,
  linkedToDoctrine,
  linkedToPyq,
  linkedToCurrentAffairs,
  linkedToSdg,
  linkedToComponent,
}

/// Broad economic/social sector of a Scheme, aligned to the UPSC syllabus
/// and used as a first-class analytics & filtering dimension.
enum SchemeSector {
  agriculture,
  ruralDevelopment,
  health,
  education,
  womenChildDevelopment,
  socialJustice,
  tribalDevelopment,
  employment,
  skillDevelopment,
  financialInclusion,
  housing,
  waterSanitation,
  energy,
  infrastructure,
  environment,
  digitalGovernance,
  foodSecurity,
  msmeIndustry,
  scienceTechnology,
}

extension SchemeSectorExtension on SchemeSector {
  String get displayName {
    switch (this) {
      case SchemeSector.agriculture:
        return 'Agriculture & Allied Sectors';
      case SchemeSector.ruralDevelopment:
        return 'Rural Development';
      case SchemeSector.health:
        return 'Health & Family Welfare';
      case SchemeSector.education:
        return 'Education & Nutrition';
      case SchemeSector.womenChildDevelopment:
        return 'Women & Child Development';
      case SchemeSector.socialJustice:
        return 'Social Justice & Empowerment';
      case SchemeSector.tribalDevelopment:
        return 'Tribal Development';
      case SchemeSector.employment:
        return 'Employment & Labour Welfare';
      case SchemeSector.skillDevelopment:
        return 'Skill Development & Entrepreneurship';
      case SchemeSector.financialInclusion:
        return 'Financial Inclusion & Social Security';
      case SchemeSector.housing:
        return 'Housing & Urban Affairs';
      case SchemeSector.waterSanitation:
        return 'Water, Sanitation & Jal Shakti';
      case SchemeSector.energy:
        return 'Energy & Renewable Energy';
      case SchemeSector.infrastructure:
        return 'Infrastructure & Connectivity';
      case SchemeSector.environment:
        return 'Environment, Forest & Climate Change';
      case SchemeSector.digitalGovernance:
        return 'Digital Governance & IT';
      case SchemeSector.foodSecurity:
        return 'Food Security & Public Distribution';
      case SchemeSector.msmeIndustry:
        return 'MSME, Industry & Manufacturing';
      case SchemeSector.scienceTechnology:
        return 'Science, Innovation & Technology';
    }
  }
}

/// Geographic applicability of a Scheme for benefit delivery.
enum RuralUrbanScope {
  rural,
  urban,
  both,
}

extension RuralUrbanScopeExtension on RuralUrbanScope {
  String get displayName {
    switch (this) {
      case RuralUrbanScope.rural:
        return 'Rural';
      case RuralUrbanScope.urban:
        return 'Urban';
      case RuralUrbanScope.both:
        return 'Rural & Urban';
    }
  }
}
