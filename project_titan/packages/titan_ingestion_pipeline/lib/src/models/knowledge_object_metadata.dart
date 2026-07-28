import 'package:meta/meta.dart';

/// Extracted document metadata for Knowledge Objects.
@immutable
class KnowledgeObjectMetadata {
  final String title;
  final String author;
  final String publisher;
  final String edition;
  final int? year;
  final String language;
  final String sourceType;
  final String copyright;
  final String? license;
  final Map<String, dynamic> extra;

  KnowledgeObjectMetadata({
    required this.title,
    this.author = 'Unknown',
    this.publisher = 'Unknown',
    this.edition = '1st',
    this.year,
    this.language = 'en',
    this.sourceType = 'text',
    this.copyright = '',
    this.license,
    Map<String, dynamic>? extra,
  }) : extra = Map.unmodifiable(extra ?? {});

  Map<String, dynamic> toJson() => {
        'title': title,
        'author': author,
        'publisher': publisher,
        'edition': edition,
        'year': year,
        'language': language,
        'sourceType': sourceType,
        'copyright': copyright,
        'license': license,
        'extra': extra,
      };

  factory KnowledgeObjectMetadata.fromJson(Map<String, dynamic> json) =>
      KnowledgeObjectMetadata(
        title: json['title'] as String? ?? 'Untitled',
        author: json['author'] as String? ?? 'Unknown',
        publisher: json['publisher'] as String? ?? 'Unknown',
        edition: json['edition'] as String? ?? '1st',
        year: json['year'] as int?,
        language: json['language'] as String? ?? 'en',
        sourceType: json['sourceType'] as String? ?? 'text',
        copyright: json['copyright'] as String? ?? '',
        license: json['license'] as String?,
        extra: Map<String, dynamic>.from(json['extra'] as Map? ?? {}),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KnowledgeObjectMetadata &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          author == other.author &&
          sourceType == other.sourceType;

  @override
  int get hashCode => Object.hash(title, author, sourceType);
}
