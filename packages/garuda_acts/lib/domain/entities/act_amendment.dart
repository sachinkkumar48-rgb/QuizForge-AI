library;

import 'package:meta/meta.dart';

/// Legislative Amendment record for an Act.
@immutable
class ActAmendment {
  final String amendmentId;
  final String actId;
  final String amendmentNumber;
  final String title;
  final int year;
  final String gazetteReference;
  final List<String> affectedSectionNumbers;
  final String summary;

  const ActAmendment({
    required this.amendmentId,
    required this.actId,
    required this.amendmentNumber,
    required this.title,
    required this.year,
    required this.gazetteReference,
    required this.affectedSectionNumbers,
    required this.summary,
  });

  Map<String, dynamic> toJson() {
    return {
      'amendmentId': amendmentId,
      'actId': actId,
      'amendmentNumber': amendmentNumber,
      'title': title,
      'year': year,
      'gazetteReference': gazetteReference,
      'affectedSectionNumbers': affectedSectionNumbers,
      'summary': summary,
    };
  }

  factory ActAmendment.fromJson(Map<String, dynamic> json) {
    return ActAmendment(
      amendmentId: json['amendmentId'] as String,
      actId: json['actId'] as String,
      amendmentNumber: json['amendmentNumber'] as String,
      title: json['title'] as String,
      year: json['year'] as int,
      gazetteReference: json['gazetteReference'] as String,
      affectedSectionNumbers: List<String>.from(json['affectedSectionNumbers'] as List? ?? []),
      summary: json['summary'] as String,
    );
  }
}
