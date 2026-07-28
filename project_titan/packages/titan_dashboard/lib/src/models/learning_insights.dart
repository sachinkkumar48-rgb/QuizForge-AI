import 'package:meta/meta.dart';

/// Immutable entity containing AI-generated learning insights, focus recommendations, and warnings.
@immutable
class LearningInsights {
  final List<String> keyTakeaways;
  final List<String> weakAreasToAddress;
  final List<String> strongAreasToMaintain;
  final String topRecommendation;
  final String mentorTip;

  LearningInsights({
    List<String>? keyTakeaways,
    List<String>? weakAreasToAddress,
    List<String>? strongAreasToMaintain,
    this.topRecommendation = 'Prioritize Indian Polity revision queue.',
    this.mentorTip = 'Maintain steady 2-hour focused daily sessions.',
  })  : keyTakeaways = List<String>.unmodifiable(keyTakeaways ?? []),
        weakAreasToAddress =
            List<String>.unmodifiable(weakAreasToAddress ?? []),
        strongAreasToMaintain =
            List<String>.unmodifiable(strongAreasToMaintain ?? []);

  factory LearningInsights.empty() => LearningInsights(
        keyTakeaways: const ['Consistent progress across modules.'],
        weakAreasToAddress: const ['Polity', 'Modern History'],
        strongAreasToMaintain: const ['Geography'],
      );

  LearningInsights copyWith({
    List<String>? keyTakeaways,
    List<String>? weakAreasToAddress,
    List<String>? strongAreasToMaintain,
    String? topRecommendation,
    String? mentorTip,
  }) {
    return LearningInsights(
      keyTakeaways: keyTakeaways ?? this.keyTakeaways,
      weakAreasToAddress: weakAreasToAddress ?? this.weakAreasToAddress,
      strongAreasToMaintain:
          strongAreasToMaintain ?? this.strongAreasToMaintain,
      topRecommendation: topRecommendation ?? this.topRecommendation,
      mentorTip: mentorTip ?? this.mentorTip,
    );
  }

  Map<String, dynamic> toJson() => {
        'keyTakeaways': keyTakeaways,
        'weakAreasToAddress': weakAreasToAddress,
        'strongAreasToMaintain': strongAreasToMaintain,
        'topRecommendation': topRecommendation,
        'mentorTip': mentorTip,
      };

  factory LearningInsights.fromJson(Map<String, dynamic> json) =>
      LearningInsights(
        keyTakeaways: (json['keyTakeaways'] as List? ?? []).cast<String>(),
        weakAreasToAddress:
            (json['weakAreasToAddress'] as List? ?? []).cast<String>(),
        strongAreasToMaintain:
            (json['strongAreasToMaintain'] as List? ?? []).cast<String>(),
        topRecommendation: json['topRecommendation'] as String? ?? '',
        mentorTip: json['mentorTip'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningInsights &&
          runtimeType == other.runtimeType &&
          topRecommendation == other.topRecommendation &&
          mentorTip == other.mentorTip;

  @override
  int get hashCode => Object.hash(topRecommendation, mentorTip);
}
