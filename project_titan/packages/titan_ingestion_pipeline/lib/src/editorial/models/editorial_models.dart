import 'package:meta/meta.dart';
import '../../intelligence/models/generated_learning_assets.dart';
import '../../models/glossary_item.dart';

/// Editorial status lifecycle transitions for AI-generated assets.
enum EditorialStatus {
  draft,
  aiGenerated,
  needsReview,
  editorReview,
  reviewerApproval,
  published,
  unpublished,
  archived;

  String get label {
    switch (this) {
      case EditorialStatus.draft:
        return 'Draft';
      case EditorialStatus.aiGenerated:
        return 'AI Generated';
      case EditorialStatus.needsReview:
        return 'Needs Review';
      case EditorialStatus.editorReview:
        return 'Editor Review';
      case EditorialStatus.reviewerApproval:
        return 'Senior Approval';
      case EditorialStatus.published:
        return 'Published';
      case EditorialStatus.unpublished:
        return 'Unpublished';
      case EditorialStatus.archived:
        return 'Archived';
    }
  }
}

/// User roles in the editorial approval pipeline.
enum EditorialRole {
  author,
  aiGenerator,
  editor,
  seniorReviewer,
  publisher,
  administrator;

  bool get canReview =>
      this == EditorialRole.editor ||
      this == EditorialRole.seniorReviewer ||
      this == EditorialRole.administrator;

  bool get canPublish =>
      this == EditorialRole.seniorReviewer ||
      this == EditorialRole.publisher ||
      this == EditorialRole.administrator;

  bool get canApprove =>
      this == EditorialRole.seniorReviewer ||
      this == EditorialRole.administrator;
}

/// Provenance tracking for full origin-to-publication lineage.
@immutable
class AssetProvenance {
  final String knowledgeObjectId;
  final String sourceDocumentId;
  final String generationModel;
  final String generationVersion;
  final String editorId;
  final String reviewerId;
  final DateTime? approvalDate;
  final String publishedVersion;

  const AssetProvenance({
    required this.knowledgeObjectId,
    required this.sourceDocumentId,
    this.generationModel = 'Gemini-3.6-Flash',
    this.generationVersion = '1.0.0',
    this.editorId = 'unassigned',
    this.reviewerId = 'unassigned',
    this.approvalDate,
    this.publishedVersion = '1.0.0',
  });

  AssetProvenance copyWith({
    String? knowledgeObjectId,
    String? sourceDocumentId,
    String? generationModel,
    String? generationVersion,
    String? editorId,
    String? reviewerId,
    DateTime? approvalDate,
    String? publishedVersion,
  }) {
    return AssetProvenance(
      knowledgeObjectId: knowledgeObjectId ?? this.knowledgeObjectId,
      sourceDocumentId: sourceDocumentId ?? this.sourceDocumentId,
      generationModel: generationModel ?? this.generationModel,
      generationVersion: generationVersion ?? this.generationVersion,
      editorId: editorId ?? this.editorId,
      reviewerId: reviewerId ?? this.reviewerId,
      approvalDate: approvalDate ?? this.approvalDate,
      publishedVersion: publishedVersion ?? this.publishedVersion,
    );
  }

  Map<String, dynamic> toJson() => {
        'knowledgeObjectId': knowledgeObjectId,
        'sourceDocumentId': sourceDocumentId,
        'generationModel': generationModel,
        'generationVersion': generationVersion,
        'editorId': editorId,
        'reviewerId': reviewerId,
        'approvalDate': approvalDate?.toIso8601String(),
        'publishedVersion': publishedVersion,
      };

  factory AssetProvenance.fromJson(Map<String, dynamic> json) =>
      AssetProvenance(
        knowledgeObjectId: json['knowledgeObjectId'] as String,
        sourceDocumentId: json['sourceDocumentId'] as String,
        generationModel:
            json['generationModel'] as String? ?? 'Gemini-3.6-Flash',
        generationVersion: json['generationVersion'] as String? ?? '1.0.0',
        editorId: json['editorId'] as String? ?? 'unassigned',
        reviewerId: json['reviewerId'] as String? ?? 'unassigned',
        approvalDate: json['approvalDate'] != null
            ? DateTime.parse(json['approvalDate'] as String)
            : null,
        publishedVersion: json['publishedVersion'] as String? ?? '1.0.0',
      );
}

/// Historical snapshot record for version control and rollback.
@immutable
class AssetVersionRecord {
  final String versionId;
  final String assetId;
  final String versionNumber;
  final String snapshotTitle;
  final String snapshotContent;
  final String changeSummary;
  final String authorId;
  final DateTime timestamp;

