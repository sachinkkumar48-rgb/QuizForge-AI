import 'package:meta/meta.dart';

@immutable
class LearningObjectives {
  final List<String> studentShouldBeAbleTo;
  final List<String> define;
  final List<String> identify;
  final List<String> differentiate;
  final List<String> apply;
  final List<String> analyse;
  final List<String> eliminateOptions;

  const LearningObjectives({
    this.studentShouldBeAbleTo = const [],
    this.define = const [],
    this.identify = const [],
    this.differentiate = const [],
    this.apply = const [],
    this.analyse = const [],
    this.eliminateOptions = const [],
  });

  Map<String, dynamic> toJson() => {
        'studentShouldBeAbleTo': studentShouldBeAbleTo,
        'define': define,
        'identify': identify,
        'differentiate': differentiate,
        'apply': apply,
        'analyse': analyse,
        'eliminateOptions': eliminateOptions,
      };

  factory LearningObjectives.fromJson(Map<String, dynamic> json) =>
      LearningObjectives(
        studentShouldBeAbleTo:
            List<String>.from(json['studentShouldBeAbleTo'] ?? []),
        define: List<String>.from(json['define'] ?? []),
        identify: List<String>.from(json['identify'] ?? []),
        differentiate: List<String>.from(json['differentiate'] ?? []),
        apply: List<String>.from(json['apply'] ?? []),
        analyse: List<String>.from(json['analyse'] ?? []),
        eliminateOptions: List<String>.from(json['eliminateOptions'] ?? []),
      );
}
