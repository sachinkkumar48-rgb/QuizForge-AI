library;

/// Top-level classification of a GARUDA Report Library Knowledge Object.
enum ReportObjectType {
  report,
  indices,
  survey,
}

/// Broad syllabus-aligned categories used to classify Reports, Indices and Surveys.
enum ReportCategory {
  economy,
  finance,
  budget,
  fiscalFederalism,
  agriculture,
  industry,
  trade,
  infrastructure,
  logistics,
  socialDevelopment,
  health,
  education,
  demography,
  labour,
  governance,
  environment,
  climate,
  energy,
  forest,
  security,
  international,
  science,
  statistics,
}

extension ReportCategoryExtension on ReportCategory {
  String get displayName {
    switch (this) {
      case ReportCategory.economy:
        return 'Economy & Growth';
      case ReportCategory.finance:
        return 'Finance & Banking';
      case ReportCategory.budget:
        return 'Budget & Public Finance';
      case ReportCategory.fiscalFederalism:
        return 'Fiscal Federalism';
      case ReportCategory.agriculture:
        return 'Agriculture & Food Security';
      case ReportCategory.industry:
        return 'Industry & Manufacturing';
      case ReportCategory.trade:
        return 'Trade & Commerce';
      case ReportCategory.infrastructure:
        return 'Infrastructure & Connectivity';
      case ReportCategory.logistics:
        return 'Logistics & Supply Chain';
      case ReportCategory.socialDevelopment:
        return 'Social Development & Welfare';
      case ReportCategory.health:
        return 'Health & Nutrition';
      case ReportCategory.education:
        return 'Education & Skill Development';
      case ReportCategory.demography:
        return 'Demography & Census';
      case ReportCategory.labour:
        return 'Labour & Employment';
      case ReportCategory.governance:
        return 'Governance & Public Administration';
      case ReportCategory.environment:
        return 'Environment & Ecology';
      case ReportCategory.climate:
        return 'Climate Change';
      case ReportCategory.energy:
        return 'Energy';
      case ReportCategory.forest:
        return 'Forestry & Biodiversity';
      case ReportCategory.security:
        return 'Internal Security & Crime';
      case ReportCategory.international:
        return 'International & Multilateral';
      case ReportCategory.science:
        return 'Science, Innovation & Technology';
      case ReportCategory.statistics:
        return 'Statistics & Data Systems';
    }
  }
}

/// Publication cadence of the report series.
enum PublicationFrequency {
  annual,
  semiAnnual,
  biennial,
  triennial,
  quinquennial,
  adhoc,
  periodic,
  discontinued,
}

extension PublicationFrequencyExtension on PublicationFrequency {
  String get displayName {
    switch (this) {
      case PublicationFrequency.annual:
        return 'Annual';
      case PublicationFrequency.semiAnnual:
        return 'Semi-Annual';
      case PublicationFrequency.biennial:
        return 'Biennial';
      case PublicationFrequency.triennial:
        return 'Triennial';
      case PublicationFrequency.quinquennial:
        return 'Quinquennial';
      case PublicationFrequency.adhoc:
        return 'Ad-hoc / One-off';
      case PublicationFrequency.periodic:
        return 'Periodic';
      case PublicationFrequency.discontinued:
        return 'Discontinued / Historical';
    }
  }
}

/// Directional movement of an Index ranking or score over successive editions.
enum IndexTrend {
  improving,
  worsening,
  stable,
  firstEdition,
}

extension IndexTrendExtension on IndexTrend {
  String get displayName {
    switch (this) {
      case IndexTrend.improving:
        return 'Improving';
      case IndexTrend.worsening:
        return 'Worsening';
      case IndexTrend.stable:
        return 'Stable';
      case IndexTrend.firstEdition:
        return 'First Edition';
    }
  }
}

/// Implementation status of a structured Recommendation Knowledge Object.
enum RecommendationStatus {
  underConsideration,
  accepted,
  acceptedPartially,
  implemented,
  rejected,
}

extension RecommendationStatusExtension on RecommendationStatus {
  String get displayName {
    switch (this) {
      case RecommendationStatus.underConsideration:
        return 'Under Consideration';
      case RecommendationStatus.accepted:
        return 'Accepted';
      case RecommendationStatus.acceptedPartially:
        return 'Accepted Partially';
      case RecommendationStatus.implemented:
        return 'Implemented';
      case RecommendationStatus.rejected:
        return 'Rejected';
    }
  }
}

/// Visual category of an important chart embedded in a report.
enum ReportChartType {
  bar,
  line,
  pie,
  stacked,
  scatter,
  map,
  table,
}

extension ReportChartTypeExtension on ReportChartType {
  String get displayName {
    switch (this) {
      case ReportChartType.bar:
        return 'Bar Chart';
      case ReportChartType.line:
        return 'Line Chart';
      case ReportChartType.pie:
        return 'Pie Chart';
      case ReportChartType.stacked:
        return 'Stacked Bar Chart';
      case ReportChartType.scatter:
        return 'Scatter Plot';
      case ReportChartType.map:
        return 'Thematic Map';
      case ReportChartType.table:
        return 'Tabular Exhibit';
    }
  }
}

/// Institutional type of a Report, Survey, Index or Budget/Statistical document.
enum ReportType {
  annualReport,
  survey,
  census,
  budgetDocument,
  indexPublication,
  statisticalPublication,
  assessmentReport,
  policyDocument,
  globalReport,
  forecast,
}

extension ReportTypeExtension on ReportType {
  String get displayName {
    switch (this) {
      case ReportType.annualReport:
        return 'Annual Report';
      case ReportType.survey:
        return 'Survey';
      case ReportType.census:
        return 'Census / Enumeration';
      case ReportType.budgetDocument:
        return 'Budget Document';
      case ReportType.indexPublication:
        return 'Index Publication';
      case ReportType.statisticalPublication:
        return 'Statistical Publication';
      case ReportType.assessmentReport:
        return 'Assessment / Outlook Report';
      case ReportType.policyDocument:
        return 'Policy Document';
      case ReportType.globalReport:
        return 'Global / Multilateral Report';
      case ReportType.forecast:
        return 'Forecast / Outlook';
    }
  }
}

/// Direction of an indicator's movement relative to its previous edition.
enum IndicatorTrend {
  improving,
  worsening,
  stable,
  firstEdition,
  notAvailable,
}

extension IndicatorTrendExtension on IndicatorTrend {
  String get displayName {
    switch (this) {
      case IndicatorTrend.improving:
        return 'Improving';
      case IndicatorTrend.worsening:
        return 'Worsening';
      case IndicatorTrend.stable:
        return 'Stable';
      case IndicatorTrend.firstEdition:
        return 'First Edition';
      case IndicatorTrend.notAvailable:
        return 'Not Available';
    }
  }
}

/// Relevance level for a specific UPSC exam stage.
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
