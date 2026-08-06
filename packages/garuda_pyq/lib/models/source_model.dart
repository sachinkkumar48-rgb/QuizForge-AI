import 'package:meta/meta.dart';

enum SourceType {
  officialWebsite,
  officialPdf,
  verifiedArchive,
  editorialEntry,
}

@immutable
class QuestionSource {
  final SourceType sourceType;
  final String? url;
  final String publisher;
  final DateTime retrievedDate;
  final DateTime? verifiedDate;
  final String? reviewer;
  final String checksum; // SHA-256 or MD5 integrity checksum

  const QuestionSource({
    required this.sourceType,
    this.url,
    required this.publisher,
    required this.retrievedDate,
    this.verifiedDate,
    this.reviewer,
    required this.checksum,
  });

  Map<String, dynamic> toJson() => {
        'sourceType': sourceType.name,
        'url': url,
        'publisher': publisher,
        'retrievedDate': retrievedDate.toIso8601String(),
        'verifiedDate': verifiedDate?.toIso8601String(),
        'reviewer': reviewer,
        'checksum': checksum,
      };

  factory QuestionSource.fromJson(Map<String, dynamic> json) {
    return QuestionSource(
      sourceType: SourceType.values.firstWhere(
        (e) => e.name == json['sourceType'],
        orElse: () => SourceType.editorialEntry,
      ),
      url: json['url'] as String?,
      publisher: json['publisher'] as String? ?? 'GARUDA Repository',
      retrievedDate: DateTime.parse(json['retrievedDate'] as String),
      verifiedDate: json['verifiedDate'] != null
          ? DateTime.parse(json['verifiedDate'] as String)
          : null,
      reviewer: json['reviewer'] as String?,
      checksum: json['checksum'] as String? ?? '',
    );
  }
}
