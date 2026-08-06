class KnowledgePackageStatistics {
  final String packageName;
  final int totalObjectsRegistered;
  final int totalRelationshipsRegistered;
  final int totalEventsDispatched;
  final DateTime initializedAt;

  const KnowledgePackageStatistics({
    required this.packageName,
    required this.totalObjectsRegistered,
    required this.totalRelationshipsRegistered,
    required this.totalEventsDispatched,
    required this.initializedAt,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'totalObjectsRegistered': totalObjectsRegistered,
        'totalRelationshipsRegistered': totalRelationshipsRegistered,
        'totalEventsDispatched': totalEventsDispatched,
        'initializedAt': initializedAt.toIso8601String(),
      };
}
