library;

import 'package:garuda_editor/garuda_editor.dart';
import 'package:meta/meta.dart';
import 'body_enums.dart';
import 'body_relationship.dart';

/// Permanent, interconnected Government Body Knowledge Object in the GARUDA
/// Commissions & Statutory Bodies Library. Every body (Constitutional, Statutory,
/// Regulatory, National Commission, Authority, Board or Tribunal) is modelled as
/// an independent, searchable, evidence-backed Knowledge Object linked to the
/// Constitution, Acts, Cases, Doctrines, Committees, Reports, Schemes, Current
/// Affairs, PYQs, SDGs and related Bodies.
@immutable
class BodyKnowledgeObject {
  final String id;
  final String officialName;
  final String shortName;
  final BodyType bodyType;
  final BodyCategory category;
  final ConstitutionalBasis constitutionalBasis;
  final StatutoryBasis statutoryBasis;
  final BodyStatus bodyStatus;
  final BodyIndependence bodyIndependence;
  final List<String> establishingArticleIds;
  final List<String> establishingActIds;
  final int yearEstablished;
  final String parentMinistry;
  final String headquarters;
  final BodyJurisdiction jurisdiction;
  final String mandate;
  final List<String> powers;
  final List<String> functions;
  final String composition;
  final String appointmentMechanism;
  final AppointmentAuthority appointmentAuthority;
  final String tenure;
  final TenureType tenureType;
  final String removalMechanism;
  final List<String> eligibilityQualifications;
  final ReportingAuthority reportingAuthority;
  final String financialStructure;
  final List<String> importantProvisions;
  final UpscRelevanceLevel upscRelevance;
  final RelevanceLevel prelimsRelevance;
  final RelevanceLevel mainsRelevance;
  final RelevanceLevel interviewRelevance;
  final List<String> relatedArticleIds;
  final List<String> relatedActIds;
  final List<String> relatedCaseLawIds;
  final List<String> relatedDoctrineIds;
  final List<String> relatedCommitteeIds;
  final List<String> relatedReportIds;
  final List<String> relatedSchemeIds;
  final List<String> relatedCurrentAffairsIds;
  final List<String> relatedPyqIds;
  final List<String> relatedBodyIds;
  final List<String> sdgGoals;
  final List<BodyRelationship> relationships;
  final String officialSource;
  final List<String> evidenceIds;
  final String lastVerifiedDate;
  final List<String> keywords;
  final int version;
  final EditorialStatus editorialStatus;
  final Map<String, dynamic> metadata;

  BodyKnowledgeObject({
    required this.id,
    required this.officialName,
    required this.shortName,
    this.bodyType = BodyType.statutory,
    this.category = BodyCategory.commission,
    this.constitutionalBasis = ConstitutionalBasis.none,
    this.statutoryBasis = StatutoryBasis.parliamentaryAct,
    this.bodyStatus = BodyStatus.active,
    this.bodyIndependence = BodyIndependence.statutorilyAutonomous,
    this.establishingArticleIds = const [],
    this.establishingActIds = const [],
    this.yearEstablished = 0,
    this.parentMinistry = '',
    this.headquarters = '',
    this.jurisdiction = BodyJurisdiction.national,
    this.mandate = '',
    this.powers = const [],
    this.functions = const [],
    this.composition = '',
    this.appointmentMechanism = '',
    this.appointmentAuthority = AppointmentAuthority.president,
    this.tenure = '',
    this.tenureType = TenureType.notApplicable,
    this.removalMechanism = '',
    this.eligibilityQualifications = const [],
    this.reportingAuthority = ReportingAuthority.notApplicable,
    this.financialStructure = '',
    this.importantProvisions = const [],
    this.upscRelevance = UpscRelevanceLevel.high,
    this.prelimsRelevance = RelevanceLevel.high,
    this.mainsRelevance = RelevanceLevel.high,
    this.interviewRelevance = RelevanceLevel.medium,
    this.relatedArticleIds = const [],
    this.relatedActIds = const [],
    this.relatedCaseLawIds = const [],
    this.relatedDoctrineIds = const [],
    this.relatedCommitteeIds = const [],
    this.relatedReportIds = const [],
    this.relatedSchemeIds = const [],
    this.relatedCurrentAffairsIds = const [],
    this.relatedPyqIds = const [],
    this.relatedBodyIds = const [],
    this.sdgGoals = const [],
    this.relationships = const [],
    this.officialSource = '',
    this.evidenceIds = const [],
    this.lastVerifiedDate = '',
    this.keywords = const [],
    this.version = 1,
    this.editorialStatus = EditorialStatus.imported,
    Map<String, dynamic>? metadata,
  }) : metadata = Map<String, dynamic>.from(metadata ?? const {});

