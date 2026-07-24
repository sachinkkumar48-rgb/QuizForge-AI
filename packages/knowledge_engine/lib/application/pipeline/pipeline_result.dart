import 'package:meta/meta.dart';

import '../../domain/entities/knowledge_object.dart';

/// Performance and payload statistics for an ingestion pipeline run.
@immutable
class PipelineStats {
  /// Raw input character count before normalization.
  final int originalCharCount;

  /// Clean character count after normalization.
  final int normalizedCharCount;

  /// Number of knowledge chunks produced.
  final int chunkCount;

  /// Total word count across all generated chunks.
  final int totalWords;

  /// Constructs immutable [PipelineStats].
  const PipelineStats({
    required this.originalCharCount,
    required this.normalizedCharCount,
    required this.chunkCount,
    required this.totalWords,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PipelineStats &&
        other.originalCharCount == originalCharCount &&
        other.normalizedCharCount == normalizedCharCount &&
        other.chunkCount == chunkCount &&
        other.totalWords == totalWords;
  }

  @override
  int get hashCode {
    return Object.hash(
        originalCharCount, normalizedCharCount, chunkCount, totalWords);
  }

  @override
  String toString() {
    return 'PipelineStats(originalChars: $originalCharCount, normalizedChars: $normalizedCharCount, chunks: $chunkCount, words: $totalWords)';
  }
}

/// Represents the immutable execution result returned by [KnowledgeIngestionPipeline].
@immutable
class PipelineResult {
  /// List of generated [KnowledgeObject] entities.
  final List<KnowledgeObject> objects;

  /// Detailed processing metrics.
  final PipelineStats statistics;

  /// Time taken to process the ingestion request.
  final Duration processingDuration;

  /// Non-fatal warnings encountered during ingestion.
  final List<String> warnings;

  /// Indicates if the pipeline completed successfully without critical errors.
  final bool isSuccess;

  /// Constructs an immutable [PipelineResult].
  PipelineResult({
    required List<KnowledgeObject> objects,
    required this.statistics,
    required this.processingDuration,
    List<String> warnings = const [],
    this.isSuccess = true,
  })  : objects = List<KnowledgeObject>.unmodifiable(objects),
        warnings = List<String>.unmodifiable(warnings);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PipelineResult &&
        other.isSuccess == isSuccess &&
        other.statistics == statistics &&
        other.processingDuration == processingDuration &&
        _listEquals(other.objects, objects) &&
        _listEquals(other.warnings, warnings);
  }

  @override
  int get hashCode {
    return Object.hash(
      isSuccess,
      statistics,
      processingDuration,
      Object.hashAll(objects),
      Object.hashAll(warnings),
    );
  }

  @override
  String toString() {
    return 'PipelineResult(success: $isSuccess, objects: ${objects.length}, duration: ${processingDuration.inMilliseconds}ms, warnings: ${warnings.length})';
  }

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
