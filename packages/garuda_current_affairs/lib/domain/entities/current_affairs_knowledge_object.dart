library;

import 'package:garuda_editor/garuda_editor.dart';
import 'package:meta/meta.dart';
import 'current_affairs_enums.dart';

/// UPSC Intelligence metadata payload embedded in CurrentAffairsKnowledgeObject.
@immutable
class UpscIntelligence {
  final double relevanceScore; // 0.0 to 100.0
  final double prelimsWeight; // Expected weight percentage 0-100
  final double mainsWeight; // Expected weight percentage 0-100
  final double interviewRelevance; // 0.0 to 100.0
  final List<String> relatedPyqIds;
  final List<String> relatedStaticTopics;
  final List<String> likelyRevisionAreas;

  const UpscIntelligence({
    required this.relevanceScore,
    required this.prelimsWeight,
    required this.mainsWeight,
    required this.interviewRelevance,
    this.relatedPyqIds = const [],
    this.relatedStaticTopics = const [],
    this.likelyRevisionAreas = const [],
  });

  Map<String, dynamic> toJson() => {
        'relevanceScore': relevanceScore,
        'prelimsWeight': prelimsWeight,
        'mainsWeight': mainsWeight,
        'interviewRelevance': interviewRelevance,
        'relatedPyqIds': relatedPyqIds,
        'relatedStaticTopics': relatedStaticTopics,
        'likelyRevisionAreas': likelyRevisionAreas,
      };

