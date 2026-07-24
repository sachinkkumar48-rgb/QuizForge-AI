import 'package:meta/meta.dart';

/// Immutable record of performance metrics and resource usage during AI quiz generation.
@immutable
class GenerationStatistics {
  final int chunksProcessed;
  final int questionsGenerated;
  final int tokensUsed;
  final Duration generationTime;

  const GenerationStatistics({
    required this.chunksProcessed,
    required this.questionsGenerated,
    required this.tokensUsed,
    required this.generationTime,
  });

  const GenerationStatistics.zero()
      : chunksProcessed = 0,
        questionsGenerated = 0,
        tokensUsed = 0,
        generationTime = Duration.zero;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GenerationStatistics &&
          runtimeType == other.runtimeType &&
          chunksProcessed == other.chunksProcessed &&
          questionsGenerated == other.questionsGenerated &&
          tokensUsed == other.tokensUsed &&
          generationTime == other.generationTime;

  @override
  int get hashCode => Object.hash(
        chunksProcessed,
        questionsGenerated,
        tokensUsed,
        generationTime,
      );

  @override
  String toString() =>
      'GenerationStatistics(chunks: $chunksProcessed, questions: $questionsGenerated, tokens: $tokensUsed, time: ${generationTime.inMilliseconds}ms)';
}
