library;

import 'package:meta/meta.dart';

/// Subordinate Legislation / Executive Rule framed under an Act.
@immutable
class ActRule {
  final String ruleId;
  final String actId;
  final String ruleNumber;
  final String title;
  final String sourceSectionNumber;
  final String content;
  final String scope;

  const ActRule({
    required this.ruleId,
    required this.actId,
    required this.ruleNumber,
    required this.title,
    required this.sourceSectionNumber,
    required this.content,
    required this.scope,
  });

  Map<String, dynamic> toJson() {
    return {
      'ruleId': ruleId,
      'actId': actId,
      'ruleNumber': ruleNumber,
      'title': title,
      'sourceSectionNumber': sourceSectionNumber,
      'content': content,
      'scope': scope,
    };
  }

  factory ActRule.fromJson(Map<String, dynamic> json) {
    return ActRule(
      ruleId: json['ruleId'] as String,
      actId: json['actId'] as String,
      ruleNumber: json['ruleNumber'] as String,
      title: json['title'] as String,
      sourceSectionNumber: json['sourceSectionNumber'] as String,
      content: json['content'] as String,
      scope: json['scope'] as String,
    );
  }
}
