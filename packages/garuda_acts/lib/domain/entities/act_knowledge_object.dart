library;

import 'package:meta/meta.dart';
import 'act_enums.dart';
import 'act_metadata.dart';
import 'act_chapter.dart';
import 'act_section.dart';
import 'act_schedule.dart';
import 'act_amendment.dart';
import 'act_rule.dart';
import 'act_notification.dart';
import 'act_relationship.dart';

/// Primary Knowledge Object representing a Central Act in GARUDA Knowledge Repository.
@immutable
class ActKnowledgeObject {
  final String objectId;
  final String actId;
  final ActMetadata metadata;
  final List<ActChapter> chapters;
  final List<ActSection> sections;
  final List<ActSchedule> schedules;
  final List<ActAmendment> amendments;
  final List<ActRule> rules;
  final List<ActNotification> notifications;
  final List<ActRelationship> relationships;
  final List<String> importantProvisions;
  final List<String> landmarkCases;
  final List<String> relatedArticles;
  final List<String> relatedDoctrines;
  final List<String> relatedCommittees;
  final List<String> relatedReports;
  final List<String> relatedCurrentAffairs;
  final List<String> relatedPyqIds;
  final List<String> searchKeywords;
  final List<String> evidenceReferences;
  final EditorialStatus editorialStatus;
  final int version;

  const ActKnowledgeObject({
    required this.objectId,
    required this.actId,
    required this.metadata,
    this.chapters = const [],
    this.sections = const [],
    this.schedules = const [],
    this.amendments = const [],
    this.rules = const [],
    this.notifications = const [],
    this.relationships = const [],
    this.importantProvisions = const [],
    this.landmarkCases = const [],
    this.relatedArticles = const [],
    this.relatedDoctrines = const [],
    this.relatedCommittees = const [],
    this.relatedReports = const [],
    this.relatedCurrentAffairs = const [],
    this.relatedPyqIds = const [],
    this.searchKeywords = const [],
    this.evidenceReferences = const [],
    this.editorialStatus = EditorialStatus.productionReady,
    this.version = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'objectId': objectId,
      'actId': actId,
      'metadata': metadata.toJson(),
      'chapters': chapters.map((c) => c.toJson()).toList(),
      'sections': sections.map((s) => s.toJson()).toList(),
      'schedules': schedules.map((s) => s.toJson()).toList(),
      'amendments': amendments.map((a) => a.toJson()).toList(),
      'rules': rules.map((r) => r.toJson()).toList(),
      'notifications': notifications.map((n) => n.toJson()).toList(),
      'relationships': relationships.map((r) => r.toJson()).toList(),
      'importantProvisions': importantProvisions,
      'landmarkCases': landmarkCases,
      'relatedArticles': relatedArticles,
      'relatedDoctrines': relatedDoctrines,
      'relatedCommittees': relatedCommittees,
      'relatedReports': relatedReports,
      'relatedCurrentAffairs': relatedCurrentAffairs,
      'relatedPyqIds': relatedPyqIds,
      'searchKeywords': searchKeywords,
      'evidenceReferences': evidenceReferences,
      'editorialStatus': editorialStatus.name,
      'version': version,
    };
  }

  factory ActKnowledgeObject.fromJson(Map<String, dynamic> json) {
    return ActKnowledgeObject(
      objectId: json['objectId'] as String,
      actId: json['actId'] as String,
      metadata: ActMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
      chapters: (json['chapters'] as List? ?? [])
          .map((c) => ActChapter.fromJson(c as Map<String, dynamic>))
          .toList(),
      sections: (json['sections'] as List? ?? [])
          .map((s) => ActSection.fromJson(s as Map<String, dynamic>))
          .toList(),
      schedules: (json['schedules'] as List? ?? [])
          .map((s) => ActSchedule.fromJson(s as Map<String, dynamic>))
          .toList(),
      amendments: (json['amendments'] as List? ?? [])
          .map((a) => ActAmendment.fromJson(a as Map<String, dynamic>))
          .toList(),
      rules: (json['rules'] as List? ?? [])
          .map((r) => ActRule.fromJson(r as Map<String, dynamic>))
          .toList(),
      notifications: (json['notifications'] as List? ?? [])
          .map((n) => ActNotification.fromJson(n as Map<String, dynamic>))
          .toList(),
      relationships: (json['relationships'] as List? ?? [])
          .map((r) => ActRelationship.fromJson(r as Map<String, dynamic>))
          .toList(),
      importantProvisions: List<String>.from(json['importantProvisions'] as List? ?? []),
      landmarkCases: List<String>.from(json['landmarkCases'] as List? ?? []),
      relatedArticles: List<String>.from(json['relatedArticles'] as List? ?? []),
      relatedDoctrines: List<String>.from(json['relatedDoctrines'] as List? ?? []),
      relatedCommittees: List<String>.from(json['relatedCommittees'] as List? ?? []),
      relatedReports: List<String>.from(json['relatedReports'] as List? ?? []),
      relatedCurrentAffairs: List<String>.from(json['relatedCurrentAffairs'] as List? ?? []),
      relatedPyqIds: List<String>.from(json['relatedPyqIds'] as List? ?? []),
      searchKeywords: List<String>.from(json['searchKeywords'] as List? ?? []),
      evidenceReferences: List<String>.from(json['evidenceReferences'] as List? ?? []),
      editorialStatus: EditorialStatus.values.byName(json['editorialStatus'] as String? ?? 'productionReady'),
      version: json['version'] as int? ?? 1,
    );
  }
}
