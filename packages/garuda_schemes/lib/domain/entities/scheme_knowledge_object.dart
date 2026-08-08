library;

import 'package:garuda_editor/garuda_editor.dart';
import 'package:meta/meta.dart';
import 'scheme_beneficiary.dart';
import 'scheme_benefit.dart';
import 'scheme_component.dart';
import 'scheme_enums.dart';
import 'scheme_funding.dart';
import 'scheme_ministry.dart';
import 'scheme_relationship.dart';
import 'scheme_timeline.dart';

/// Permanent, interconnected Government Scheme Knowledge Object in the
/// GARUDA Government Schemes Knowledge Library. Every Scheme is modelled as an
/// independent, searchable, evidence-backed Knowledge Object linked to the
/// Constitution, Acts, Committees, Reports, Case Law, Doctrines, Current
/// Affairs, PYQs, Ministries and SDGs.
@immutable
class SchemeKnowledgeObject {
  final String id;
  final String officialName;
  final String shortName;
  final SchemeType schemeType;
  final SchemeCategory category;
  final SchemeSector sector;
  final SchemeMinistry ministry;
  final String department;
  final SchemeStatus status;
  final DateTime? launchDate;
  final String implementingAgency;
  final List<BeneficiaryGroup> beneficiaries;
  final List<String> targetBeneficiaries;
  final List<String> eligibility;
  final List<String> objectives;
  final List<String> keyFeatures;
  final List<SchemeBenefit> benefits;
  final List<SchemeComponent> components;
  final SchemeFundingDetail funding;
  final String coverage;
  final List<String> geographicScope;
  final RuralUrbanScope ruralUrbanScope;
  final List<String> relatedArticleIds;
  final List<String> relatedActIds;
  final List<String> relatedCaseLawIds;
  final List<String> relatedDoctrineIds;
  final List<String> relatedCommitteeIds;
  final List<String> relatedReportIds;
  final List<String> relatedCurrentAffairsIds;
  final List<String> relatedPyqIds;
  final List<String> relatedSchemeIds;
  final List<String> predecessorSchemeIds;
  final List<String> successorSchemeIds;
  final String? subsumedBySchemeId;
  final List<SdgGoal> sdgGoals;
  final List<SchemeRelationship> relationships;
  final List<SchemeTimeline> timeline;
  final String officialSource;
  final List<String> evidenceIds;
  final String lastVerifiedDate;
  final String upscRelevance;
  final List<String> keywords;
  final int version;
  final EditorialStatus editorialStatus;
  final Map<String, dynamic> metadata;

  SchemeKnowledgeObject({
    required this.id,
    required this.officialName,
    required this.shortName,
    this.schemeType = SchemeType.centralSector,
    this.category = SchemeCategory.agriculture,
    this.sector = SchemeSector.agriculture,
    this.ministry = SchemeMinistry.agricultureFarmersWelfare,
    this.department = '',
    this.status = SchemeStatus.operational,
    this.launchDate,
    this.implementingAgency = '',
    this.beneficiaries = const [],
    this.targetBeneficiaries = const [],
    this.eligibility = const [],
    this.objectives = const [],
    this.keyFeatures = const [],
    this.benefits = const [],
    this.components = const [],
    this.funding = const SchemeFundingDetail(),
    this.coverage = '',
    this.geographicScope = const [],
    this.ruralUrbanScope = RuralUrbanScope.both,
    this.relatedArticleIds = const [],
    this.relatedActIds = const [],
    this.relatedCaseLawIds = const [],
    this.relatedDoctrineIds = const [],
    this.relatedCommitteeIds = const [],
    this.relatedReportIds = const [],
    this.relatedCurrentAffairsIds = const [],
    this.relatedPyqIds = const [],
    this.relatedSchemeIds = const [],
    this.predecessorSchemeIds = const [],
    this.successorSchemeIds = const [],
    this.subsumedBySchemeId,
    this.sdgGoals = const [],
    this.relationships = const [],
    this.timeline = const [],
    this.officialSource = '',
    this.evidenceIds = const [],
    this.lastVerifiedDate = '',
    this.upscRelevance = '',
    this.keywords = const [],
    this.version = 1,
    this.editorialStatus = EditorialStatus.imported,
    Map<String, dynamic>? metadata,
  }) : metadata = Map<String, dynamic>.from(metadata ?? const {});

