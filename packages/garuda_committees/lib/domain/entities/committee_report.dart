library;

import 'package:meta/meta.dart';

/// Immutable model representing an official report submitted by a Committee.
@immutable
class CommitteeReport {
  final String id;
  final String title;
  final String reportNumber;
  final DateTime? submissionDate;
  final String reportUrl;
  final String gazetteReference;
  final String summary;

  const CommitteeReport({
    required this.id,
    required this.title,
    this.reportNumber = '',
    this.submissionDate,
    this.reportUrl = '',
    this.gazetteReference = '',
    this.summary = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'reportNumber': reportNumber,
        'submissionDate': submissionDate?.toIso8601String(),
        'reportUrl': reportUrl,
        'gazetteReference': gazetteReference,
        'summary': summary,
      };

  factory CommitteeReport.fromJson(Map<String, dynamic> json) => CommitteeReport(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        reportNumber: json['reportNumber'] as String? ?? '',
        submissionDate: DateTime.tryParse(json['submissionDate'] as String? ?? ''),
        reportUrl: json['reportUrl'] as String? ?? '',
        gazetteReference: json['gazetteReference'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
      );
}
