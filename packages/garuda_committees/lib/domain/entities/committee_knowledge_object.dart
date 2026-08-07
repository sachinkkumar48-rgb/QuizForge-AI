library;

import 'package:garuda_editor/garuda_editor.dart';
import 'package:meta/meta.dart';
import 'committee_enums.dart';
import 'committee_member.dart';
import 'committee_report.dart';
import 'committee_timeline.dart';
import 'recommendation.dart';
import 'terms_of_reference.dart';

/// Permanent, interconnected Committee & Commission Knowledge Object in GARUDA ecosystem.
@immutable
class CommitteeKnowledgeObject {
  final String id;
  final String officialName;
  final String shortName;
  final CommitteeCategory category;
  final String constitutingAuthority;
  final CommitteeMember chairperson;
  final List<CommitteeMember> members;
  final int yearConstituted;
  final int? yearDissolved;
  final CommitteeStatus currentStatus;
  final TermsOfReference termsOfReference;
  final List<String> objectives;
  final List<Recommendation> recommendations;
  final String implementationStatus;
  final List<String> relatedMinistries;
  final List<String> relatedActIds;
  final List<String> relatedArticleIds;
  final List<String> relatedCaseLawIds;
  final List<String> relatedDoctrineIds;
  final List<CommitteeReport> reports;
  final List<String> relatedSchemeNames;
  final List<String> relatedCurrentAffairsIds;
  final List<String> relatedPyqIds;
  final String officialReportUrl;
  final String gazetteReference;
  final List<String> evidenceIds;
  final List<String> keywords;
  final List<CommitteeTimeline> timeline;
  final int version;
  final EditorialStatus editorialStatus;
  final Map<String, dynamic> metadata;

  CommitteeKnowledgeObject({
    required this.id,
    required this.officialName,
    required this.shortName,
    required this.category,
    required this.constitutingAuthority,
    required this.chairperson,
    this.members = const [],
    required this.yearConstituted,
    this.yearDissolved,
    this.currentStatus = CommitteeStatus.submitted,
    required this.termsOfReference,
    this.objectives = const [],
    this.recommendations = const [],
    this.implementationStatus = 'Submitted to Government',
    this.relatedMinistries = const [],
    this.relatedActIds = const [],
    this.relatedArticleIds = const [],
    this.relatedCaseLawIds = const [],
    this.relatedDoctrineIds = const [],
    this.reports = const [],
    this.relatedSchemeNames = const [],
    this.relatedCurrentAffairsIds = const [],
    this.relatedPyqIds = const [],
    this.officialReportUrl = '',
    this.gazetteReference = '',
    this.evidenceIds = const [],
    this.keywords = const [],
    this.timeline = const [],
    this.version = 1,
    this.editorialStatus = EditorialStatus.imported,
    Map<String, dynamic>? metadata,
  }) : metadata = Map<String, dynamic>.from(metadata ?? const {});

  /// Alias getter for Commission objects.
  bool get isCommission =>
      category == CommitteeCategory.constitutional ||
      category == CommitteeCategory.statutory ||
      category == CommitteeCategory.commissionOfInquiry;

  /// Bridge helper converting to base GARUDA KnowledgeObject format for Editorial Production Engine.
  KnowledgeObject toGarudaKnowledgeObject() {
    return KnowledgeObject(
      id: id,
      title: officialName,
      subject: category.displayName,
      topic: shortName.isNotEmpty ? shortName : officialName,
      subtopic: constitutingAuthority,
      summary: termsOfReference.description.isNotEmpty ? termsOfReference.description : officialName,
      content:
          'Chairperson: ${chairperson.name}. Constituting Authority: $constitutingAuthority. Terms of Reference: ${termsOfReference.description}. Objectives: ${objectives.join("; ")}. Implementation Status: $implementationStatus. Key Recommendations: ${recommendations.map((r) => r.title).join("; ")}.',

      officialSource: constitutingAuthority,
      evidenceIds: evidenceIds,
      status: editorialStatus,
      version: version,
      package: 'garuda_committees',
      knowledgeType: isCommission ? 'CommissionKnowledgeObject' : 'CommitteeKnowledgeObject',
      relatedArticles: relatedArticleIds,
      relatedCaseLaws: relatedCaseLawIds,
      tags: keywords,
      isVerified: evidenceIds.isNotEmpty && editorialStatus == EditorialStatus.published,
      metadata: {
        ...metadata,
        'yearConstituted': yearConstituted,
        'yearDissolved': yearDissolved,
        'category': category.name,
        'status': currentStatus.name,
        'relatedActIds': relatedActIds,
        'relatedSchemeNames': relatedSchemeNames,
        'relatedPyqIds': relatedPyqIds,
        'relatedCurrentAffairsIds': relatedCurrentAffairsIds,
        'officialReportUrl': officialReportUrl,
        'gazetteReference': gazetteReference,
      },
    );
  }

