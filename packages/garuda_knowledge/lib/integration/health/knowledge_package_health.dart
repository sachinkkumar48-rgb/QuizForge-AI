enum PackageHealthStatus { healthy, degraded, unhealthy }

class KnowledgePackageHealth {
  final String packageName;
  final String version;
  final int objectCount;
  final int relationshipCount;
  final int evidenceCount;
  final double coverage;
  final DateTime? lastSynchronization;
  final PackageHealthStatus status;
  final List<String> issues;

  const KnowledgePackageHealth({
    required this.packageName,
    required this.version,
    required this.objectCount,
    required this.relationshipCount,
    required this.evidenceCount,
    required this.coverage,
    this.lastSynchronization,
    required this.status,
    this.issues = const [],
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'version': version,
        'objectCount': objectCount,
        'relationshipCount': relationshipCount,
        'evidenceCount': evidenceCount,
        'coverage': coverage,
        'lastSynchronization': lastSynchronization?.toIso8601String(),
        'status': status.name,
        'issues': issues,
      };
}
