library;

/// Legal/constitutional character of a Government Body.
enum BodyType {
  constitutional,
  statutory,
  regulatory,
  quasiJudicial,
  executive,
}

extension BodyTypeExtension on BodyType {
  String get displayName {
    switch (this) {
      case BodyType.constitutional:
        return 'Constitutional Body';
      case BodyType.statutory:
        return 'Statutory Body';
      case BodyType.regulatory:
        return 'Regulatory Body';
      case BodyType.quasiJudicial:
        return 'Quasi-Judicial Body';
      case BodyType.executive:
        return 'Executive / Advisory Body';
    }
  }
}

/// Institutional form of a Government Body.
enum BodyCategory {
  commission,
  authority,
  board,
  tribunal,
  office,
  bank,
  regulator,
  council,
  agency,
  institution,
}

extension BodyCategoryExtension on BodyCategory {
  String get displayName {
    switch (this) {
      case BodyCategory.commission:
        return 'Commission';
      case BodyCategory.authority:
        return 'Authority';
      case BodyCategory.board:
        return 'Board';
      case BodyCategory.tribunal:
        return 'Tribunal';
      case BodyCategory.office:
        return 'Constitutional/Statutory Office';
      case BodyCategory.bank:
        return 'Bank / Financial Institution';
      case BodyCategory.regulator:
        return 'Regulator';
      case BodyCategory.council:
        return 'Council';
      case BodyCategory.agency:
        return 'Agency';
      case BodyCategory.institution:
        return 'Institution';
    }
  }
}

/// Constitutional provenance of the body.
enum ConstitutionalBasis {
  /// Established directly by a constitutional Article (e.g. ECI under Art 324).
  directArticle,

  /// Established pursuant to a constitutional mandate (e.g. NCSC under Art 338).
  constitutionalMandate,

  /// Constitutional framework of which the body is part (e.g. State Finance
  /// Commissions under Art 243I).
  derived,

  /// No direct constitutional basis.
  none,
}

extension ConstitutionalBasisExtension on ConstitutionalBasis {
  String get displayName {
    switch (this) {
      case ConstitutionalBasis.directArticle:
        return 'Established directly by a Constitutional Article';
      case ConstitutionalBasis.constitutionalMandate:
        return 'Established under a Constitutional Mandate';
      case ConstitutionalBasis.derived:
        return 'Derived from Constitutional Provisions';
      case ConstitutionalBasis.none:
        return 'No Direct Constitutional Basis';
    }
  }
}

/// Statutory/executive provenance of the body.
enum StatutoryBasis {
  parliamentaryAct,
  stateAct,
  executiveResolution,
  constitutionItself,
  internationalTreaty,
  none,
}

extension StatutoryBasisExtension on StatutoryBasis {
  String get displayName {
    switch (this) {
      case StatutoryBasis.parliamentaryAct:
        return 'Created by an Act of Parliament';
      case StatutoryBasis.stateAct:
        return 'Created by a State Act';
      case StatutoryBasis.executiveResolution:
        return 'Created by Executive Resolution / Order';
      case StatutoryBasis.constitutionItself:
        return 'The Constitution itself is the basis';
      case StatutoryBasis.internationalTreaty:
        return 'Created pursuant to an International Treaty';
      case StatutoryBasis.none:
        return 'No Statutory Basis';
    }
  }
}

/// Geographic/jurisdictional scope of the body.
enum BodyJurisdiction {
  national,
  state,
  unionTerritory,
  concurrent,
  international,
}

extension BodyJurisdictionExtension on BodyJurisdiction {
  String get displayName {
    switch (this) {
      case BodyJurisdiction.national:
        return 'National';
      case BodyJurisdiction.state:
        return 'State';
      case BodyJurisdiction.unionTerritory:
        return 'Union Territory';
      case BodyJurisdiction.concurrent:
        return 'Concurrent / Multi-level';
      case BodyJurisdiction.international:
        return 'International';
    }
  }
}

/// Authority that appoints the body/its members.
enum AppointmentAuthority {
  president,
  primeMinister,
  parliament,
  governor,
  chiefJustice,
  unionCouncilOfMinisters,
  concernedMinistry,
  financeMinistry,
  boardOfGovernors,
  selectionCommittee,
  collegium,
  electionCommission,
  membersElection,
}

