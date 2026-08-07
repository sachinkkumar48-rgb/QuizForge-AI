library;

/// 13 Primary UPSC Subject Categories for Current Affairs Classification.
enum CurrentAffairsCategory {
  polity,
  governance,
  economy,
  environment,
  scienceAndTechnology,
  security,
  internationalRelations,
  socialIssues,
  agriculture,
  culture,
  geography,
  ethics,
  miscellaneous,
}

extension CurrentAffairsCategoryExtension on CurrentAffairsCategory {
  String get displayName {
    switch (this) {
      case CurrentAffairsCategory.polity:
        return 'Polity';
      case CurrentAffairsCategory.governance:
        return 'Governance';
      case CurrentAffairsCategory.economy:
        return 'Economy';
      case CurrentAffairsCategory.environment:
        return 'Environment & Biodiversity';
      case CurrentAffairsCategory.scienceAndTechnology:
        return 'Science & Technology';
      case CurrentAffairsCategory.security:
        return 'Internal & External Security';
      case CurrentAffairsCategory.internationalRelations:
        return 'International Relations';
      case CurrentAffairsCategory.socialIssues:
        return 'Social Issues';
      case CurrentAffairsCategory.agriculture:
        return 'Agriculture & Allied Sectors';
      case CurrentAffairsCategory.culture:
        return 'Art & Culture';
      case CurrentAffairsCategory.geography:
        return 'Geography & Disaster Management';
      case CurrentAffairsCategory.ethics:
        return 'Ethics & Integrity';
      case CurrentAffairsCategory.miscellaneous:
        return 'Miscellaneous';
    }
  }
}

/// Importance levels for Current Events in UPSC Examination context.
enum CurrentAffairsImportance {
  low,
  medium,
  high,
  critical,
}

/// Periodic digest frequencies.
enum DigestFrequency {
  daily,
  weekly,
  monthly,
  yearly,
  themeWise,
  topicWise,
}
