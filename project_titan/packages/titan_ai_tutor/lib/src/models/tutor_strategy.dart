import 'package:meta/meta.dart';
import 'enums.dart';

/// Immutable domain model representing an adaptive teaching strategy.
@immutable
class TutorStrategy {
  final String id;
  final TutorPersona persona;
  final String askingStyle; // e.g. Socratic, Direct, Guided
  final String pacing; // e.g. Slow, Moderate, Fast
  final int reinforcementFrequency; // Every N steps
  final double scaffoldingLevel; // 0.0 (no hints) to 1.0 (heavy hints)

  const TutorStrategy({
    required this.id,
    this.persona = TutorPersona.intermediate,
    this.askingStyle = 'Socratic',
    this.pacing = 'Moderate',
    this.reinforcementFrequency = 3,
    this.scaffoldingLevel = 0.5,
  });

  TutorStrategy copyWith({
    String? id,
    TutorPersona? persona,
    String? askingStyle,
    String? pacing,
    int? reinforcementFrequency,
    double? scaffoldingLevel,
  }) {
    return TutorStrategy(
      id: id ?? this.id,
      persona: persona ?? this.persona,
      askingStyle: askingStyle ?? this.askingStyle,
      pacing: pacing ?? this.pacing,
      reinforcementFrequency:
          reinforcementFrequency ?? this.reinforcementFrequency,
      scaffoldingLevel: scaffoldingLevel ?? this.scaffoldingLevel,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'persona': persona.name,
        'askingStyle': askingStyle,
        'pacing': pacing,
        'reinforcementFrequency': reinforcementFrequency,
        'scaffoldingLevel': scaffoldingLevel,
      };

  factory TutorStrategy.fromJson(Map<String, dynamic> json) => TutorStrategy(
        id: json['id'] as String,
        persona: TutorPersona.values.firstWhere(
          (e) => e.name == json['persona'],
          orElse: () => TutorPersona.intermediate,
        ),
        askingStyle: json['askingStyle'] as String? ?? 'Socratic',
        pacing: json['pacing'] as String? ?? 'Moderate',
        reinforcementFrequency: json['reinforcementFrequency'] as int? ?? 3,
        scaffoldingLevel: (json['scaffoldingLevel'] as num? ?? 0.5).toDouble(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TutorStrategy &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          persona == other.persona;

  @override
  int get hashCode => Object.hash(id, persona);
}
