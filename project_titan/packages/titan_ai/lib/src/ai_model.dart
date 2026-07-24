import 'package:meta/meta.dart';

/// Immutable model describing an LLM model capabilities in Project TITAN.
@immutable
class AIModel {
  final String id;
  final String displayName;
  final int contextWindow;
  final bool supportsVision;
  final bool supportsStreaming;
  final bool supportsJson;
  final int maxOutputTokens;

  const AIModel({
    required this.id,
    required this.displayName,
    required this.contextWindow,
    this.supportsVision = false,
    this.supportsStreaming = false,
    this.supportsJson = false,
    required this.maxOutputTokens,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AIModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          displayName == other.displayName &&
          contextWindow == other.contextWindow &&
          supportsVision == other.supportsVision &&
          supportsStreaming == other.supportsStreaming &&
          supportsJson == other.supportsJson &&
          maxOutputTokens == other.maxOutputTokens;

  @override
  int get hashCode =>
      id.hashCode ^
      displayName.hashCode ^
      contextWindow.hashCode ^
      supportsVision.hashCode ^
      supportsStreaming.hashCode ^
      supportsJson.hashCode ^
      maxOutputTokens.hashCode;

  @override
  String toString() => 'AIModel($id - $displayName)';
}
