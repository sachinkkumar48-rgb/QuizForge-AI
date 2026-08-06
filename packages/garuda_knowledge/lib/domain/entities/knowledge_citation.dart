import 'package:meta/meta.dart';

/// Immutable entity representing a citation within a knowledge asset.
@immutable
class KnowledgeCitation {
  final String id;
  final String text;
  final String? sourceReference;
  final int? pageNumber;

  const KnowledgeCitation({
    required this.id,
    required this.text,
    this.sourceReference,
    this.pageNumber,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'sourceReference': sourceReference,
        'pageNumber': pageNumber,
      };

  factory KnowledgeCitation.fromJson(Map<String, dynamic> json) {
    return KnowledgeCitation(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      sourceReference: json['sourceReference'] as String?,
      pageNumber: json['pageNumber'] as int?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KnowledgeCitation &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