extension AppointmentAuthorityExtension on AppointmentAuthority {
  String get displayName {
    switch (this) {
      case AppointmentAuthority.president:
        return 'President of India';
      case AppointmentAuthority.primeMinister:
        return 'Prime Minister';
      case AppointmentAuthority.parliament:
        return 'Parliament';
      case AppointmentAuthority.governor:
        return 'Governor of State';
      case AppointmentAuthority.chiefJustice:
        return 'Chief Justice / Judiciary';
      case AppointmentAuthority.unionCouncilOfMinisters:
        return 'Union Council of Ministers';
      case AppointmentAuthority.concernedMinistry:
        return 'Concerned Ministry';
      case AppointmentAuthority.financeMinistry:
        return 'Ministry of Finance';
      case AppointmentAuthority.boardOfGovernors:
        return 'Board of Governors';
      case AppointmentAuthority.selectionCommittee:
        return 'Selection Committee';
      case AppointmentAuthority.collegium:
        return 'Collegium';
      case AppointmentAuthority.electionCommission:
        return 'Election Commission';
      case AppointmentAuthority.membersElection:
        return 'Elected by Members';
    }
  }
}

/// Nature of the tenure / term of the body or its members.
enum TenureType {
  fixedYears,
  ageBased,
  duringPleasure,
  duringGoodBehaviour,
  statutoryTerm,
  notApplicable,
}

extension TenureTypeExtension on TenureType {
  String get displayName {
    switch (this) {
      case TenureType.fixedYears:
        return 'Fixed number of years';
      case TenureType.ageBased:
        return 'Fixed years or age limit, whichever earlier';
      case TenureType.duringPleasure:
        return 'During pleasure of the appointing authority';
      case TenureType.duringGoodBehaviour:
        return 'During good behaviour';
      case TenureType.statutoryTerm:
        return 'Statutory term';
      case TenureType.notApplicable:
        return 'Not applicable';
    }
  }
}

/// Authority to whom the body reports.
enum ReportingAuthority {
  president,
  parliament,
  governor,
  unionCouncilOfMinisters,
  concernedMinistry,
  financeMinistry,
  judiciary,
  board,
  autonomous,
  notApplicable,
}

extension ReportingAuthorityExtension on ReportingAuthority {
  String get displayName {
    switch (this) {
      case ReportingAuthority.president:
        return 'President of India';
      case ReportingAuthority.parliament:
        return 'Parliament';
      case ReportingAuthority.governor:
        return 'Governor of State';
      case ReportingAuthority.unionCouncilOfMinisters:
        return 'Union Council of Ministers';
      case ReportingAuthority.concernedMinistry:
        return 'Concerned Ministry';
      case ReportingAuthority.financeMinistry:
        return 'Ministry of Finance';
      case ReportingAuthority.judiciary:
        return 'Judiciary';
      case ReportingAuthority.board:
        return 'Board / Governing Council';
      case ReportingAuthority.autonomous:
        return 'Autonomous / Statutorily Independent';
      case ReportingAuthority.notApplicable:
        return 'Not applicable';
    }
  }
}

/// Operational status of the body.
enum BodyStatus {
  active,
  reconstituted,
  subsumed,
  discontinued,
  proposed,
}

extension BodyStatusExtension on BodyStatus {
  String get displayName {
    switch (this) {
      case BodyStatus.active:
        return 'Active / Operational';
      case BodyStatus.reconstituted:
        return 'Reconstituted';
      case BodyStatus.subsumed:
        return 'Subsumed into Another Body';
      case BodyStatus.discontinued:
        return 'Discontinued / Superseded';
      case BodyStatus.proposed:
        return 'Proposed / Under Formulation';
    }
  }
}

/// Independence / autonomy classification of the body.
enum BodyIndependence {
  constitutionallyIndependent,
  statutorilyAutonomous,
  semiAutonomous,
  executiveSubordinate,
}

extension BodyIndependenceExtension on BodyIndependence {
  String get displayName {
    switch (this) {
      case BodyIndependence.constitutionallyIndependent:
        return 'Constitutionally Independent';
      case BodyIndependence.statutorilyAutonomous:
        return 'Statutorily Autonomous';
      case BodyIndependence.semiAutonomous:
        return 'Semi-autonomous';
      case BodyIndependence.executiveSubordinate:
        return 'Executive Subordinate';
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

/// Relevance level for a specific exam stage (Prelims / Mains / Interview).
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

/// Relationship link types in the Government Bodies Knowledge Graph.
enum BodyRelationshipType {
  reportsTo,
  appointedBy,
  supervises,
  regulates,
  memberOf,
  predecessorOf,
  successorOf,
  subsumedBy,
  linkedToAct,
  linkedToArticle,
  linkedToCommittee,
  linkedToReport,
  linkedToScheme,
  linkedToCaseLaw,
  linkedToDoctrine,
  linkedToPyq,
  linkedToCurrentAffairs,
  linkedToSdg,
  relatedTo,
}
