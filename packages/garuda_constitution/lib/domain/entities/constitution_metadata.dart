library;

import 'package:meta/meta.dart';

/// Immutable metadata describing the Constitution of India.
@immutable
class ConstitutionMetadata {
  final String title;
  final DateTime dateAdopted;
  final DateTime dateEnforced;
  final String constituentAssembly;
  final int originalArticles;
  final int currentArticles;
  final int originalParts;
  final int currentParts;
  final int originalSchedules;
  final int currentSchedules;
  final int currentAmendments;
  final List<String> officialSources;

  const ConstitutionMetadata({
    this.title = 'Constitution of India',
    required this.dateAdopted,
    required this.dateEnforced,
    this.constituentAssembly =
        'Constituent Assembly of India (Dr. B.R. Ambedkar, Drafting Committee Chairman)',
    this.originalArticles = 395,
    this.currentArticles = 448,
    this.originalParts = 22,
    this.currentParts = 25,
    this.originalSchedules = 8,
    this.currentSchedules = 12,
    this.currentAmendments = 106,
    this.officialSources = const [
      'Legislative Department, Ministry of Law and Justice, Government of India',
      'Gazette of India Extraordinary',
    ],
  });

  ConstitutionMetadata copyWith({
    String? title,
    DateTime? dateAdopted,
    DateTime? dateEnforced,
    String? constituentAssembly,
    int? originalArticles,
    int? currentArticles,
    int? originalParts,
    int? currentParts,
    int? originalSchedules,
    int? currentSchedules,
    int? currentAmendments,
    List<String>? officialSources,
  }) {
    return ConstitutionMetadata(
      title: title ?? this.title,
      dateAdopted: dateAdopted ?? this.dateAdopted,
      dateEnforced: dateEnforced ?? this.dateEnforced,
      constituentAssembly: constituentAssembly ?? this.constituentAssembly,
      originalArticles: originalArticles ?? this.originalArticles,
      currentArticles: currentArticles ?? this.currentArticles,
      originalParts: originalParts ?? this.originalParts,
      currentParts: currentParts ?? this.currentParts,
      originalSchedules: originalSchedules ?? this.originalSchedules,
      currentSchedules: currentSchedules ?? this.currentSchedules,
      currentAmendments: currentAmendments ?? this.currentAmendments,
      officialSources: officialSources ?? List.from(this.officialSources),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'dateAdopted': dateAdopted.toIso8601String(),
        'dateEnforced': dateEnforced.toIso8601String(),
        'constituentAssembly': constituentAssembly,
        'originalArticles': originalArticles,
        'currentArticles': currentArticles,
        'originalParts': originalParts,
        'currentParts': currentParts,
        'originalSchedules': originalSchedules,
        'currentSchedules': currentSchedules,
        'currentAmendments': currentAmendments,
        'officialSources': officialSources,
      };

  factory ConstitutionMetadata.fromJson(Map<String, dynamic> json) =>
      ConstitutionMetadata(
        title: json['title'] as String? ?? 'Constitution of India',
        dateAdopted: DateTime.tryParse(json['dateAdopted'] as String? ?? '') ??
            DateTime(1949, 11, 26),
        dateEnforced:
            DateTime.tryParse(json['dateEnforced'] as String? ?? '') ??
                DateTime(1950, 1, 26),
        constituentAssembly: json['constituentAssembly'] as String? ??
            'Constituent Assembly of India',
        originalArticles: (json['originalArticles'] as num?)?.toInt() ?? 395,
        currentArticles: (json['currentArticles'] as num?)?.toInt() ?? 448,
        originalParts: (json['originalParts'] as num?)?.toInt() ?? 22,
        currentParts: (json['currentParts'] as num?)?.toInt() ?? 25,
        originalSchedules: (json['originalSchedules'] as num?)?.toInt() ?? 8,
        currentSchedules: (json['currentSchedules'] as num?)?.toInt() ?? 12,
        currentAmendments: (json['currentAmendments'] as num?)?.toInt() ?? 106,
        officialSources: (json['officialSources'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConstitutionMetadata &&
        other.title == title &&
        other.originalArticles == originalArticles &&
        other.originalParts == originalParts &&
        other.currentParts == currentParts &&
        other.currentSchedules == currentSchedules;
  }

  @override
  int get hashCode => Object.hash(title, originalArticles, currentParts, currentSchedules);
}
