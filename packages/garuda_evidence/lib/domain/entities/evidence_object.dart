import 'package:meta/meta.dart';
import '../../orchestration/lifecycle/evidence_lifecycle.dart';
import '../../orchestration/lineage/evidence_lineage.dart';
import '../../orchestration/versioning/evidence_version.dart';
import 'enums.dart';
import 'evidence_attachment.dart';
import 'evidence_authority.dart';
import 'evidence_relationship.dart';
import 'knowledge_object_links.dart';

/// Production-ready EvidenceObject for Project TITAN GARUDA Evidence Engine.
/// Primary immutable container for all ingested official data and current affairs.
@immutable
class EvidenceObject {
  final String id;
  final String title;
  final String sourceName;
  final EvidenceSourceType sourceType;
  final EvidenceAuthority authority;
  final DateTime publicationDate;
  final DateTime retrievedDate;
  final String category;
  final String subject;
  final String topic;
  final String subtopic;
  final List<String> keywords;
  final String language;
  final String summary;
  final String originalUrl;
  final String? pdfUrl;
  final List<EvidenceAttachment> attachments;
  final double confidenceScore;
  final VerificationStatus verificationStatus;
  final EditorialStatus editorialStatus;
  final KnowledgeObjectLinks knowledgeObjectLinks;
  final List<EvidenceRelationship> relatedEvidence;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Orchestration metadata additions (TITAN-GCA-002)
  final EvidenceLifecycle? lifecycle;
  final List<EvidenceVersion> versionHistory;
  final EvidenceLineage? lineage;

  const EvidenceObject({
    required this.id,
    required this.title,
    required this.sourceName,
    required this.sourceType,
    required this.authority,
    required this.publicationDate,
    required this.retrievedDate,
    required this.category,
    required this.subject,
    required this.topic,
    required this.subtopic,
    required this.keywords,
    required this.language,
    required this.summary,
    required this.originalUrl,
    this.pdfUrl,
    this.attachments = const [],
    this.confidenceScore = 1.0,
    this.verificationStatus = VerificationStatus.pending,
    this.editorialStatus = EditorialStatus.draft,
    this.knowledgeObjectLinks = const KnowledgeObjectLinks(),
    this.relatedEvidence = const [],
    this.version = 1,
    required this.createdAt,
    required this.updatedAt,
    this.lifecycle,
    this.versionHistory = const [],
    this.lineage,
  });

  EvidenceLifecycle get activeLifecycle =>
      lifecycle ?? EvidenceLifecycle(updatedAt: createdAt);

  EvidenceLineage get activeLineage =>
      lineage ??
      EvidenceLineage(
        originalSource: sourceName,
        originalUrl: originalUrl,
        originalPdf: pdfUrl,
      );

  EvidenceObject copyWith({
    String? id,
    String? title,
    String? sourceName,
    EvidenceSourceType? sourceType,
    EvidenceAuthority? authority,
    DateTime? publicationDate,
    DateTime? retrievedDate,
    String? category,
    String? subject,
    String? topic,
    String? subtopic,
    List<String>? keywords,
    String? language,
    String? summary,
    String? originalUrl,
    String? pdfUrl,
    List<EvidenceAttachment>? attachments,
    double? confidenceScore,
    VerificationStatus? verificationStatus,
    EditorialStatus? editorialStatus,
    KnowledgeObjectLinks? knowledgeObjectLinks,
    List<EvidenceRelationship>? relatedEvidence,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
    EvidenceLifecycle? lifecycle,
    List<EvidenceVersion>? versionHistory,
    EvidenceLineage? lineage,
  }) {
    return EvidenceObject(
      id: id ?? this.id,
      title: title ?? this.title,
      sourceName: sourceName ?? this.sourceName,
      sourceType: sourceType ?? this.sourceType,
      authority: authority ?? this.authority,
      publicationDate: publicationDate ?? this.publicationDate,
      retrievedDate: retrievedDate ?? this.retrievedDate,
      category: category ?? this.category,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      subtopic: subtopic ?? this.subtopic,
      keywords: keywords ?? List.from(this.keywords),
      language: language ?? this.language,
      summary: summary ?? this.summary,
      originalUrl: originalUrl ?? this.originalUrl,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      attachments: attachments ?? List.from(this.attachments),
      confidenceScore: confidenceScore ?? this.confidenceScore,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      editorialStatus: editorialStatus ?? this.editorialStatus,
      knowledgeObjectLinks: knowledgeObjectLinks ?? this.knowledgeObjectLinks,
      relatedEvidence: relatedEvidence ?? List.from(this.relatedEvidence),
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lifecycle: lifecycle ?? this.lifecycle,
      versionHistory: versionHistory ?? List.from(this.versionHistory),
      lineage: lineage ?? this.lineage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'sourceName': sourceName,
      'sourceType': sourceType.name,
      'authority': authority.toJson(),
      'publicationDate': publicationDate.toIso8601String(),
      'retrievedDate': retrievedDate.toIso8601String(),
      'category': category,
      'subject': subject,
      'topic': topic,
      'subtopic': subtopic,
      'keywords': keywords,
      'language': language,
      'summary': summary,
      'originalUrl': originalUrl,
      'pdfUrl': pdfUrl,
      'attachments': attachments.map((a) => a.toJson()).toList(),
      'confidenceScore': confidenceScore,
      'verificationStatus': verificationStatus.name,
      'editorialStatus': editorialStatus.name,
      'knowledgeObjectLinks': knowledgeObjectLinks.toJson(),
      'relatedEvidence': relatedEvidence.map((r) => r.toJson()).toList(),
      'version': version,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lifecycle': activeLifecycle.toJson(),
      'versionHistory': versionHistory.map((v) => v.toJson()).toList(),
      'lineage': activeLineage.toJson(),
    };
  }