  factory UpscIntelligence.fromJson(Map<String, dynamic> json) => UpscIntelligence(
        relevanceScore: (json['relevanceScore'] as num?)?.toDouble() ?? 0.0,
        prelimsWeight: (json['prelimsWeight'] as num?)?.toDouble() ?? 0.0,
        mainsWeight: (json['mainsWeight'] as num?)?.toDouble() ?? 0.0,
        interviewRelevance: (json['interviewRelevance'] as num?)?.toDouble() ?? 0.0,
        relatedPyqIds:
            (json['relatedPyqIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        relatedStaticTopics:
            (json['relatedStaticTopics'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        likelyRevisionAreas:
            (json['likelyRevisionAreas'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
      );
}

/// Comprehensive Knowledge Links mapping from Current Affairs events to permanent static syllabus assets.
@immutable
class KnowledgeLinkSet {
  final List<String> articleIds;
  final List<String> partIds;
  final List<String> scheduleIds;
  final List<String> amendmentIds;
  final List<String> actIds;
  final List<String> actSectionIds;
  final List<String> caseLawIds;
  final List<String> doctrineIds;
  final List<String> committeeNames;
  final List<String> commissionNames;
  final List<String> reportNames;
  final List<String> schemeNames;
  final List<String> internationalOrgNames;
  final List<String> treatyNames;
  final List<String> pyqIds;
  final List<String> conceptIds;
  final List<String> linkedObjectIds;

  const KnowledgeLinkSet({
    this.articleIds = const [],
    this.partIds = const [],
    this.scheduleIds = const [],
    this.amendmentIds = const [],
    this.actIds = const [],
    this.actSectionIds = const [],
    this.caseLawIds = const [],
    this.doctrineIds = const [],
    this.committeeNames = const [],
    this.commissionNames = const [],
    this.reportNames = const [],
    this.schemeNames = const [],
    this.internationalOrgNames = const [],
    this.treatyNames = const [],
    this.pyqIds = const [],
    this.conceptIds = const [],
    this.linkedObjectIds = const [],
  });

  bool get isEmpty =>
      articleIds.isEmpty &&
      partIds.isEmpty &&
      scheduleIds.isEmpty &&
      amendmentIds.isEmpty &&
      actIds.isEmpty &&
      actSectionIds.isEmpty &&
      caseLawIds.isEmpty &&
      doctrineIds.isEmpty &&
      committeeNames.isEmpty &&
      commissionNames.isEmpty &&
      reportNames.isEmpty &&
      schemeNames.isEmpty &&
      internationalOrgNames.isEmpty &&
      treatyNames.isEmpty &&
      pyqIds.isEmpty &&
      conceptIds.isEmpty &&
      linkedObjectIds.isEmpty;

  int get totalLinksCount =>
      articleIds.length +
      partIds.length +
      scheduleIds.length +
      amendmentIds.length +
      actIds.length +
      actSectionIds.length +
      caseLawIds.length +
      doctrineIds.length +
      committeeNames.length +
      commissionNames.length +
      reportNames.length +
      schemeNames.length +
      internationalOrgNames.length +
      treatyNames.length +
      pyqIds.length +
      conceptIds.length +
      linkedObjectIds.length;

  Map<String, dynamic> toJson() => {
        'articleIds': articleIds,
        'partIds': partIds,
        'scheduleIds': scheduleIds,
        'amendmentIds': amendmentIds,
        'actIds': actIds,
        'actSectionIds': actSectionIds,
        'caseLawIds': caseLawIds,
        'doctrineIds': doctrineIds,
        'committeeNames': committeeNames,
        'commissionNames': commissionNames,
        'reportNames': reportNames,
        'schemeNames': schemeNames,
        'internationalOrgNames': internationalOrgNames,
        'treatyNames': treatyNames,
        'pyqIds': pyqIds,
        'conceptIds': conceptIds,
        'linkedObjectIds': linkedObjectIds,
      };

  factory KnowledgeLinkSet.fromJson(Map<String, dynamic> json) => KnowledgeLinkSet(
        articleIds:
            (json['articleIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        partIds: (json['partIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        scheduleIds:
            (json['scheduleIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        amendmentIds:
            (json['amendmentIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        actIds: (json['actIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        actSectionIds:
            (json['actSectionIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        caseLawIds:
            (json['caseLawIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        doctrineIds:
            (json['doctrineIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        committeeNames:
            (json['committeeNames'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        commissionNames:
            (json['commissionNames'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        reportNames:
            (json['reportNames'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        schemeNames:
            (json['schemeNames'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        internationalOrgNames: (json['internationalOrgNames'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        treatyNames:
            (json['treatyNames'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        pyqIds: (json['pyqIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        conceptIds:
            (json['conceptIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        linkedObjectIds:
            (json['linkedObjectIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      );
}

/// Permanent, interconnected Current Affairs Knowledge Object in GARUDA ecosystem.
@immutable
class CurrentAffairsKnowledgeObject {
  final String id; // Event ID
  final String headline;
  final String summary;
  final String content;
  final String officialSource;
  final String sourceUrl;
  final DateTime publicationDate;
  final DateTime retrievedDate;
  final CurrentAffairsCategory category;
  final String subcategory;
  final String country;
  final String state;
  final String ministry;
  final CurrentAffairsImportance importance;
  final List<String> keywords;
  final List<String> tags;
  final String timelinePosition;
  final List<String> evidenceIds;
  final EditorialStatus editorialStatus;
  final int version;
  final UpscIntelligence intelligence;
  final KnowledgeLinkSet links;
  final Map<String, dynamic> metadata;

  CurrentAffairsKnowledgeObject({
    required this.id,
    required this.headline,
    required this.summary,
    required this.content,
    required this.officialSource,
    this.sourceUrl = '',
    required this.publicationDate,
    DateTime? retrievedDate,
    this.category = CurrentAffairsCategory.miscellaneous,
    this.subcategory = '',
    this.country = 'India',
    this.state = '',
    this.ministry = '',
    this.importance = CurrentAffairsImportance.medium,
    this.keywords = const [],
    this.tags = const [],
    this.timelinePosition = '',
    this.evidenceIds = const [],
    this.editorialStatus = EditorialStatus.imported,
    this.version = 1,
    required this.intelligence,
    this.links = const KnowledgeLinkSet(),
    Map<String, dynamic>? metadata,
  })  : retrievedDate = retrievedDate ?? DateTime.now(),
        metadata = Map<String, dynamic>.from(metadata ?? const {});

  /// Bridge helper converting to base GARUDA KnowledgeObject format for Editorial Production Engine.
  KnowledgeObject toGarudaKnowledgeObject() {
    return KnowledgeObject(
      id: id,
      title: headline,
      subject: category.displayName,
      topic: subcategory.isNotEmpty ? subcategory : category.displayName,
      subtopic: ministry,
      summary: summary,
      content: content,
      officialSource: officialSource,
      evidenceIds: evidenceIds,
      status: editorialStatus,
      version: version,
      package: 'garuda_current_affairs',
      knowledgeType: 'CurrentAffairsKnowledgeObject',
      relatedArticles: links.articleIds,
      relatedCaseLaws: links.caseLawIds,
      tags: tags,
      isVerified: evidenceIds.isNotEmpty && editorialStatus == EditorialStatus.published,
      metadata: {
        ...metadata,
        'country': country,
        'state': state,
        'ministry': ministry,
        'importance': importance.name,
        'category': category.name,
        'publicationDate': publicationDate.toIso8601String(),
        'retrievedDate': retrievedDate.toIso8601String(),
        'relevanceScore': intelligence.relevanceScore,
        'prelimsWeight': intelligence.prelimsWeight,
        'mainsWeight': intelligence.mainsWeight,
        'interviewRelevance': intelligence.interviewRelevance,
      },
    );
  }

  CurrentAffairsKnowledgeObject copyWith({
    String? id,
    String? headline,
    String? summary,
    String? content,
    String? officialSource,
    String? sourceUrl,
    DateTime? publicationDate,
    DateTime? retrievedDate,
    CurrentAffairsCategory? category,
    String? subcategory,
    String? country,
    String? state,
    String? ministry,
    CurrentAffairsImportance? importance,
    List<String>? keywords,
    List<String>? tags,
    String? timelinePosition,
    List<String>? evidenceIds,
    EditorialStatus? editorialStatus,
    int? version,
    UpscIntelligence? intelligence,
    KnowledgeLinkSet? links,
    Map<String, dynamic>? metadata,
  }) {
    return CurrentAffairsKnowledgeObject(
      id: id ?? this.id,
      headline: headline ?? this.headline,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      officialSource: officialSource ?? this.officialSource,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      publicationDate: publicationDate ?? this.publicationDate,
      retrievedDate: retrievedDate ?? this.retrievedDate,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      country: country ?? this.country,
      state: state ?? this.state,
      ministry: ministry ?? this.ministry,
      importance: importance ?? this.importance,
      keywords: keywords ?? List.from(this.keywords),
      tags: tags ?? List.from(this.tags),
      timelinePosition: timelinePosition ?? this.timelinePosition,
      evidenceIds: evidenceIds ?? List.from(this.evidenceIds),
      editorialStatus: editorialStatus ?? this.editorialStatus,
      version: version ?? this.version,
      intelligence: intelligence ?? this.intelligence,
      links: links ?? this.links,
      metadata: metadata ?? Map.from(this.metadata),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'headline': headline,
        'summary': summary,
        'content': content,
        'officialSource': officialSource,
        'sourceUrl': sourceUrl,
        'publicationDate': publicationDate.toIso8601String(),
        'retrievedDate': retrievedDate.toIso8601String(),
        'category': category.name,
        'subcategory': subcategory,
        'country': country,
        'state': state,
        'ministry': ministry,
        'importance': importance.name,
        'keywords': keywords,
        'tags': tags,
        'timelinePosition': timelinePosition,
        'evidenceIds': evidenceIds,
        'editorialStatus': editorialStatus.name,
        'version': version,
        'intelligence': intelligence.toJson(),
        'links': links.toJson(),
        'metadata': metadata,
      };

  factory CurrentAffairsKnowledgeObject.fromJson(Map<String, dynamic> json) =>
      CurrentAffairsKnowledgeObject(
        id: json['id'] as String? ?? '',
        headline: json['headline'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
        content: json['content'] as String? ?? '',
        officialSource: json['officialSource'] as String? ?? '',
        sourceUrl: json['sourceUrl'] as String? ?? '',
        publicationDate:
            DateTime.tryParse(json['publicationDate'] as String? ?? '') ?? DateTime.now(),
        retrievedDate:
            DateTime.tryParse(json['retrievedDate'] as String? ?? '') ?? DateTime.now(),
        category: CurrentAffairsCategory.values.firstWhere(
          (c) => c.name == json['category'],
          orElse: () => CurrentAffairsCategory.miscellaneous,
        ),
        subcategory: json['subcategory'] as String? ?? '',
        country: json['country'] as String? ?? 'India',
        state: json['state'] as String? ?? '',
        ministry: json['ministry'] as String? ?? '',
        importance: CurrentAffairsImportance.values.firstWhere(
          (i) => i.name == json['importance'],
          orElse: () => CurrentAffairsImportance.medium,
        ),
        keywords: (json['keywords'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        timelinePosition: json['timelinePosition'] as String? ?? '',
        evidenceIds:
            (json['evidenceIds'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        editorialStatus: EditorialStatus.values.firstWhere(
          (s) => s.name == json['editorialStatus'],
          orElse: () => EditorialStatus.imported,
        ),
        version: (json['version'] as num?)?.toInt() ?? 1,
        intelligence: UpscIntelligence.fromJson(
            Map<String, dynamic>.from(json['intelligence'] as Map? ?? {})),
        links: KnowledgeLinkSet.fromJson(
            Map<String, dynamic>.from(json['links'] as Map? ?? {})),
        metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      );
}
