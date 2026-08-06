library;

import 'package:meta/meta.dart';
import 'act_enums.dart';

/// Independently addressable, searchable, and linkable Statutory Section.
@immutable
class ActSection {
  final String sectionId;
  final String actId;
  final String? chapterId;
  final String sectionNumber;
  final String title;
  final String content;
  final List<String> explanations;
  final List<String> exceptions;
  final SectionType type;
  final bool isImportant;
  final List<String> keywords;
  final List<String> relatedArticles;
  final List<String> landmarkCases;
  final List<String> relatedDoctrines;
  final List<String> pyqIds;
  final List<String> currentAffairsIds;
  final String? reformEquivalent;
  final List<String> evidenceReferences;

  const ActSection({
    required this.sectionId,
    required this.actId,
    this.chapterId,
    required this.sectionNumber,
    required this.title,
    required this.content,
    this.explanations = const [],
    this.exceptions = const [],
    this.type = SectionType.substantive,
    this.isImportant = false,
    this.keywords = const [],
    this.relatedArticles = const [],
    this.landmarkCases = const [],
    this.relatedDoctrines = const [],
    this.pyqIds = const [],
    this.currentAffairsIds = const [],
    this.reformEquivalent,
    this.evidenceReferences = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'sectionId': sectionId,
      'actId': actId,
      'chapterId': chapterId,
      'sectionNumber': sectionNumber,
      'title': title,
      'content': content,
      'explanations': explanations,
      'exceptions': exceptions,
      'type': type.name,
      'isImportant': isImportant,
      'keywords': keywords,
      'relatedArticles': relatedArticles,
      'landmarkCases': landmarkCases,
      'relatedDoctrines': relatedDoctrines,
      'pyqIds': pyqIds,
      'currentAffairsIds': currentAffairsIds,
      'reformEquivalent': reformEquivalent,
      'evidenceReferences': evidenceReferences,
    };
  }

  factory ActSection.fromJson(Map<String, dynamic> json) {
    return ActSection(
      sectionId: json['sectionId'] as String,
      actId: json['actId'] as String,
      chapterId: json['chapterId'] as String?,
      sectionNumber: json['sectionNumber'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      explanations: List<String>.from(json['explanations'] as List? ?? []),
      exceptions: List<String>.from(json['exceptions'] as List? ?? []),
      type: SectionType.values.byName(json['type'] as String? ?? 'substantive'),
      isImportant: json['isImportant'] as bool? ?? false,
      keywords: List<String>.from(json['keywords'] as List? ?? []),
      relatedArticles: List<String>.from(json['relatedArticles'] as List? ?? []),
      landmarkCases: List<String>.from(json['landmarkCases'] as List? ?? []),
      relatedDoctrines: List<String>.from(json['relatedDoctrines'] as List? ?? []),
      pyqIds: List<String>.from(json['pyqIds'] as List? ?? []),
      currentAffairsIds: List<String>.from(json['currentAffairsIds'] as List? ?? []),
      reformEquivalent: json['reformEquivalent'] as String?,
      evidenceReferences: List<String>.from(json['evidenceReferences'] as List? ?? []),
    );
  }
}
