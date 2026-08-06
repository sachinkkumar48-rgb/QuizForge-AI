library;

import '../../domain/entities/editorial_status.dart';
import '../../domain/entities/knowledge_object.dart';
import '../../domain/entities/knowledge_object_version.dart';

class VersionDiffField {
  final String fieldName;
  final String oldValue;
  final String newValue;

  const VersionDiffField({
    required this.fieldName,
    required this.oldValue,
    required this.newValue,
  });
}

class VersionDiffResult {
  final String objectId;
  final int fromVersionNumber;
  final int toVersionNumber;
  final List<VersionDiffField> diffs;

  const VersionDiffResult({
    required this.objectId,
    required this.fromVersionNumber,
    required this.toVersionNumber,
    required this.diffs,
  });

  bool get hasChanges => diffs.isNotEmpty;
}

class VersionComparisonService {
  static VersionDiffResult compareVersions(
    KnowledgeObjectVersion v1,
    KnowledgeObjectVersion v2,
  ) {
    final List<VersionDiffField> diffs = [];
    final obj1 = v1.snapshotObject;
    final obj2 = v2.snapshotObject;

    if (obj1.title != obj2.title) {
      diffs.add(VersionDiffField(
        fieldName: 'title',
        oldValue: obj1.title,
        newValue: obj2.title,
      ));
    }

    if (obj1.content != obj2.content) {
      diffs.add(VersionDiffField(
        fieldName: 'content',
        oldValue: obj1.content,
        newValue: obj2.content,
      ));
    }

    if (obj1.status != obj2.status) {
      diffs.add(VersionDiffField(
        fieldName: 'status',
        oldValue: obj1.status.displayName,
        newValue: obj2.status.displayName,
      ));
    }

    if (obj1.subject != obj2.subject) {
      diffs.add(VersionDiffField(
        fieldName: 'subject',
        oldValue: obj1.subject,
        newValue: obj2.subject,
      ));
    }

    if (obj1.officialSource != obj2.officialSource) {
      diffs.add(VersionDiffField(
        fieldName: 'officialSource',
        oldValue: obj1.officialSource,
        newValue: obj2.officialSource,
      ));
    }

    return VersionDiffResult(
      objectId: v1.objectId,
      fromVersionNumber: v1.versionNumber,
      toVersionNumber: v2.versionNumber,
      diffs: diffs,
    );
  }

  static VersionDiffResult compareWithObject(
    KnowledgeObjectVersion version,
    KnowledgeObject currentObject,
  ) {
    final List<VersionDiffField> diffs = [];
    final snapObj = version.snapshotObject;

    if (snapObj.title != currentObject.title) {
      diffs.add(VersionDiffField(
        fieldName: 'title',
        oldValue: snapObj.title,
        newValue: currentObject.title,
      ));
    }

    if (snapObj.content != currentObject.content) {
      diffs.add(VersionDiffField(
        fieldName: 'content',
        oldValue: snapObj.content,
        newValue: currentObject.content,
      ));
    }

    if (snapObj.status != currentObject.status) {
      diffs.add(VersionDiffField(
        fieldName: 'status',
        oldValue: snapObj.status.displayName,
        newValue: currentObject.status.displayName,
      ));
    }

    return VersionDiffResult(
      objectId: currentObject.id,
      fromVersionNumber: version.versionNumber,
      toVersionNumber: currentObject.version,
      diffs: diffs,
    );
  }
}