  /// Bridge helper converting to the base GARUDA KnowledgeObject for the
  /// Editorial Production Engine (shared GARUDA knowledge registry/index).
  KnowledgeObject toGarudaKnowledgeObject() {
    return KnowledgeObject(
      id: id,
      title: officialName,
      subject: '${bodyType.displayName} — ${category.displayName}',
      topic: shortName.isNotEmpty ? shortName : officialName,
      subtopic: parentMinistry.isNotEmpty ? parentMinistry : headquarters,
      summary: mandate.isNotEmpty ? mandate : officialName,
      content:
          'Body: $officialName ($shortName). Type: ${bodyType.displayName}. Category: ${category.displayName}. Established: $yearEstablished. Mandate: $mandate. Powers: ${powers.join("; ")}. Functions: ${functions.join("; ")}. Composition: $composition. Appointment: $appointmentMechanism. Tenure: $tenure.',
      officialSource: officialSource,
      evidenceIds: evidenceIds,
      status: editorialStatus,
      version: version,
      package: 'garuda_bodies',
      knowledgeType: 'BodyKnowledgeObject',
      relatedArticles: relatedArticleIds,
      relatedCaseLaws: relatedCaseLawIds,
      tags: keywords,
      isVerified: evidenceIds.isNotEmpty &&
          editorialStatus == EditorialStatus.published,
      metadata: {
        ...metadata,
        'bodyType': bodyType.name,
        'category': category.name,
        'constitutionalBasis': constitutionalBasis.name,
        'statutoryBasis': statutoryBasis.name,
        'yearEstablished': yearEstablished,
        'parentMinistry': parentMinistry,
        'relatedActIds': relatedActIds,
        'relatedCommitteeIds': relatedCommitteeIds,
        'relatedReportIds': relatedReportIds,
        'relatedSchemeIds': relatedSchemeIds,
        'relatedBodyIds': relatedBodyIds,
        'relatedPyqIds': relatedPyqIds,
        'relatedCurrentAffairsIds': relatedCurrentAffairsIds,
        'officialSource': officialSource,
        'lastVerifiedDate': lastVerifiedDate,
      },
    );
  }

