import 'package:meta/meta.dart';

/// Immutable entity representing the origin/source of a knowledge object.
@immutable
class KnowledgeSource {
  final String sourceId;
  final String title;
  final String? url;
  final String? publisher;
  final DateTime? publicationDate;

  const KnowledgeSource({
    required this.sourceId,
    required this.title,
    this.url,
    this.publisher,
    this.publicationDate,
  });

  Map<String, dynamic> toJson() => {
        'sourceId': sourceId,
        'title': title,
        'url': url,
        'publisher': publisher,
        'publicationDate': publicationDate?.toIso8601String(),
      };

  factory KnowledgeSource.fromJson(Map<String, dynamic> json) {
    return KnowledgeSource(
      sourceId: json['sourceId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      url: json['url'] as String?,
      publisher: json['publisher'] as String?,
      publicationDate: json['publicationDate'] != null
          ? DateTime.parse(json['publicationDate'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KnowledgeSource &&
          runtimeType == other.runtimeType &&
          sourceId == other.sourceId;

  @override
  int get hashCode => sourceId.hashCode;
}
