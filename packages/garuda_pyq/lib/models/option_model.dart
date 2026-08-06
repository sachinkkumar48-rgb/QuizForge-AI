import 'package:meta/meta.dart';

@immutable
class Option {
  final String key; // e.g. 'A', 'B', 'C', 'D'
  final String text;
  final String? explanation;
  final bool isCorrect;

  const Option({
    required this.key,
    required this.text,
    this.explanation,
    this.isCorrect = false,
  });

  Map<String, dynamic> toJson() => {
        'key': key,
        'text': text,
        'explanation': explanation,
        'isCorrect': isCorrect,
      };

  factory Option.fromJson(Map<String, dynamic> json) => Option(
        key: json['key'] as String,
        text: json['text'] as String,
        explanation: json['explanation'] as String?,
        isCorrect: json['isCorrect'] as bool? ?? false,
      );

  Option copyWith({
    String? key,
    String? text,
    String? explanation,
    bool? isCorrect,
  }) {
    return Option(
      key: key ?? this.key,
      text: text ?? this.text,
      explanation: explanation ?? this.explanation,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }
}
