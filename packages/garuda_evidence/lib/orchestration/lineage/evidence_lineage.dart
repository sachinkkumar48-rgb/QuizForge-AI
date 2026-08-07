import 'package:meta/meta.dart';

/// Immutable provenance and lineage audit record for Evidence Objects.
@immutable
class EvidenceLineage {
  final String originalSource;
  final String originalUrl;
  final String? originalPdf;
  final String? downloadedFile;
  final String parserVersion;
  final String validatorVersion;
  final List<String> knowledgeObjectsGenerated;
  final List<String> lessonsGenerated;
  final List<String> mcqsGenerated;
  final List<String> flashcardsGenerated;
  final List<String> revisionAssetsGenerated;

  const EvidenceLineage({
    required this.originalSource,
    required this.originalUrl,
    this.originalPdf,
    this.downloadedFile,
    this.parserVersion = '1.0.0',
    this.validatorVersion = '1.0.0',
    this.knowledgeObjectsGenerated = const [],
    this.lessonsGenerated = const [],
    this.mcqsGenerated = const [],
    this.flashcardsGenerated = const [],
    this.revisionAssetsGenerated = const [],
  });

  EvidenceLineage copyWith({
    String? originalSource,
    String? originalUrl,
    String? originalPdf,
    String? downloadedFile,
    String? parserVersion,
    String? validatorVersion,
    List<String>? knowledgeObjectsGenerated,
    List<String>? lessonsGenerated,
    List<String>? mcqsGenerated,
    List<String>? flashcardsGenerated,
    List<String>? revisionAssetsGenerated,
  }) {
    return EvidenceLineage(
      originalSource: originalSource ?? this.originalSource,
      originalUrl: originalUrl ?? this.originalUrl,
      originalPdf: originalPdf ?? this.originalPdf,
      downloadedFile: downloadedFile ?? this.downloadedFile,
      parserVersion: parserVersion ?? this.parserVersion,
      validatorVersion: validatorVersion ?? this.validatorVersion,
      knowledgeObjectsGenerated: knowledgeObjectsGenerated ??
          List.from(this.knowledgeObjectsGenerated),
      lessonsGenerated: lessonsGenerated ?? List.from(this.lessonsGenerated),
      mcqsGenerated: mcqsGenerated ?? List.from(this.mcqsGenerated),
      flashcardsGenerated:
          flashcardsGenerated ?? List.from(this.flashcardsGenerated),
      revisionAssetsGenerated:
          revisionAssetsGenerated ?? List.from(this.revisionAssetsGenerated),
    );
  }

  Map<String, dynamic> toJson() => {
        'originalSource': originalSource,
        'originalUrl': originalUrl,
        'originalPdf': originalPdf,
        'downloadedFile': downloadedFile,
        'parserVersion': parserVersion,
        'validatorVersion': validatorVersion,
        'knowledgeObjectsGenerated': knowledgeObjectsGenerated,
        'lessonsGenerated': lessonsGenerated,
        'mcqsGenerated': mcqsGenerated,
        'flashcardsGenerated': flashcardsGenerated,
        'revisionAssetsGenerated': revisionAssetsGenerated,
      };

  factory EvidenceLineage.fromJson(Map<String, dynamic> json) {
    List<String> parseList(dynamic val) {
      if (val is List) return val.map((e) => e.toString()).toList();
      return const [];
    }

    return EvidenceLineage(
      originalSource: json['originalSource'] as String? ?? '',
      originalUrl: json['originalUrl'] as String? ?? '',
      originalPdf: json['originalPdf'] as String?,
      downloadedFile: json['downloadedFile'] as String?,
      parserVersion: json['parserVersion'] as String? ?? '1.0.0',
      validatorVersion: json['validatorVersion'] as String? ?? '1.0.0',
      knowledgeObjectsGenerated: parseList(json['knowledgeObjectsGenerated']),
      lessonsGenerated: parseList(json['lessonsGenerated']),
      mcqsGenerated: parseList(json['mcqsGenerated']),
      flashcardsGenerated: parseList(json['flashcardsGenerated']),
      revisionAssetsGenerated: parseList(json['revisionAssetsGenerated']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EvidenceLineage &&
        other.originalSource == originalSource &&
        other.originalUrl == originalUrl &&
        other.parserVersion == parserVersion;
  }

  @override
  int get hashCode => Object.hash(originalSource, originalUrl, parserVersion);
}