  /// Bridge helper converting to base GARUDA KnowledgeObject for the
  /// Editorial Production Engine (shared GARUDA knowledge registry/index).
  KnowledgeObject toGarudaKnowledgeObject() {
    return KnowledgeObject(
      id: id,
      title: officialName,
      subject: category.displayName,
      topic: shortName.isNotEmpty ? shortName : officialName,
      subtopic: ministry.displayName,
      summary: coverage.isNotEmpty ? coverage : officialName,
      content:
          'Scheme: $officialName ($shortName). Ministry: ${ministry.displayName}. Status: ${status.displayName}. Funding Pattern: ${funding.fundingPattern.displayName}. Key Features: ${keyFeatures.join("; ")}. Benefits: ${benefits.map((b) => b.title).join("; ")}. Coverage: $coverage.',
      officialSource: officialSource,
      evidenceIds: evidenceIds,
      status: editorialStatus,
      version: version,
      package: 'garuda_schemes',
      knowledgeType: 'SchemeKnowledgeObject',
      relatedArticles: relatedArticleIds,
      relatedCaseLaws: relatedCaseLawIds,
      tags: keywords,
      isVerified: evidenceIds.isNotEmpty &&
          editorialStatus == EditorialStatus.published,
      metadata: {
        ...metadata,
        'ministry': ministry.name,
        'schemeType': schemeType.name,
        'sector': sector.name,
        'category': category.name,
        'status': status.name,
        'launchDate': launchDate?.toIso8601String(),
        'relatedActIds': relatedActIds,
        'relatedCommitteeIds': relatedCommitteeIds,
        'relatedReportIds': relatedReportIds,
        'relatedSchemeIds': relatedSchemeIds,
        'relatedPyqIds': relatedPyqIds,
        'relatedCurrentAffairsIds': relatedCurrentAffairsIds,
        'sdgGoals': sdgGoals.map((g) => g.name).toList(),
        'fundingPattern': funding.fundingPattern.name,
        'officialSource': officialSource,
        'lastVerifiedDate': lastVerifiedDate,
      },
    );
  }

