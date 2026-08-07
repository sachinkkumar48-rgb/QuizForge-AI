library;

/// Categories for Indian Committees, Commissions, and Expert Bodies.
enum CommitteeCategory {
  constitutional,
  statutory,
  executive,
  finance,
  law,
  police,
  education,
  agriculture,
  environment,
  health,
  economy,
  judicial,
  parliamentary,
  nitiAayog,
  taskForce,
  workingGroup,
  commissionOfInquiry,
  expertGroup,
}

extension CommitteeCategoryExtension on CommitteeCategory {
  String get displayName {
    switch (this) {
      case CommitteeCategory.constitutional:
        return 'Constitutional Body / Commission';
      case CommitteeCategory.statutory:
        return 'Statutory Commission / Committee';
      case CommitteeCategory.executive:
        return 'Executive Resolution Committee';
      case CommitteeCategory.finance:
        return 'Finance & Fiscal Reforms';
      case CommitteeCategory.law:
        return 'Law Commission & Judicial Reforms';
      case CommitteeCategory.police:
        return 'Police & Internal Security Reforms';
      case CommitteeCategory.education:
        return 'Education & Skill Development';
      case CommitteeCategory.agriculture:
        return 'Agriculture & Farmers Welfare';
      case CommitteeCategory.environment:
        return 'Environment, Ecology & Climate';
      case CommitteeCategory.health:
        return 'Public Health & Medical Reform';
      case CommitteeCategory.economy:
        return 'Macroeconomic & Financial Sector';
      case CommitteeCategory.judicial:
        return 'Judicial Commission / Inquiry';
      case CommitteeCategory.parliamentary:
        return 'Parliamentary Committee';
      case CommitteeCategory.nitiAayog:
        return 'NITI Aayog Committee / Task Force';
      case CommitteeCategory.taskForce:
        return 'High-Level Task Force';
      case CommitteeCategory.workingGroup:
        return 'Working Group / Sub-Committee';
      case CommitteeCategory.commissionOfInquiry:
        return 'Commission of Inquiry';
      case CommitteeCategory.expertGroup:
        return 'Expert Body / Technical Group';
    }
  }
}

/// Operational status of a committee or commission.
enum CommitteeStatus {
  active,
  submitted,
  dissolved,
  implemented,
  partiallyImplemented,
  rejected,
}

/// Status of individual recommendations.
enum RecommendationStatus {
  accepted,
  acceptedPartially,
  underConsideration,
  rejected,
  implemented,
}
