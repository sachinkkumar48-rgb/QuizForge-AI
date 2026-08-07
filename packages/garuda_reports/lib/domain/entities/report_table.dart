library;

import 'package:meta/meta.dart';

/// Immutable metadata descriptor for an important statistical table inside a Report.
@immutable
class ReportTableMetadata {
  final String id;
  final String title;
  final String tableNumber;
  final String description;
  final List<String> columns;
  final int rowCount;
  final int pageNumber;

  const ReportTableMetadata({
    required this.id,
    required this.title,
    this.tableNumber = '',
    this.description = '',
    this.columns = const [],
    this.rowCount = 0,
    this.pageNumber = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'tableNumber': tableNumber,
        'description': description,
        'columns': columns,
        'rowCount': rowCount,
        'pageNumber': pageNumber,
      };

  factory ReportTableMetadata.fromJson(Map<String, dynamic> json) =>
      ReportTableMetadata(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        tableNumber: json['tableNumber'] as String? ?? '',
        description: json['description'] as String? ?? '',
        columns:
            (json['columns'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        rowCount: (json['rowCount'] as num?)?.toInt() ?? 0,
        pageNumber: (json['pageNumber'] as num?)?.toInt() ?? 0,
      );
}