  SchemeKnowledgeObject copyWith({
    String? id,
    String? officialName,
    String? shortName,
    SchemeType? schemeType,
    SchemeCategory? category,
    SchemeSector? sector,
    SchemeMinistry? ministry,
    String? department,
    SchemeStatus? status,
    DateTime? launchDate,
    String? implementingAgency,
    List<BeneficiaryGroup>? beneficiaries,
    List<String>? targetBeneficiaries,
    List<String>? eligibility,
    List<String>? objectives,
    List<String>? keyFeatures,
    List<SchemeBenefit>? benefits,
    List<SchemeComponent>? components,
    SchemeFundingDetail? funding,
    String? coverage,
    List<String>? geographicScope,
    RuralUrbanScope? ruralUrbanScope,
    List<String>? relatedArticleIds,
    List<String>? relatedActIds,
    List<String>? relatedCaseLawIds,
    List<String>? relatedDoctrineIds,
    List<String>? relatedCommitteeIds,
    List<String>? relatedReportIds,
    List<String>? relatedCurrentAffairsIds,
    List<String>? relatedPyqIds,
    List<String>? relatedSchemeIds,
    List<String>? predecessorSchemeIds,
    List<String>? successorSchemeIds,
    String? subsumedBySchemeId,
    List<SdgGoal>? sdgGoals,
    List<SchemeRelationship>? relationships,
    List<SchemeTimeline>? timeline,
    String? officialSource,
    List<String>? evidenceIds,
    String? lastVerifiedDate,
    String? upscRelevance,
    List<String>? keywords,
    int? version,
    EditorialStatus? editorialStatus,
    Map<String, dynamic>? metadata,
  }) {
    return SchemeKnowledgeObject(
      id: id ?? this.id,
      officialName: officialName ?? this.officialName,
      shortName: shortName ?? this.shortName,
      schemeType: schemeType ?? this.schemeType,
      category: category ?? this.category,
      sector: sector ?? this.sector,
      ministry: ministry ?? this.ministry,
      department: department ?? this.department,
      status: status ?? this.status,
      launchDate: launchDate ?? this.launchDate,
      implementingAgency: implementingAgency ?? this.implementingAgency,
      beneficiaries: beneficiaries ?? List.from(this.beneficiaries),
      targetBeneficiaries:
          targetBeneficiaries ?? List.from(this.targetBeneficiaries),
      eligibility: eligibility ?? List.from(this.eligibility),
      objectives: objectives ?? List.from(this.objectives),
      keyFeatures: keyFeatures ?? List.from(this.keyFeatures),
      benefits: benefits ?? List.from(this.benefits),
      components: components ?? List.from(this.components),
      funding: funding ?? this.funding,
      coverage: coverage ?? this.coverage,
      geographicScope: geographicScope ?? List.from(this.geographicScope),
      ruralUrbanScope: ruralUrbanScope ?? this.ruralUrbanScope,
      relatedArticleIds: relatedArticleIds ?? List.from(this.relatedArticleIds),
      relatedActIds: relatedActIds ?? List.from(this.relatedActIds),
      relatedCaseLawIds: relatedCaseLawIds ?? List.from(this.relatedCaseLawIds),
      relatedDoctrineIds: relatedDoctrineIds ?? List.from(this.relatedDoctrineIds),
      relatedCommitteeIds:
          relatedCommitteeIds ?? List.from(this.relatedCommitteeIds),
      relatedReportIds: relatedReportIds ?? List.from(this.relatedReportIds),
      relatedCurrentAffairsIds:
          relatedCurrentAffairsIds ?? List.from(this.relatedCurrentAffairsIds),
      relatedPyqIds: relatedPyqIds ?? List.from(this.relatedPyqIds),
      relatedSchemeIds: relatedSchemeIds ?? List.from(this.relatedSchemeIds),
      predecessorSchemeIds:
          predecessorSchemeIds ?? List.from(this.predecessorSchemeIds),
      successorSchemeIds: successorSchemeIds ?? List.from(this.successorSchemeIds),
      subsumedBySchemeId: subsumedBySchemeId ?? this.subsumedBySchemeId,
      sdgGoals: sdgGoals ?? List.from(this.sdgGoals),
      relationships: relationships ?? List.from(this.relationships),
      timeline: timeline ?? List.from(this.timeline),
      officialSource: officialSource ?? this.officialSource,
      evidenceIds: evidenceIds ?? List.from(this.evidenceIds),
      lastVerifiedDate: lastVerifiedDate ?? this.lastVerifiedDate,
      upscRelevance: upscRelevance ?? this.upscRelevance,
      keywords: keywords ?? List.from(this.keywords),
      version: version ?? this.version,
      editorialStatus: editorialStatus ?? this.editorialStatus,
      metadata: metadata ?? Map.from(this.metadata),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'officialName': officialName,
        'shortName': shortName,
        'schemeType': schemeType.name,
        'category': category.name,
        'sector': sector.name,
        'ministry': ministry.name,
        'department': department,
        'status': status.name,
        'launchDate': launchDate?.toIso8601String(),
        'implementingAgency': implementingAgency,
        'beneficiaries': beneficiaries.map((b) => b.name).toList(),
        'targetBeneficiaries': targetBeneficiaries,
        'eligibility': eligibility,
        'objectives': objectives,
        'keyFeatures': keyFeatures,
        'benefits': benefits.map((b) => b.toJson()).toList(),
        'components': components.map((c) => c.toJson()).toList(),
        'funding': funding.toJson(),
        'coverage': coverage,
        'geographicScope': geographicScope,
        'ruralUrbanScope': ruralUrbanScope.name,
        'relatedArticleIds': relatedArticleIds,
        'relatedActIds': relatedActIds,
        'relatedCaseLawIds': relatedCaseLawIds,
        'relatedDoctrineIds': relatedDoctrineIds,
        'relatedCommitteeIds': relatedCommitteeIds,
        'relatedReportIds': relatedReportIds,
        'relatedCurrentAffairsIds': relatedCurrentAffairsIds,
        'relatedPyqIds': relatedPyqIds,
        'relatedSchemeIds': relatedSchemeIds,
        'predecessorSchemeIds': predecessorSchemeIds,
        'successorSchemeIds': successorSchemeIds,
        'subsumedBySchemeId': subsumedBySchemeId,
        'sdgGoals': sdgGoals.map((g) => g.name).toList(),
        'relationships': relationships.map((r) => r.toJson()).toList(),
        'timeline': timeline.map((t) => t.toJson()).toList(),
        'officialSource': officialSource,
        'evidenceIds': evidenceIds,
        'lastVerifiedDate': lastVerifiedDate,
        'upscRelevance': upscRelevance,
        'keywords': keywords,
        'version': version,
        'editorialStatus': editorialStatus.name,
        'metadata': metadata,
      };

  factory SchemeKnowledgeObject.fromJson(Map<String, dynamic> json) =>
      SchemeKnowledgeObject(
        id: json['id'] as String? ?? '',
        officialName: json['officialName'] as String? ?? '',
        shortName: json['shortName'] as String? ?? '',
        schemeType: SchemeType.values.firstWhere(
          (t) => t.name == json['schemeType'],
          orElse: () => SchemeType.centralSector,
        ),
        category: SchemeCategory.values.firstWhere(
          (c) => c.name == json['category'],
          orElse: () => SchemeCategory.agriculture,
        ),
        sector: SchemeSector.values.firstWhere(
          (s) => s.name == json['sector'],
          orElse: () => SchemeSector.agriculture,
        ),
        ministry: SchemeMinistry.values.firstWhere(
          (m) => m.name == json['ministry'],
          orElse: () => SchemeMinistry.agricultureFarmersWelfare,
        ),
        department: json['department'] as String? ?? '',
        status: SchemeStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => SchemeStatus.operational,
        ),
        launchDate: DateTime.tryParse(json['launchDate'] as String? ?? ''),
        implementingAgency: json['implementingAgency'] as String? ?? '',
        beneficiaries: (json['beneficiaries'] as List?)
                ?.map((e) => BeneficiaryGroup.values.firstWhere(
                      (b) => b.name == e,
                      orElse: () => BeneficiaryGroup.allCitizens,
                    ))
                .toList() ??
            const [],
        targetBeneficiaries: (json['targetBeneficiaries'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        eligibility: (json['eligibility'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        objectives: (json['objectives'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        keyFeatures: (json['keyFeatures'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        benefits: (json['benefits'] as List?)
                ?.map((b) =>
                    SchemeBenefit.fromJson(Map<String, dynamic>.from(b as Map)))
                .toList() ??
            const [],
        components: (json['components'] as List?)
                ?.map((c) => SchemeComponent.fromJson(
                    Map<String, dynamic>.from(c as Map)))
                .toList() ??
            const [],
        funding: SchemeFundingDetail.fromJson(
            Map<String, dynamic>.from(json['funding'] as Map? ?? {})),
        coverage: json['coverage'] as String? ?? '',
        geographicScope: (json['geographicScope'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        ruralUrbanScope: RuralUrbanScope.values.firstWhere(
          (r) => r.name == json['ruralUrbanScope'],
          orElse: () => RuralUrbanScope.both,
        ),
        relatedArticleIds: (json['relatedArticleIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        relatedActIds: (json['relatedActIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        relatedCaseLawIds: (json['relatedCaseLawIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        relatedDoctrineIds: (json['relatedDoctrineIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        relatedCommitteeIds: (json['relatedCommitteeIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        relatedReportIds: (json['relatedReportIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        relatedCurrentAffairsIds: (json['relatedCurrentAffairsIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        relatedPyqIds: (json['relatedPyqIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        relatedSchemeIds: (json['relatedSchemeIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        predecessorSchemeIds: (json['predecessorSchemeIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        successorSchemeIds: (json['successorSchemeIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        subsumedBySchemeId: json['subsumedBySchemeId'] as String?,
        sdgGoals: (json['sdgGoals'] as List?)
                ?.map((e) => SdgGoal.values.firstWhere(
                      (g) => g.name == e,
                      orElse: () => SdgGoal.noPoverty,
                    ))
                .toList() ??
            const [],
        relationships: (json['relationships'] as List?)
                ?.map((r) => SchemeRelationship.fromJson(
                    Map<String, dynamic>.from(r as Map)))
                .toList() ??
            const [],
        timeline: (json['timeline'] as List?)
                ?.map((t) => SchemeTimeline.fromJson(
                    Map<String, dynamic>.from(t as Map)))
                .toList() ??
            const [],
        officialSource: json['officialSource'] as String? ?? '',
        evidenceIds: (json['evidenceIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        lastVerifiedDate: json['lastVerifiedDate'] as String? ?? '',
        upscRelevance: json['upscRelevance'] as String? ?? '',
        keywords: (json['keywords'] as List?)
                ?.map((e) => e.toString())
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