  const AssetVersionRecord({
    required this.versionId,
    required this.assetId,
    required this.versionNumber,
    required this.snapshotTitle,
    required this.snapshotContent,
    required this.changeSummary,
    required this.authorId,
    required this.timestamp,
  });

  String get changeLogSummary => changeSummary;

  Map<String, dynamic> toJson() => {
        'versionId': versionId,
        'assetId': assetId,
        'versionNumber': versionNumber,
        'snapshotTitle': snapshotTitle,
        'snapshotContent': snapshotContent,
        'changeSummary': changeSummary,
        'authorId': authorId,
        'timestamp': timestamp.toIso8601String(),
      };

  factory AssetVersionRecord.fromJson(Map<String, dynamic> json) =>
      AssetVersionRecord(
        versionId: json['versionId'] as String,
        assetId: json['assetId'] as String,
        versionNumber: json['versionNumber'] as String,
        snapshotTitle: json['snapshotTitle'] as String,
        snapshotContent: json['snapshotContent'] as String,
        changeSummary: json['changeSummary'] as String? ??
            json['changeLogSummary'] as String? ??
            '',
        authorId: json['authorId'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

/// Editorial internal comment / note.
@immutable
class EditorialComment {
  final String id;
  final String assetId;
  final String authorId;
  final String authorName;
  final String commentText;
  final DateTime createdAt;

  const EditorialComment({
    required this.id,
    required this.assetId,
    required this.authorId,
    required this.authorName,
    required this.commentText,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'assetId': assetId,
        'authorId': authorId,
        'authorName': authorName,
        'commentText': commentText,
        'createdAt': createdAt.toIso8601String(),
      };

  factory EditorialComment.fromJson(Map<String, dynamic> json) =>
      EditorialComment(
        id: json['id'] as String,
        assetId: json['assetId'] as String,
        authorId: json['authorId'] as String,
        authorName: json['authorName'] as String,
        commentText: json['commentText'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

/// Quality Validation Checklist covering 9 dimensions.
@immutable
class QualityValidationChecklist {
  final bool accuracyValidated;
  final bool completenessValidated;
  final bool grammarValidated;
  final bool formattingValidated;
  final bool metadataValidated;
  final bool referencesValidated;
  final bool relationshipsValidated;
  final bool learningObjectivesValidated;
  final bool difficultyValidated;

  const QualityValidationChecklist({
    this.accuracyValidated = false,
    this.completenessValidated = false,
    this.grammarValidated = false,
    this.formattingValidated = false,
    this.metadataValidated = false,
    this.referencesValidated = false,
    this.relationshipsValidated = false,
    this.learningObjectivesValidated = false,
    this.difficultyValidated = false,
  });

  bool get isFullyValidated =>
      accuracyValidated &&
      completenessValidated &&
      grammarValidated &&
      formattingValidated &&
      metadataValidated &&
      referencesValidated &&
      relationshipsValidated &&
      learningObjectivesValidated &&
      difficultyValidated;

  int get validatedCount =>
      (accuracyValidated ? 1 : 0) +
      (completenessValidated ? 1 : 0) +
      (grammarValidated ? 1 : 0) +
      (formattingValidated ? 1 : 0) +
      (metadataValidated ? 1 : 0) +
      (referencesValidated ? 1 : 0) +
      (relationshipsValidated ? 1 : 0) +
      (learningObjectivesValidated ? 1 : 0) +
      (difficultyValidated ? 1 : 0);

  QualityValidationChecklist copyWith({
    bool? accuracyValidated,
    bool? completenessValidated,
    bool? grammarValidated,
    bool? formattingValidated,
    bool? metadataValidated,
    bool? referencesValidated,
    bool? relationshipsValidated,
    bool? learningObjectivesValidated,
    bool? difficultyValidated,
  }) {
    return QualityValidationChecklist(
      accuracyValidated: accuracyValidated ?? this.accuracyValidated,
      completenessValidated:
          completenessValidated ?? this.completenessValidated,
      grammarValidated: grammarValidated ?? this.grammarValidated,
      formattingValidated: formattingValidated ?? this.formattingValidated,
      metadataValidated: metadataValidated ?? this.metadataValidated,
      referencesValidated: referencesValidated ?? this.referencesValidated,
      relationshipsValidated:
          relationshipsValidated ?? this.relationshipsValidated,
      learningObjectivesValidated:
          learningObjectivesValidated ?? this.learningObjectivesValidated,
      difficultyValidated: difficultyValidated ?? this.difficultyValidated,
    );
  }

  Map<String, dynamic> toJson() => {
        'accuracyValidated': accuracyValidated,
        'completenessValidated': completenessValidated,
        'grammarValidated': grammarValidated,
        'formattingValidated': formattingValidated,
        'metadataValidated': metadataValidated,
        'referencesValidated': referencesValidated,
        'relationshipsValidated': relationshipsValidated,
        'learningObjectivesValidated': learningObjectivesValidated,
        'difficultyValidated': difficultyValidated,
      };

  factory QualityValidationChecklist.fromJson(Map<String, dynamic> json) =>
      QualityValidationChecklist(
        accuracyValidated: json['accuracyValidated'] as bool? ?? false,
        completenessValidated: json['completenessValidated'] as bool? ?? false,
        grammarValidated: json['grammarValidated'] as bool? ?? false,
        formattingValidated: json['formattingValidated'] as bool? ?? false,
        metadataValidated: json['metadataValidated'] as bool? ?? false,
        referencesValidated: json['referencesValidated'] as bool? ?? false,
        relationshipsValidated:
            json['relationshipsValidated'] as bool? ?? false,
        learningObjectivesValidated:
            json['learningObjectivesValidated'] as bool? ?? false,
        difficultyValidated: json['difficultyValidated'] as bool? ?? false,
      );
}

/// Audit log entry for workflow state transitions.
@immutable
class EditorialAuditEntry {
  final String id;
  final String assetId;
  final EditorialStatus fromStatus;
  final EditorialStatus toStatus;
  final String actorId;
  final EditorialRole actorRole;
  final String notes;
  final DateTime timestamp;

  const EditorialAuditEntry({
    required this.id,
    required this.assetId,
    required this.fromStatus,
    required this.toStatus,
    required this.actorId,
    required this.actorRole,
    this.notes = '',
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'assetId': assetId,
        'fromStatus': fromStatus.name,
        'toStatus': toStatus.name,
        'actorId': actorId,
        'actorRole': actorRole.name,
        'notes': notes,
        'timestamp': timestamp.toIso8601String(),
      };

  factory EditorialAuditEntry.fromJson(Map<String, dynamic> json) =>
      EditorialAuditEntry(
        id: json['id'] as String,
        assetId: json['assetId'] as String,
        fromStatus: EditorialStatus.values.firstWhere(
            (e) => e.name == json['fromStatus'],
            orElse: () => EditorialStatus.draft),
        toStatus: EditorialStatus.values.firstWhere(
            (e) => e.name == json['toStatus'],
            orElse: () => EditorialStatus.published),
        actorId: json['actorId'] as String,
        actorRole: EditorialRole.values.firstWhere(
            (e) => e.name == json['actorRole'],
            orElse: () => EditorialRole.editor),
        notes: json['notes'] as String? ?? '',
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

/// Multi-dimension Editorial Quality Assessment Score.
@immutable
class EditorialQualityScore {
  final double knowledgeQuality; // 0 - 100
  final double editorialQuality; // 0 - 100
  final double completeness; // 0 - 100
  final double readability; // 0 - 100
  final double consistency; // 0 - 100
  final double overallScore; // 0 - 100

  const EditorialQualityScore({
    required this.knowledgeQuality,
    required this.editorialQuality,
    required this.completeness,
    required this.readability,
    required this.consistency,
    required this.overallScore,
  });

  Map<String, dynamic> toJson() => {
        'knowledgeQuality': knowledgeQuality,
        'editorialQuality': editorialQuality,
        'completeness': completeness,
        'readability': readability,
        'consistency': consistency,
        'overallScore': overallScore,
      };

  factory EditorialQualityScore.fromJson(Map<String, dynamic> json) =>
      EditorialQualityScore(
        knowledgeQuality:
            (json['knowledgeQuality'] as num?)?.toDouble() ?? 80.0,
        editorialQuality:
            (json['editorialQuality'] as num?)?.toDouble() ?? 80.0,
        completeness: (json['completeness'] as num?)?.toDouble() ?? 80.0,
        readability: (json['readability'] as num?)?.toDouble() ?? 80.0,
        consistency: (json['consistency'] as num?)?.toDouble() ?? 80.0,
        overallScore: (json['overallScore'] as num?)?.toDouble() ?? 80.0,
      );
}

/// Master Editorial Record wrapping generated learning assets, status, provenance, version history, quality score, validation checklist, comments, and audit log.
@immutable
class EditorialAssetRecord {
  final String id;
  final GeneratedKnowledgeAssets assets;
  final EditorialStatus status;
  final AssetProvenance provenance;
  final EditorialQualityScore qualityScore;
  final QualityValidationChecklist validationChecklist;
  final List<AssetVersionRecord> versionHistory;
  final List<EditorialComment> comments;
  final List<GlossaryItem> glossaryItems;
  final List<EditorialAuditEntry> auditLog;
  final DateTime? scheduledPublishDate;
  final DateTime updatedAt;

  EditorialAssetRecord({
    required this.id,
    required this.assets,
    this.status = EditorialStatus.aiGenerated,
    required this.provenance,
    required this.qualityScore,
    this.validationChecklist = const QualityValidationChecklist(),
    List<AssetVersionRecord>? versionHistory,
    List<EditorialComment>? comments,
    List<GlossaryItem>? glossaryItems,
    List<EditorialAuditEntry>? auditLog,
    this.scheduledPublishDate,
    DateTime? updatedAt,
  })  : versionHistory = List.unmodifiable(versionHistory ?? const []),
        comments = List.unmodifiable(comments ?? const []),
        glossaryItems = List.unmodifiable(glossaryItems ?? const []),
        auditLog = List.unmodifiable(auditLog ?? const []),
        updatedAt = updatedAt ?? DateTime.now();

  EditorialAssetRecord copyWith({
    EditorialStatus? status,
    AssetProvenance? provenance,
    EditorialQualityScore? qualityScore,
    QualityValidationChecklist? validationChecklist,
    List<AssetVersionRecord>? versionHistory,
    List<EditorialComment>? comments,
    List<GlossaryItem>? glossaryItems,
    List<EditorialAuditEntry>? auditLog,
    DateTime? scheduledPublishDate,
    GeneratedKnowledgeAssets? assets,
    DateTime? updatedAt,
  }) {
    return EditorialAssetRecord(
      id: id,
      assets: assets ?? this.assets,
      status: status ?? this.status,
      provenance: provenance ?? this.provenance,
      qualityScore: qualityScore ?? this.qualityScore,
      validationChecklist: validationChecklist ?? this.validationChecklist,
      versionHistory: versionHistory ?? this.versionHistory,
      comments: comments ?? this.comments,
      glossaryItems: glossaryItems ?? this.glossaryItems,
      auditLog: auditLog ?? this.auditLog,
      scheduledPublishDate: scheduledPublishDate ?? this.scheduledPublishDate,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'assets': assets.toJson(),
        'status': status.name,
        'provenance': provenance.toJson(),
        'qualityScore': qualityScore.toJson(),
        'validationChecklist': validationChecklist.toJson(),
        'versionHistory': versionHistory.map((v) => v.toJson()).toList(),
        'comments': comments.map((c) => c.toJson()).toList(),
        'glossaryItems': glossaryItems.map((g) => g.toJson()).toList(),
        'auditLog': auditLog.map((a) => a.toJson()).toList(),
        'scheduledPublishDate': scheduledPublishDate?.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory EditorialAssetRecord.fromJson(Map<String, dynamic> json) {
    return EditorialAssetRecord(
      id: json['id'] as String,
      assets: GeneratedKnowledgeAssets.fromJson(
          Map<String, dynamic>.from(json['assets'] as Map)),
      status: EditorialStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => EditorialStatus.aiGenerated,
      ),
      provenance: AssetProvenance.fromJson(
          Map<String, dynamic>.from(json['provenance'] as Map)),
      qualityScore: EditorialQualityScore.fromJson(
          Map<String, dynamic>.from(json['qualityScore'] as Map)),
      validationChecklist: json['validationChecklist'] != null
          ? QualityValidationChecklist.fromJson(
              Map<String, dynamic>.from(json['validationChecklist'] as Map))
          : const QualityValidationChecklist(),
      versionHistory: (json['versionHistory'] as List? ?? [])
          .map((v) =>
              AssetVersionRecord.fromJson(Map<String, dynamic>.from(v as Map)))
          .toList(),
      comments: (json['comments'] as List? ?? [])
          .map((c) =>
              EditorialComment.fromJson(Map<String, dynamic>.from(c as Map)))
          .toList(),
      glossaryItems: (json['glossaryItems'] as List? ?? [])
          .map(
              (g) => GlossaryItem.fromJson(Map<String, dynamic>.from(g as Map)))
          .toList(),
      auditLog: (json['auditLog'] as List? ?? [])
          .map((a) =>
              EditorialAuditEntry.fromJson(Map<String, dynamic>.from(a as Map)))
          .toList(),
      scheduledPublishDate: json['scheduledPublishDate'] != null
          ? DateTime.parse(json['scheduledPublishDate'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }
}
