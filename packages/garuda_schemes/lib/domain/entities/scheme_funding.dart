library;

import 'package:meta/meta.dart';
import 'scheme_enums.dart';

/// Structured funding & financial assistance detail of a Government Scheme.
/// Central/State shares are stored as human-readable strings (Indian cost-share
/// ratios are expressed as "60:40", "100% Central" or "primarily State") while
/// the machine-usable `fundingPattern` enum remains the analytics key.
@immutable
class SchemeFundingDetail {
  final FundingPatternType fundingPattern;
  final String centralShare; // e.g. "100%", "60%", "90:10 (Centre:State)"
  final String stateShare; // e.g. "—", "40%", "10%"
  final String financialAssistance; // e.g. "₹6,000/year per farmer family"
  final String budgetOutlay; // e.g. "₹70,000 crore (FY 2025-26 BE)"

  const SchemeFundingDetail({
    this.fundingPattern = FundingPatternType.fullCentral,
    this.centralShare = '100%',
    this.stateShare = '',
    this.financialAssistance = '',
    this.budgetOutlay = '',
  });

  Map<String, dynamic> toJson() => {
        'fundingPattern': fundingPattern.name,
        'centralShare': centralShare,
        'stateShare': stateShare,
        'financialAssistance': financialAssistance,
        'budgetOutlay': budgetOutlay,
      };

  factory SchemeFundingDetail.fromJson(Map<String, dynamic> json) =>
      SchemeFundingDetail(
        fundingPattern: FundingPatternType.values.firstWhere(
          (t) => t.name == json['fundingPattern'],
          orElse: () => FundingPatternType.fullCentral,
        ),
        centralShare: json['centralShare'] as String? ?? '100%',
        stateShare: json['stateShare'] as String? ?? '',
        financialAssistance: json['financialAssistance'] as String? ?? '',
        budgetOutlay: json['budgetOutlay'] as String? ?? '',
      );

  SchemeFundingDetail copyWith({
    FundingPatternType? fundingPattern,
    String? centralShare,
    String? stateShare,
    String? financialAssistance,
    String? budgetOutlay,
  }) {
    return SchemeFundingDetail(
      fundingPattern: fundingPattern ?? this.fundingPattern,
      centralShare: centralShare ?? this.centralShare,
      stateShare: stateShare ?? this.stateShare,
      financialAssistance: financialAssistance ?? this.financialAssistance,
      budgetOutlay: budgetOutlay ?? this.budgetOutlay,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SchemeFundingDetail &&
        other.fundingPattern == fundingPattern &&
        other.centralShare == centralShare &&
        other.stateShare == stateShare &&
        other.financialAssistance == financialAssistance &&
        other.budgetOutlay == budgetOutlay;
  }

  @override
  int get hashCode => Object.hash(
      fundingPattern, centralShare, stateShare, financialAssistance, budgetOutlay);
}
