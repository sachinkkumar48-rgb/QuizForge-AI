library;

import 'package:meta/meta.dart';
import 'report_enums.dart';

/// Immutable metadata descriptor for an important chart/exhibit inside a Report.
@immutable
class ReportChartMetadata {
  final String id;
  final String title;
  final ReportChartType chartType;
  final String description;
  final int pageNumber;
  final String sourceDataNote;

  const ReportChartMetadata({
    required this.id,
    required this.title,
    this.chartType = ReportChartType.bar,
    this.description = '',
    this.pageNumber = 0,
    this.sourceDataNote = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'chartType': chartType.name,
        'description': description,
        'pageNumber': pageNumber,
        'sourceDataNote': sourceDataNote,
      };

  factory ReportChartMetadata.fromJson(Map<String, dynamic> json) =>
      ReportChartMetadata(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        chartType: ReportChartType.values.firstWhere(
          (t) => t.name == json['chartType'],
          orElse: () => ReportChartType.bar,
        ),
        description: json['description'] as String? ?? '',
        pageNumber: (json['pageNumber'] as num?)?.toInt() ?? 0,
        sourceDataNote: json['sourceDataNote'] as String? ?? '',
      );
}
