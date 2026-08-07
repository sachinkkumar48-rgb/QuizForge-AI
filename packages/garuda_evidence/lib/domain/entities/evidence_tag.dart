import 'package:meta/meta.dart';

/// Tag attached to an evidence object for categorization and search.
@immutable
class EvidenceTag {
  final String id;
  final String name;
  final String category;
  final double confidenceScore;

  const EvidenceTag({
    required this.id,
    required this.name,
    this.category = 'general',
    this.confidenceScore = 1.0,
  });

  EvidenceTag copyWith({
    String? id,
    String? name,
    String? category,
    double? confidenceScore,
  }) {
    return EvidenceTag(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      confidenceScore: confidenceScore ?? this.confidenceScore,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'confidenceScore': confidenceScore,
    };
  }

  factory EvidenceTag.fromJson(Map<String, dynamic> json) {
    return EvidenceTag(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'general',
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EvidenceTag &&
        other.id == id &&
        other.name == name &&
        other.category == category &&
        other.confidenceScore == confidenceScore;
  }

  @override
  int get hashCode => Object.hash(id, name, category, confidenceScore);

  @override
  String toString() => 'EvidenceTag(id: $id, name: $name, category: $category)';
}
