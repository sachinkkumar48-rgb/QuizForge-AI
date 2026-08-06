import 'package:meta/meta.dart';
import 'knowledge_capability.dart';

/// Descriptor containing metadata, versions, and capabilities of a registered GARUDA package.
@immutable
class KnowledgePackageDescriptor {
  final String packageName;
  final String version;
  final List<String> dependencies;
  final List<KnowledgeCapability> capabilities;
  final DateTime registeredAt;
  final Map<String, dynamic> metadata;

  const KnowledgePackageDescriptor({
    required this.packageName,
    required this.version,
    this.dependencies = const [],
    this.capabilities = const [],
    required this.registeredAt,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'version': version,
        'dependencies': dependencies,
        'capabilities': capabilities.map((c) => c.toJson()).toList(),
        'registeredAt': registeredAt.toIso8601String(),
        'metadata': metadata,
      };

  factory KnowledgePackageDescriptor.fromJson(Map<String, dynamic> json) {
    return KnowledgePackageDescriptor(
      packageName: json['packageName'] as String? ?? '',
      version: json['version'] as String? ?? '0.1.0',
      dependencies: (json['dependencies'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      capabilities: (json['capabilities'] as List<dynamic>?)
              ?.map((e) => KnowledgeCapability.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      registeredAt: json['registeredAt'] != null
          ? DateTime.parse(json['registeredAt'] as String)
          : DateTime.now(),
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KnowledgePackageDescriptor &&
          runtimeType == other.runtimeType &&
          packageName == other.packageName &&
          version == other.version;

  @override
  int get hashCode => Object.hash(packageName, version);
}
