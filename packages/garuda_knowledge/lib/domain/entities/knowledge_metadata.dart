import 'package:meta/meta.dart';

/// Immutable entity storing metadata attributes for a Knowledge Object.
@immutable
class KnowledgeMetadata {
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String? lastUpdatedBy;
  final String locale;
  final Map<String, dynamic> customAttributes;

  const KnowledgeMetadata({
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.lastUpdatedBy,
    this.locale = 'en_IN',
    this.customAttributes = const {},
  });

  String get packageOrigin =>
      customAttributes['package_origin'] as String? ??
      customAttributes['packageOrigin'] as String? ??
      createdBy;

  Map<String, dynamic> toJson() => {
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'createdBy': createdBy,
        'lastUpdatedBy': lastUpdatedBy,
        'locale': locale,
        'customAttributes': customAttributes,
      };

  factory KnowledgeMetadata.fromJson(Map<String, dynamic> json) {
    return KnowledgeMetadata(
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      createdBy: json['createdBy'] as String? ?? 'System',
      lastUpdatedBy: json['lastUpdatedBy'] as String?,
      locale: json['locale'] as String? ?? 'en_IN',
      customAttributes:
          (json['customAttributes'] as Map<String, dynamic>?) ?? const {},
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KnowledgeMetadata &&
          runtimeType == other.runtimeType &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(createdAt, updatedAt);
}
