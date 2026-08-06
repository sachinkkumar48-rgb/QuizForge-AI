library;

import 'package:meta/meta.dart';
import 'act_enums.dart';

/// Statutory metadata for a Central Act Knowledge Object.
@immutable
class ActMetadata {
  final String officialName;
  final String shortTitle;
  final int year;
  final String actNumber;
  final ActStatus status;
  final ActCategory category;
  final String ministry;
  final String gazetteReference;
  final GazetteType gazetteType;
  final String officialPdfUrl;
  final DateTime commencementDate;
  final List<String> repeals;
  final List<String> amendmentHistory;
  final String statementOfObjectsAndReasons;
  final String applicability;
  final Map<String, String> definitions;

  const ActMetadata({
    required this.officialName,
    required this.shortTitle,
    required this.year,
    required this.actNumber,
    required this.status,
    required this.category,
    required this.ministry,
    required this.gazetteReference,
    this.gazetteType = GazetteType.extraordinary,
    required this.officialPdfUrl,
    required this.commencementDate,
    this.repeals = const [],
    this.amendmentHistory = const [],
    required this.statementOfObjectsAndReasons,
    required this.applicability,
    this.definitions = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'officialName': officialName,
      'shortTitle': shortTitle,
      'year': year,
      'actNumber': actNumber,
      'status': status.name,
      'category': category.name,
      'ministry': ministry,
      'gazetteReference': gazetteReference,
      'gazetteType': gazetteType.name,
      'officialPdfUrl': officialPdfUrl,
      'commencementDate': commencementDate.toIso8601String(),
      'repeals': repeals,
      'amendmentHistory': amendmentHistory,
      'statementOfObjectsAndReasons': statementOfObjectsAndReasons,
      'applicability': applicability,
      'definitions': definitions,
    };
  }

  factory ActMetadata.fromJson(Map<String, dynamic> json) {
    return ActMetadata(
      officialName: json['officialName'] as String,
      shortTitle: json['shortTitle'] as String,
      year: json['year'] as int,
      actNumber: json['actNumber'] as String,
      status: ActStatus.values.byName(json['status'] as String),
      category: ActCategory.values.byName(json['category'] as String),
      ministry: json['ministry'] as String,
      gazetteReference: json['gazetteReference'] as String,
      gazetteType: GazetteType.values.byName(json['gazetteType'] as String? ?? 'extraordinary'),
      officialPdfUrl: json['officialPdfUrl'] as String,
      commencementDate: DateTime.parse(json['commencementDate'] as String),
      repeals: List<String>.from(json['repeals'] as List? ?? []),
      amendmentHistory: List<String>.from(json['amendmentHistory'] as List? ?? []),
      statementOfObjectsAndReasons: json['statementOfObjectsAndReasons'] as String,
      applicability: json['applicability'] as String,
      definitions: Map<String, String>.from(json['definitions'] as Map? ?? {}),
    );
  }
}