  CommitteeKnowledgeObject copyWith({
    String? id,
    String? officialName,
    String? shortName,
    CommitteeCategory? category,
    String? constitutingAuthority,
    CommitteeMember? chairperson,
    List<CommitteeMember>? members,
    int? yearConstituted,
    int? yearDissolved,
    CommitteeStatus? currentStatus,
    TermsOfReference? termsOfReference,
    List<String>? objectives,
    List<Recommendation>? recommendations,
    String? implementationStatus,
    List<String>? relatedMinistries,
    List<String>? relatedActIds,
    List<String>? relatedArticleIds,
    List<String>? relatedCaseLawIds,
    List<String>? relatedDoctrineIds,
    List<CommitteeReport>? reports,
    List<String>? relatedSchemeNames,
    List<String>? relatedCurrentAffairsIds,
    List<String>? relatedPyqIds,
    String? officialReportUrl,
    String? gazetteReference,
    List<String>? evidenceIds,
    List<String>? keywords,
    List<CommitteeTimeline>? timeline,
    int? version,
    EditorialStatus? editorialStatus,
    Map<String, dynamic>? metadata,
  }) {
    return CommitteeKnowledgeObject(
      id: id ?? this.id,
      officialName: officialName ?? this.officialName,
      shortName: shortName ?? this.shortName,
      category: category ?? this.category,
      constitutingAuthority: constitutingAuthority ?? this.constitutingAuthority,
      chairperson: chairperson ?? this.chairperson,
      members: members ?? List.from(this.members),
      yearConstituted: yearConstituted ?? this.yearConstituted,
      yearDissolved: yearDissolved ?? this.yearDissolved,
      currentStatus: currentStatus ?? this.currentStatus,
      termsOfReference: termsOfReference ?? this.termsOfReference,
      objectives: objectives ?? List.from(this.objectives),
      recommendations: recommendations ?? List.from(this.recommendations),
      implementationStatus: implementationStatus ?? this.implementationStatus,
      relatedMinistries: relatedMinistries ?? List.from(this.relatedMinistries),
      relatedActIds: relatedActIds ?? List.from(this.relatedActIds),
      relatedArticleIds: relatedArticleIds ?? List.from(this.relatedArticleIds),
      relatedCaseLawIds: relatedCaseLawIds ?? List.from(this.relatedCaseLawIds),
      relatedDoctrineIds: relatedDoctrineIds ?? List.from(this.relatedDoctrineIds),
      reports: reports ?? List.from(this.reports),
      relatedSchemeNames: relatedSchemeNames ?? List.from(this.relatedSchemeNames),
      relatedCurrentAffairsIds: relatedCurrentAffairsIds ?? List.from(this.relatedCurrentAffairsIds),
      relatedPyqIds: relatedPyqIds ?? List.from(this.relatedPyqIds),
      officialReportUrl: officialReportUrl ?? this.officialReportUrl,
      gazetteReference: gazetteReference ?? this.gazetteReference,
      evidenceIds: evidenceIds ?? List.from(this.evidenceIds),
      keywords: keywords ?? List.from(this.keywords),
      timeline: timeline ?? List.from(this.timeline),
      version: version ?? this.version,
      editorialStatus: editorialStatus ?? this.editorialStatus,
      metadata: metadata ?? Map.from(this.metadata),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'officialName': officialName,
        'shortName': shortName,
        'category': category.name,
        'constitutingAuthority': constitutingAuthority,
        'chairperson': chairperson.toJson(),
        'members': members.map((m) => m.toJson()).toList(),
        'yearConstituted': yearConstituted,
        'yearDissolved': yearDissolved,
        'currentStatus': currentStatus.name,
        'termsOfReference': termsOfReference.toJson(),
        'objectives': objectives,
        'recommendations': recommendations.map((r) => r.toJson()).toList(),
        'implementationStatus': implementationStatus,
        'relatedMinistries': relatedMinistries,
        'relatedActIds': relatedActIds,
        'relatedArticleIds': relatedArticleIds,
        'relatedCaseLawIds': relatedCaseLawIds,
        'relatedDoctrineIds': relatedDoctrineIds,
        'reports': reports.map((r) => r.toJson()).toList(),
        'relatedSchemeNames': relatedSchemeNames,
        'relatedCurrentAffairsIds': relatedCurrentAffairsIds,
        'relatedPyqIds': relatedPyqIds,
        'officialReportUrl': officialReportUrl,
        'gazetteReference': gazetteReference,
        'evidenceIds': evidenceIds,
        'keywords': keywords,
        'timeline': timeline.map((t) => t.toJson()).toList(),
        'version': version,
        'editorialStatus': editorialStatus.name,
        'metadata': metadata,
      };

  factory CommitteeKnowledgeObject.fromJson(Map<String, dynamic> json) =>
      CommitteeKnowledgeObject(
        id: json['id'] as String? ?? '',
        officialName: json['officialName'] as String? ?? '',
        shortName: json['shortName'] as String? ?? '',
        category: CommitteeCategory.values.firstWhere(
          (c) => c.name == json['category'],
          orElse: () => CommitteeCategory.executive,
        ),
        constitutingAuthority: json['constitutingAuthority'] as String? ?? '',
        chairperson: CommitteeMember.fromJson(
            Map<String, dynamic>.from(json['chairperson'] as Map? ?? {})),
        members: (json['members'] as List?)
                ?.map((m) => CommitteeMember.fromJson(Map<String, dynamic>.from(m as Map)))
                .toList() ??
            const [],
        yearConstituted: (json['yearConstituted'] as num?)?.toInt() ?? 1947,
        yearDissolved: (json['yearDissolved'] as num?)?.toInt(),
        currentStatus: CommitteeStatus.values.firstWhere(
          (s) => s.name == json['currentStatus'],
          orElse: () => CommitteeStatus.submitted,
        ),
        termsOfReference: TermsOfReference.fromJson(
            Map<String, dynamic>.from(json['termsOfReference'] as Map? ?? {})),
        objectives: (json['objectives'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        recommendations: (json['recommendations'] as List?)
                ?.map((r) => Recommendation.fromJson(Map<String, dynamic>.from(r as Map)))
                .toList() ??
            const [],
        implementationStatus: json['implementationStatus'] as String? ?? '',
        relatedMinistries:
            (json['relatedMinistries'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        relatedActIds:
            (json['relatedActIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        relatedArticleIds:
            (json['relatedArticleIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        relatedCaseLawIds:
            (json['relatedCaseLawIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        relatedDoctrineIds:
            (json['relatedDoctrineIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        reports: (json['reports'] as List?)
                ?.map((r) => CommitteeReport.fromJson(Map<String, dynamic>.from(r as Map)))
                .toList() ??
            const [],
        relatedSchemeNames:
            (json['relatedSchemeNames'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        relatedCurrentAffairsIds:
            (json['relatedCurrentAffairsIds'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        relatedPyqIds:
            (json['relatedPyqIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        officialReportUrl: json['officialReportUrl'] as String? ?? '',
        gazetteReference: json['gazetteReference'] as String? ?? '',
        evidenceIds:
            (json['evidenceIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        keywords: (json['keywords'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        timeline: (json['timeline'] as List?)
                ?.map((t) => CommitteeTimeline.fromJson(Map<String, dynamic>.from(t as Map)))
                .toList() ??
            const [],
        version: (json['version'] as num?)?.toInt() ?? 1,
        editorialStatus: EditorialStatus.values.firstWhere(
          (s) => s.name == json['editorialStatus'],
          orElse: () => EditorialStatus.imported,
        ),
        metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      );
}

/// Type alias for Commissions.
typedef CommissionKnowledgeObject = CommitteeKnowledgeObject;
