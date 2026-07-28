import 'package:meta/meta.dart';

/// Immutable domain model representing an AI executive summary of a note.
@immutable
class NoteSummary {
  final String overview;
  final List<String> keyTakeaways;
  final List<String> upscRelevance;

  NoteSummary({
    required this.overview,
    required List<String> keyTakeaways,
    required List<String> upscRelevance,
  })  : keyTakeaways = List<String>.unmodifiable(keyTakeaways),
        upscRelevance = List<String>.unmodifiable(upscRelevance);

  NoteSummary copyWith({
    String? overview,
    List<String>? keyTakeaways,
    List<String>? upscRelevance,
  }) {
    return NoteSummary(
      overview: overview ?? this.overview,
      keyTakeaways: keyTakeaways ?? this.keyTakeaways,
      upscRelevance: upscRelevance ?? this.upscRelevance,
    );
  }

  Map<String, dynamic> toJson() => {
        'overview': overview,
        'keyTakeaways': keyTakeaways,
        'upscRelevance': upscRelevance,
      };

  factory NoteSummary.fromJson(Map<String, dynamic> json) => NoteSummary(
        overview: json['overview'] as String? ?? '',
        keyTakeaways: (json['keyTakeaways'] as List? ?? []).cast<String>(),
        upscRelevance: (json['upscRelevance'] as List? ?? []).cast<String>(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteSummary &&
          runtimeType == other.runtimeType &&
          overview == other.overview &&
          _listEquals(keyTakeaways, other.keyTakeaways) &&
          _listEquals(upscRelevance, other.upscRelevance);

  @override
  int get hashCode => Object.hash(
      overview, Object.hashAll(keyTakeaways), Object.hashAll(upscRelevance));
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
