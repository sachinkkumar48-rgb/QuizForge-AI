import 'package:meta/meta.dart';

@immutable
class AuditRecord {
  final DateTime timestamp;
  final String packageName;
  final String objectId;
  final String objectType;
  final int version;
  final String operation;
  final String result;
  final double durationMs;
  final String? details;

  const AuditRecord({
    required this.timestamp,
    required this.packageName,
    required this.objectId,
    required this.objectType,
    required this.version,
    required this.operation,
    required this.result,
    required this.durationMs,
    this.details,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'packageName': packageName,
        'objectId': objectId,
        'objectType': objectType,
        'version': version,
        'operation': operation,
        'result': result,
        'durationMs': durationMs,
        'details': details,
      };
}

class KnowledgeAuditTrail {
  final List<AuditRecord> _records = [];

  void record(AuditRecord entry) {
    _records.add(entry);
  }

  List<AuditRecord> get records => List.unmodifiable(_records);

  List<AuditRecord> getRecordsByObject(String objectId) {
    return _records.where((r) => r.objectId == objectId).toList();
  }

  List<AuditRecord> getRecordsByPackage(String packageName) {
    return _records.where((r) => r.packageName == packageName).toList();
  }

  void clear() {
    _records.clear();
  }
}
