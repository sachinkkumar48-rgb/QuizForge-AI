library;

import 'package:meta/meta.dart';

/// Immutable first-class model for a single important statistic extracted from a Report.
@immutable
class ReportStatistic {
  final String id;
  final String label;
  final String value;
  final String unit;
  final int referenceYear;
  final String source;
  final String note;

  const ReportStatistic({
    required this.id,
    required this.label,
    required this.value,
    this.unit = '',
    this.referenceYear = 0,
    this.source = '',
    this.note = '',
  });

  String get displayValue => unit.isNotEmpty ? '$value $unit' : value;

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'value': value,
        'unit': unit,
        'referenceYear': referenceYear,
        'source': source,
        'note': note,
      };

  factory ReportStatistic.fromJson(Map<String, dynamic> json) =>
      ReportStatistic(
        id: json['id'] as String? ?? '',
        label: json['label'] as String? ?? '',
        value: json['value'] as String? ?? '',
        unit: json['unit'] as String? ?? '',
        referenceYear: (json['referenceYear'] as num?)?.toInt() ?? 0,
        source: json['source'] as String? ?? '',
        note: json['note'] as String? ?? '',
      );
}
