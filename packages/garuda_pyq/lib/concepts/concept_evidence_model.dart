import 'package:meta/meta.dart';

@immutable
class ConceptEvidence {
  final String id;
  final String conceptId;
  final String evidenceType; // Article, Case, Act, Committee, Report
  final String title;
  final String citation;
  final String summary;

  const ConceptEvidence({
    required this.id,
    required this.conceptId,
    required this.evidenceType,
    required this.title,
    required this.citation,
    required this.summary,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'conceptId': conceptId,
        'evidenceType': evidenceType,
        'title': title,
        'citation': citation,
        'summary': summary,
      };

  factory ConceptEvidence.fromJson(Map<String, dynamic> json) =>
      ConceptEvidence(
        id: json['id'] as String,
        conceptId: json['conceptId'] as String,
        evidenceType: json['evidenceType'] as String,
        title: json['title'] as String,
        citation: json['citation'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
      );
}
