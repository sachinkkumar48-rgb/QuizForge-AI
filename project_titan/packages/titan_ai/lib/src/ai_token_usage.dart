import 'package:meta/meta.dart';

/// Immutable record of token consumption for an AI generation request.
@immutable
class AITokenUsage {
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;

  const AITokenUsage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });

  const AITokenUsage.zero()
      : promptTokens = 0,
        completionTokens = 0,
        totalTokens = 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AITokenUsage &&
          runtimeType == other.runtimeType &&
          promptTokens == other.promptTokens &&
          completionTokens == other.completionTokens &&
          totalTokens == other.totalTokens;

  @override
  int get hashCode =>
      promptTokens.hashCode ^ completionTokens.hashCode ^ totalTokens.hashCode;

  @override
  String toString() =>
      'AITokenUsage(prompt: $promptTokens, completion: $completionTokens, total: $totalTokens)';
}