  BodyKnowledgeObject copyWith({
    String? id,
    String? officialName,
    String? shortName,
    BodyType? bodyType,
    BodyCategory? category,
    ConstitutionalBasis? constitutionalBasis,
    StatutoryBasis? statutoryBasis,
    BodyStatus? bodyStatus,
    BodyIndependence? bodyIndependence,
    List<String>? establishingArticleIds,
    List<String>? establishingActIds,
    int? yearEstablished,
    String? parentMinistry,
    String? headquarters,
    BodyJurisdiction? jurisdiction,
    String? mandate,
    List<String>? powers,
    List<String>? functions,
    String? composition,
    String? appointmentMechanism,
    AppointmentAuthority? appointmentAuthority,
    String? tenure,
    TenureType? tenureType,
    String? removalMechanism,
    List<String>? eligibilityQualifications,
    ReportingAuthority? reportingAuthority,
    String? financialStructure,
    List<String>? importantProvisions,
    UpscRelevanceLevel? upscRelevance,
    RelevanceLevel? prelimsRelevance,
    RelevanceLevel? mainsRelevance,
    RelevanceLevel? interviewRelevance,
    List<String>? relatedArticleIds,
    List<String>? relatedActIds,
    List<String>? relatedCaseLawIds,
    List<String>? relatedDoctrineIds,
    List<String>? relatedCommitteeIds,
    List<String>? relatedReportIds,
    List<String>? relatedSchemeIds,
    List<String>? relatedCurrentAffairsIds,
    List<String>? relatedPyqIds,
    List<String>? relatedBodyIds,
    List<String>? sdgGoals,
    List<BodyRelationship>? relationships,
    String? officialSource,
    List<String>? evidenceIds,
    String? lastVerifiedDate,
    List<String>? keywords,
    int? version,
    EditorialStatus? editorialStatus,
    Map<String, dynamic>? metadata,
  }) {
    return BodyKnowledgeObject(
      id: id ?? this.id,
      officialName: officialName ?? this.officialName,
      shortName: shortName ?? this.shortName,
      bodyType: bodyType ?? this.bodyType,
      category: category ?? this.category,
      constitutionalBasis: constitutionalBasis ?? this.constitutionalBasis,
      statutoryBasis: statutoryBasis ?? this.statutoryBasis,
      bodyStatus: bodyStatus ?? this.bodyStatus,
      bodyIndependence: bodyIndependence ?? this.bodyIndependence,
      establishingArticleIds:
          establishingArticleIds ?? List.from(this.establishingArticleIds),
      establishingActIds:
          establishingActIds ?? List.from(this.establishingActIds),
      yearEstablished: yearEstablished ?? this.yearEstablished,
      parentMinistry: parentMinistry ?? this.parentMinistry,
      headquarters: headquarters ?? this.headquarters,
      jurisdiction: jurisdiction ?? this.jurisdiction,
      mandate: mandate ?? this.mandate,
      powers: powers ?? List.from(this.powers),
      functions: functions ?? List.from(this.functions),
      composition: composition ?? this.composition,
      appointmentMechanism: appointmentMechanism ?? this.appointmentMechanism,
      appointmentAuthority: appointmentAuthority ?? this.appointmentAuthority,
      tenure: tenure ?? this.tenure,
      tenureType: tenureType ?? this.tenureType,
      removalMechanism: removalMechanism ?? this.removalMechanism,
      eligibilityQualifications:
          eligibilityQualifications ?? List.from(this.eligibilityQualifications),
      reportingAuthority: reportingAuthority ?? this.reportingAuthority,
      financialStructure: financialStructure ?? this.financialStructure,
      importantProvisions:
          importantProvisions ?? List.from(this.importantProvisions),
      upscRelevance: upscRelevance ?? this.upscRelevance,
      prelimsRelevance: prelimsRelevance ?? this.prelimsRelevance,
      mainsRelevance: mainsRelevance ?? this.mainsRelevance,
      interviewRelevance: interviewRelevance ?? this.interviewRelevance,
      relatedArticleIds: relatedArticleIds ?? List.from(this.relatedArticleIds),
      relatedActIds: relatedActIds ?? List.from(this.relatedActIds),
      relatedCaseLawIds: relatedCaseLawIds ?? List.from(this.relatedCaseLawIds),
      relatedDoctrineIds:
          relatedDoctrineIds ?? List.from(this.relatedDoctrineIds),
      relatedCommitteeIds:
          relatedCommitteeIds ?? List.from(this.relatedCommitteeIds),
      relatedReportIds: relatedReportIds ?? List.from(this.relatedReportIds),
      relatedSchemeIds: relatedSchemeIds ?? List.from(this.relatedSchemeIds),
      relatedCurrentAffairsIds:
          relatedCurrentAffairsIds ?? List.from(this.relatedCurrentAffairsIds),
      relatedPyqIds: relatedPyqIds ?? List.from(this.relatedPyqIds),
      relatedBodyIds: relatedBodyIds ?? List.from(this.relatedBodyIds),
      sdgGoals: sdgGoals ?? List.from(this.sdgGoals),
      relationships: relationships ?? List.from(this.relationships),
      officialSource: officialSource ?? this.officialSource,
      evidenceIds: evidenceIds ?? List.from(this.evidenceIds),
      lastVerifiedDate: lastVerifiedDate ?? this.lastVerifiedDate,
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
        'bodyType': bodyType.name,
        'category': category.name,
        'constitutionalBasis': constitutionalBasis.name,
        'statutoryBasis': statutoryBasis.name,
        'bodyStatus': bodyStatus.name,
        'bodyIndependence': bodyIndependence.name,
        'establishingArticleIds': establishingArticleIds,
        'establishingActIds': establishingActIds,
        'yearEstablished': yearEstablished,
        'parentMinistry': parentMinistry,
        'headquarters': headquarters,
        'jurisdiction': jurisdiction.name,
        'mandate': mandate,
        'powers': powers,
        'functions': functions,
        'composition': composition,
        'appointmentMechanism': appointmentMechanism,
        'appointmentAuthority': appointmentAuthority.name,
        'tenure': tenure,
        'tenureType': tenureType.name,
        'removalMechanism': removalMechanism,
        'eligibilityQualifications': eligibilityQualifications,
        'reportingAuthority': reportingAuthority.name,
        'financialStructure': financialStructure,
        'importantProvisions': importantProvisions,
        'upscRelevance': upscRelevance.name,
        'prelimsRelevance': prelimsRelevance.name,
        'mainsRelevance': mainsRelevance.name,
        'interviewRelevance': interviewRelevance.name,
        'relatedArticleIds': relatedArticleIds,
        'relatedActIds': relatedActIds,
        'relatedCaseLawIds': relatedCaseLawIds,
        'relatedDoctrineIds': relatedDoctrineIds,
        'relatedCommitteeIds': relatedCommitteeIds,
        'relatedReportIds': relatedReportIds,
        'relatedSchemeIds': relatedSchemeIds,
        'relatedCurrentAffairsIds': relatedCurrentAffairsIds,
        'relatedPyqIds': relatedPyqIds,
        'relatedBodyIds': relatedBodyIds,
        'sdgGoals': sdgGoals,
        'relationships': relationships.map((r) => r.toJson()).toList(),
        'officialSource': officialSource,
        'evidenceIds': evidenceIds,
        'lastVerifiedDate': lastVerifiedDate,
        'keywords': keywords,
        'version': version,
        'editorialStatus': editorialStatus.name,
        'metadata': metadata,
      };

  factory BodyKnowledgeObject.fromJson(Map<String, dynamic> json) =>
      BodyKnowledgeObject(
        id: json['id'] as String? ?? '',
        officialName: json['officialName'] as String? ?? '',
        shortName: json['shortName'] as String? ?? '',
        bodyType: BodyType.values.firstWhere(
          (t) => t.name == json['bodyType'],
          orElse: () => BodyType.statutory,
        ),
        category: BodyCategory.values.firstWhere(
          (c) => c.name == json['category'],
          orElse: () => BodyCategory.commission,
        ),
        constitutionalBasis: ConstitutionalBasis.values.firstWhere(
          (c) => c.name == json['constitutionalBasis'],
          orElse: () => ConstitutionalBasis.none,
        ),
        statutoryBasis: StatutoryBasis.values.firstWhere(
          (s) => s.name == json['statutoryBasis'],
          orElse: () => StatutoryBasis.parliamentaryAct,
        ),
        bodyStatus: BodyStatus.values.firstWhere(
          (s) => s.name == json['bodyStatus'],
          orElse: () => BodyStatus.active,
        ),
        bodyIndependence: BodyIndependence.values.firstWhere(
          (b) => b.name == json['bodyIndependence'],
          orElse: () => BodyIndependence.statutorilyAutonomous,
        ),
        establishingArticleIds: (json['establishingArticleIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        establishingActIds: (json['establishingActIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        yearEstablished: (json['yearEstablished'] as num?)?.toInt() ?? 0,
        parentMinistry: json['parentMinistry'] as String? ?? '',
        headquarters: json['headquarters'] as String? ?? '',
        jurisdiction: BodyJurisdiction.values.firstWhere(
          (j) => j.name == json['jurisdiction'],
          orElse: () => BodyJurisdiction.national,
        ),
        mandate: json['mandate'] as String? ?? '',
        powers: (json['powers'] as List?)?.map((e) => e.toString()).toList() ??
            const [],
        functions:
            (json['functions'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        composition: json['composition'] as String? ?? '',
        appointmentMechanism: json['appointmentMechanism'] as String? ?? '',
        appointmentAuthority: AppointmentAuthority.values.firstWhere(
          (a) => a.name == json['appointmentAuthority'],
          orElse: () => AppointmentAuthority.president,
        ),
        tenure: json['tenure'] as String? ?? '',
        tenureType: TenureType.values.firstWhere(
          (t) => t.name == json['tenureType'],
          orElse: () => TenureType.notApplicable,
        ),
        removalMechanism: json['removalMechanism'] as String? ?? '',
        eligibilityQualifications: (json['eligibilityQualifications'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        reportingAuthority: ReportingAuthority.values.firstWhere(
          (r) => r.name == json['reportingAuthority'],
          orElse: () => ReportingAuthority.notApplicable,
        ),
        financialStructure: json['financialStructure'] as String? ?? '',
        importantProvisions: (json['importantProvisions'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        upscRelevance: UpscRelevanceLevel.values.firstWhere(
          (u) => u.name == json['upscRelevance'],
          orElse: () => UpscRelevanceLevel.high,
        ),
        prelimsRelevance: RelevanceLevel.values.firstWhere(
          (r) => r.name == json['prelimsRelevance'],
          orElse: () => RelevanceLevel.high,
        ),
        mainsRelevance: RelevanceLevel.values.firstWhere(
          (r) => r.name == json['mainsRelevance'],
          orElse: () => RelevanceLevel.high,
        ),
        interviewRelevance: RelevanceLevel.values.firstWhere(
          (r) => r.name == json['interviewRelevance'],
          orElse: () => RelevanceLevel.medium,
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
        relatedSchemeIds: (json['relatedSchemeIds'] as List?)
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
        relatedBodyIds: (json['relatedBodyIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        sdgGoals:
            (json['sdgGoals'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        relationships: (json['relationships'] as List?)
                ?.map((r) => BodyRelationship.fromJson(
                    Map<String, dynamic>.from(r as Map)))
                .toList() ??
            const [],
        officialSource: json['officialSource'] as String? ?? '',
        evidenceIds: (json['evidenceIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        lastVerifiedDate: json['lastVerifiedDate'] as String? ?? '',
        keywords:
            (json['keywords'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        version: (json['version'] as num?)?.toInt() ?? 1,
        editorialStatus: EditorialStatus.values.firstWhere(
          (s) => s.name == json['editorialStatus'],
          orElse: () => EditorialStatus.imported,
        ),
        metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      );
}
