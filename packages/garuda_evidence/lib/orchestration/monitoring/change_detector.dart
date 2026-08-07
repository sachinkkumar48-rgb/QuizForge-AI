import 'package:meta/meta.dart';
import '../../domain/entities/evidence_object.dart';

/// Classification of detected change between two Evidence Objects.
enum ChangeClassification {
  none,
  minorMetadata,
  contentUpdate,
  majorRevision,
}

/// Detailed difference report between two Evidence Object instances.
@immutable
class ChangeDelta {
  final bool hasChanged;
  final ChangeClassification classification;
  final bool checksumMatches;
  final List<String> modifiedFields;

  const ChangeDelta({
    required this.hasChanged,
    required this.classification,
    required this.checksumMatches,
    this.modifiedFields = const [],
  });

  Map<String, dynamic> toJson() => {
        'hasChanged': hasChanged,
        'classification': classification.name,
        'checksumMatches': checksumMatches,
        'modifiedFields': modifiedFields,
      };
}

/// Contract and default implementation for Evidence Object change detection.
abstract class ChangeDetector {
  /// Compare two evidence objects and return detailed delta report.
  ChangeDelta detectChange(EvidenceObject oldObj, EvidenceObject newObj);

  /// Compare two SHA256 checksum strings.
  bool compareChecksum(String oldChecksum, String newChecksum);

  /// Compare two metadata maps for key property differences.
  List<String> compareMetadata(
    Map<String, dynamic> oldMeta,
    Map<String, dynamic> newMeta,
  );
}

/// Standard implementation of [ChangeDetector].
class StandardChangeDetector implements ChangeDetector {
  @override
  bool compareChecksum(String oldChecksum, String newChecksum) {
    if (oldChecksum.isEmpty || newChecksum.isEmpty) return false;
    return oldChecksum == newChecksum;
  }

  @override
  List<String> compareMetadata(
    Map<String, dynamic> oldMeta,
    Map<String, dynamic> newMeta,
  ) {
    final modified = <String>[];
    final allKeys = {...oldMeta.keys, ...newMeta.keys};

    for (final key in allKeys) {
      if (oldMeta[key] != newMeta[key]) {
        modified.add(key);
      }
    }
    return modified;
  }

  @override
  ChangeDelta detectChange(EvidenceObject oldObj, EvidenceObject newObj) {
    final modified = <String>[];

    if (oldObj.title != newObj.title) modified.add('title');
    if (oldObj.summary != newObj.summary) modified.add('summary');
    if (oldObj.originalUrl != newObj.originalUrl) modified.add('originalUrl');
    if (oldObj.pdfUrl != newObj.pdfUrl) modified.add('pdfUrl');
    if (oldObj.category != newObj.category) modified.add('category');
    if (oldObj.topic != newObj.topic) modified.add('topic');

    final checksumMatches = oldObj.summary == newObj.summary &&
        oldObj.title == newObj.title &&
        oldObj.originalUrl == newObj.originalUrl;

    if (modified.isEmpty) {
      return const ChangeDelta(
        hasChanged: false,
        classification: ChangeClassification.none,
        checksumMatches: true,
        modifiedFields: [],
      );
    }

    ChangeClassification classification;
    if (modified.contains('title') || modified.contains('summary')) {
      classification = ChangeClassification.contentUpdate;
    } else if (modified.contains('originalUrl') || oldObj.version != newObj.version) {
      classification = ChangeClassification.majorRevision;
    } else {
      classification = ChangeClassification.minorMetadata;
    }

    return ChangeDelta(
      hasChanged: true,
      classification: classification,
      checksumMatches: checksumMatches,
      modifiedFields: modified,
    );
  }
}
