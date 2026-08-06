library;

import 'package:meta/meta.dart';

/// Chapter container entity in an Act.
@immutable
class ActChapter {
  final String chapterId;
  final String actId;
  final String chapterNumber;
  final String title;
  final String description;
  final List<String> sectionNumbers;
  final List<String> keywords;

  const ActChapter({
    required this.chapterId,
    required this.actId,
    required this.chapterNumber,
    required this.title,
    required this.description,
    required this.sectionNumbers,
    this.keywords = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'chapterId': chapterId,
      'actId': actId,
      'chapterNumber': chapterNumber,
      'title': title,
      'description': description,
      'sectionNumbers': sectionNumbers,
      'keywords': keywords,
    };
  }

  factory ActChapter.fromJson(Map<String, dynamic> json) {
    return ActChapter(
      chapterId: json['chapterId'] as String,
      actId: json['actId'] as String,
      chapterNumber: json['chapterNumber'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      sectionNumbers: List<String>.from(json['sectionNumbers'] as List? ?? []),
      keywords: List<String>.from(json['keywords'] as List? ?? []),
    );
  }
}
