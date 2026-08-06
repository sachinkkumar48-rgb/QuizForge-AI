library;

import 'package:meta/meta.dart';
import 'constitution_enums.dart';
import 'constitution_knowledge_object.dart';

/// Production-grade domain entity representing a Constitutional Schedule Knowledge Object.
@immutable
class ScheduleKnowledgeObject extends ConstitutionKnowledgeObject {
  final String scheduleNumber;
  final String purpose;
  final ScheduleType scheduleType;

  const ScheduleKnowledgeObject({
    required this.scheduleNumber,
    required super.objectId,
    required super.title,
    required super.officialName,
    required super.description,
    required this.purpose,
    this.scheduleType = ScheduleType.territorial,
    super.officialSource = 'Legislative Department, Ministry of Law and Justice',
    super.status = ConstitutionStatus.active,
    super.version = 1,
    required super.effectiveDate,
    super.keywords = const [],
    super.aliases = const [],
    super.timeline = const [],
    super.crossReferences = const [],
    super.relatedParts = const [],
    super.relatedSchedules = const [],
    super.relatedArticles = const [],
    super.relatedAmendments = const [],
    super.relatedCases = const [],
    super.relatedActs = const [],
    super.relatedPYQs = const [],
    super.relatedCurrentAffairs = const [],
    super.editorialStatus = 'APPROVED',
    super.evidenceReferences = const [],
    super.knowledgeGraphLinks = const [],
  });

  @override
  Map<String, dynamic> toJson() {
    final base = super.toJson();
    base.addAll({
      'scheduleNumber': scheduleNumber,
      'purpose': purpose,
      'scheduleType': scheduleType.name,
    });
    return base;
  }

  factory ScheduleKnowledgeObject.fromJson(Map<String, dynamic> json) {
    final base = ConstitutionKnowledgeObject.fromJson(json);
    final sTypeStr = json['scheduleType'] as String? ?? 'territorial';
    final scheduleType = ScheduleType.values.firstWhere(
      (e) => e.name == sTypeStr,
      orElse: () => ScheduleType.territorial,
    );

    return ScheduleKnowledgeObject(
      scheduleNumber: json['scheduleNumber'] as String? ?? '',
      objectId: base.objectId,
      title: base.title,
      officialName: base.officialName,
      description: base.description,
      purpose: json['purpose'] as String? ?? base.description,
      scheduleType: scheduleType,
      officialSource: base.officialSource,
      status: base.status,
      version: base.version,
      effectiveDate: base.effectiveDate,
      keywords: base.keywords,
      aliases: base.aliases,
      timeline: base.timeline,
      crossReferences: base.crossReferences,
      relatedParts: base.relatedParts,
      relatedSchedules: base.relatedSchedules,
      relatedArticles: base.relatedArticles,
      relatedAmendments: base.relatedAmendments,
      relatedCases: base.relatedCases,
      relatedActs: base.relatedActs,
      relatedPYQs: base.relatedPYQs,
      relatedCurrentAffairs: base.relatedCurrentAffairs,
      editorialStatus: base.editorialStatus,
      evidenceReferences: base.evidenceReferences,
      knowledgeGraphLinks: base.knowledgeGraphLinks,
    );
  }
}