  factory EvidenceObject.fromJson(Map<String, dynamic> json) {
    final created =
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now();

    return EvidenceObject(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      sourceName: json['sourceName'] as String? ?? '',
      sourceType: EvidenceSourceType.values.firstWhere(
        (e) => e.name == json['sourceType'],
        orElse: () => EvidenceSourceType.other,
      ),
      authority: json['authority'] != null
          ? EvidenceAuthority.fromJson(
              Map<String, dynamic>.from(json['authority'] as Map))
          : const EvidenceAuthority(
              id: 'unknown',
              name: 'Unknown Authority',
              type: EvidenceSourceType.other,
              jurisdiction: 'India',
            ),
      publicationDate:
          DateTime.tryParse(json['publicationDate'] as String? ?? '') ??
              DateTime.now(),
      retrievedDate:
          DateTime.tryParse(json['retrievedDate'] as String? ?? '') ??
              DateTime.now(),
      category: json['category'] as String? ?? 'General',
      subject: json['subject'] as String? ?? 'General',
      topic: json['topic'] as String? ?? 'General',
      subtopic: json['subtopic'] as String? ?? 'General',
      keywords:
          (json['keywords'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      language: json['language'] as String? ?? 'en',
      summary: json['summary'] as String? ?? '',
      originalUrl: json['originalUrl'] as String? ?? '',
      pdfUrl: json['pdfUrl'] as String?,
      attachments: (json['attachments'] as List?)
              ?.map((e) => EvidenceAttachment.fromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 1.0,
      verificationStatus: VerificationStatus.values.firstWhere(
        (e) => e.name == json['verificationStatus'],
        orElse: () => VerificationStatus.pending,
      ),
      editorialStatus: EditorialStatus.values.firstWhere(
        (e) => e.name == json['editorialStatus'],
        orElse: () => EditorialStatus.draft,
      ),
      knowledgeObjectLinks: json['knowledgeObjectLinks'] != null
          ? KnowledgeObjectLinks.fromJson(
              Map<String, dynamic>.from(json['knowledgeObjectLinks'] as Map))
          : const KnowledgeObjectLinks(),
      relatedEvidence: (json['relatedEvidence'] as List?)
              ?.map((e) => EvidenceRelationship.fromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      version: (json['version'] as num?)?.toInt() ?? 1,
      createdAt: created,
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? created,
      lifecycle: json['lifecycle'] != null
          ? EvidenceLifecycle.fromJson(
              Map<String, dynamic>.from(json['lifecycle'] as Map))
          : null,
      versionHistory: (json['versionHistory'] as List?)
              ?.map((e) => EvidenceVersion.fromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      lineage: json['lineage'] != null
          ? EvidenceLineage.fromJson(
              Map<String, dynamic>.from(json['lineage'] as Map))
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EvidenceObject &&
        other.id == id &&
        other.title == title &&
        other.sourceName == sourceName &&
        other.sourceType == sourceType &&
        other.version == version;
  }

  @override
  int get hashCode => Object.hash(id, title, sourceName, sourceType, version);

  @override
  String toString() =>
      'EvidenceObject(id: $id, title: $title, source: $sourceName, status: ${verificationStatus.name})';
}
