import 'package:titan_knowledge_graph/titan_knowledge_graph.dart';
import 'package:titan_search/titan_search.dart';
import '../../intelligence/models/generated_learning_assets.dart';
import '../models/editorial_models.dart';
import '../repository/editorial_repository.dart';

/// Analytics metrics container for Editorial Platform.
class EditorialAnalytics {
  final int totalAssets;
  final int pendingReviewCount;
  final int publishedCount;
  final int rejectedCount;
  final int archivedCount;
  final double approvalRatePercentage;
  final double averageQualityScore;
  final double averageReviewTimeMinutes;
  final Map<String, int> editorProductivity;

  const EditorialAnalytics({
    required this.totalAssets,
    required this.pendingReviewCount,
    required this.publishedCount,
    required this.rejectedCount,
    this.archivedCount = 0,
    required this.approvalRatePercentage,
    required this.averageQualityScore,
    this.averageReviewTimeMinutes = 15.0,
    this.editorProductivity = const {},
  });
}

/// Pure Dart Master Editorial Workflow Engine for Project TITAN.
class EditorialWorkflowEngine {
  final EditorialRepository repository;
  final SearchRepository searchRepository;
  final KnowledgeGraphRepository graphRepository;

  EditorialWorkflowEngine({
    required this.repository,
    required this.searchRepository,
    required this.graphRepository,
  });

  /// Ingests a new [GeneratedKnowledgeAssets] instance into the Editorial Platform.
  Future<EditorialAssetRecord> initializeRecord({
    required GeneratedKnowledgeAssets assets,
    required String sourceDocumentId,
  }) async {
    final recordId = 'ed_${assets.id}';
    final provenance = AssetProvenance(
      knowledgeObjectId: assets.sourceKnowledgeObjectId,
      sourceDocumentId: sourceDocumentId,
    );

    final qualityScore = EditorialQualityScore(
      knowledgeQuality: assets.qualityReport.score,
      editorialQuality: 80.0,
      completeness: assets.qualityReport.completenessScore,
      readability: assets.qualityReport.readabilityScore,
      consistency: 85.0,
      overallScore: (assets.qualityReport.score + 80.0) / 2,
    );

    final initialVersion = AssetVersionRecord(
      versionId: 'v_1_0_0',
      assetId: recordId,
      versionNumber: '1.0.0',
      snapshotTitle: assets.lessonTitle,
      snapshotContent: assets.summaries.detailedSummary,
      changeSummary: 'Initial AI Generation',
      authorId: 'AI_GENERATOR',
      timestamp: DateTime.now(),
    );

    final initialAudit = EditorialAuditEntry(
      id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
      assetId: recordId,
      fromStatus: EditorialStatus.draft,
      toStatus: EditorialStatus.aiGenerated,
      actorId: 'AI_GENERATOR',
      actorRole: EditorialRole.aiGenerator,
      notes: 'Initial AI asset generation ingestion',
      timestamp: DateTime.now(),
    );

    final record = EditorialAssetRecord(
      id: recordId,
      assets: assets,
      status: EditorialStatus.aiGenerated,
      provenance: provenance,
      qualityScore: qualityScore,
      versionHistory: [initialVersion],
      auditLog: [initialAudit],
    );

    await repository.saveRecord(record);
    return record;
  }

  /// State Transition: Submit for Editorial Review.
  Future<EditorialAssetRecord> submitForReview(String recordId, String actorId,
      {EditorialRole role = EditorialRole.author}) async {
    final record = await _getRecordOrThrow(recordId);
    if (record.status == EditorialStatus.archived ||
        record.status == EditorialStatus.published) {
      throw StateError(
          'Cannot submit asset in status ${record.status} for review');
    }
    final audit = EditorialAuditEntry(
      id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
      assetId: recordId,
      fromStatus: record.status,
      toStatus: EditorialStatus.needsReview,
      actorId: actorId,
      actorRole: role,
      notes: 'Submitted for editorial review',
      timestamp: DateTime.now(),
    );
    final auditLog = List<EditorialAuditEntry>.from(record.auditLog)
      ..add(audit);

    final updated = record.copyWith(
      status: EditorialStatus.needsReview,
      provenance: record.provenance.copyWith(editorId: actorId),
      auditLog: auditLog,
    );
    await repository.saveRecord(updated);
    return updated;
  }

  /// State Transition: Claim for Active Editorial Review.
  Future<EditorialAssetRecord> claimForReview(String recordId, String editorId,
      {EditorialRole role = EditorialRole.editor}) async {
    if (!role.canReview) {
      throw StateError('Role ${role.name} is not authorized to review assets.');
    }
    final record = await _getRecordOrThrow(recordId);
    if (record.status == EditorialStatus.archived) {
      throw StateError('Cannot claim archived asset for review.');
    }
    final audit = EditorialAuditEntry(
      id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
      assetId: recordId,
      fromStatus: record.status,
      toStatus: EditorialStatus.editorReview,
      actorId: editorId,
      actorRole: role,
      notes: 'Claimed by editor for active review',
      timestamp: DateTime.now(),
    );
    final auditLog = List<EditorialAuditEntry>.from(record.auditLog)
      ..add(audit);

    final updated = record.copyWith(
      status: EditorialStatus.editorReview,
      provenance: record.provenance.copyWith(editorId: editorId),
      auditLog: auditLog,
    );
    await repository.saveRecord(updated);
    return updated;
  }

  /// State Transition: Submit to Senior Reviewer for Approval.
  Future<EditorialAssetRecord> submitForSeniorApproval(
      String recordId, String editorId,
      {EditorialRole role = EditorialRole.editor}) async {
    if (!role.canReview) {
      throw StateError(
          'Role ${role.name} is not authorized to submit for senior approval.');
    }
    final record = await _getRecordOrThrow(recordId);
    if (record.status == EditorialStatus.archived) {
      throw StateError('Cannot submit archived asset for approval.');
    }
    final audit = EditorialAuditEntry(
      id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
      assetId: recordId,
      fromStatus: record.status,
      toStatus: EditorialStatus.reviewerApproval,
      actorId: editorId,
      actorRole: role,
      notes: 'Submitted for senior reviewer approval',
      timestamp: DateTime.now(),
    );
    final auditLog = List<EditorialAuditEntry>.from(record.auditLog)
      ..add(audit);

    final updated = record.copyWith(
      status: EditorialStatus.reviewerApproval,
      provenance: record.provenance.copyWith(editorId: editorId),
      auditLog: auditLog,
    );
    await repository.saveRecord(updated);
    return updated;
  }

  /// Inline Editing: Modify asset properties and create a new version snapshot.
  Future<EditorialAssetRecord> updateContent({
    required String recordId,
    required String newTitle,
    required String newDetailedSummary,
    required String changeSummary,
    required String editorId,
  }) async {
    final record = await _getRecordOrThrow(recordId);
    final currentHistory = List<AssetVersionRecord>.from(record.versionHistory);

    final newVerNumber = '1.${currentHistory.length}.0';
    final newVersion = AssetVersionRecord(
      versionId: 'v_${newVerNumber.replaceAll('.', '_')}',
      assetId: recordId,
      versionNumber: newVerNumber,
      snapshotTitle: newTitle,
      snapshotContent: newDetailedSummary,
      changeSummary: changeSummary,
      authorId: editorId,
      timestamp: DateTime.now(),
    );

    currentHistory.add(newVersion);

    final updatedSummaries = SummaryBundle(
      summary30s: record.assets.summaries.summary30s,
      summary5m: record.assets.summaries.summary5m,
      detailedSummary: newDetailedSummary,
    );

    final updatedAssets = GeneratedKnowledgeAssets(
      id: record.assets.id,
      sourceKnowledgeObjectId: record.assets.sourceKnowledgeObjectId,
      lessonTitle: newTitle,
      summaries: updatedSummaries,
      questions: record.assets.questions,
      flashcards: record.assets.flashcards,
      revisionNotes: record.assets.revisionNotes,
      mindMap: record.assets.mindMap,
      objectivesMetadata: record.assets.objectivesMetadata,
      tutorContext: record.assets.tutorContext,
      qualityReport: record.assets.qualityReport,
      generationMetadata: record.assets.generationMetadata,
      generatedAt: record.assets.generatedAt,
    );

    final newEditorialQuality =
        (record.qualityScore.editorialQuality + 5.0).clamp(0.0, 100.0);
    final updatedScore = EditorialQualityScore(
      knowledgeQuality: record.qualityScore.knowledgeQuality,
      editorialQuality: newEditorialQuality,
      completeness: record.qualityScore.completeness,
      readability: record.qualityScore.readability,
      consistency: record.qualityScore.consistency,
      overallScore:
          (record.qualityScore.knowledgeQuality + newEditorialQuality) / 2,
    );

    final updatedRecord = record.copyWith(
      assets: updatedAssets,
      provenance: record.provenance.copyWith(editorId: editorId),
      qualityScore: updatedScore,
      versionHistory: currentHistory,
    );

    await repository.saveRecord(updatedRecord);
    return updatedRecord;
  }

  /// Update Quality Validation Checklist for an asset.
  Future<EditorialAssetRecord> updateValidationChecklist({
    required String recordId,
    required QualityValidationChecklist checklist,
    required String actorId,
  }) async {
    final record = await _getRecordOrThrow(recordId);
    final updated = record.copyWith(
      validationChecklist: checklist,
      updatedAt: DateTime.now(),
    );
    await repository.saveRecord(updated);
    return updated;
  }

  /// Version Rollback: Revert content to a previous version snapshot.
  Future<EditorialAssetRecord> rollbackToVersion(
      String recordId, String versionId, String actorId,
      {EditorialRole role = EditorialRole.editor}) async {
    if (!role.canReview) {
      throw StateError(
          'Role ${role.name} is not authorized to rollback versions.');
    }
    final record = await _getRecordOrThrow(recordId);
    if (record.status == EditorialStatus.archived) {
      throw StateError('Cannot rollback archived asset.');
    }
    final targetVersion = record.versionHistory.firstWhere(
      (v) => v.versionId == versionId,
      orElse: () => throw ArgumentError('Version $versionId not found'),
    );

    return await updateContent(
      recordId: recordId,
      newTitle: targetVersion.snapshotTitle,
      newDetailedSummary: targetVersion.snapshotContent,
      changeSummary: 'Rollback to version ${targetVersion.versionNumber}',
      editorId: actorId,
    );
  }

  /// State Transition: Approve and Publish Asset (Updates Search & Knowledge Graph).
  Future<EditorialAssetRecord> approveAndPublish(
      String recordId, String reviewerId,
      {EditorialRole role = EditorialRole.seniorReviewer}) async {
    if (!role.canPublish && !role.canApprove) {
      throw StateError(
          'Role ${role.name} is not authorized to approve and publish assets.');
    }
    final record = await _getRecordOrThrow(recordId);
    if (record.status == EditorialStatus.archived) {
      throw StateError('Cannot publish archived asset.');
    }

    final publishedProvenance = record.provenance.copyWith(
      reviewerId: reviewerId,
      approvalDate: DateTime.now(),
      publishedVersion: record.versionHistory.last.versionNumber,
    );

    final audit = EditorialAuditEntry(
      id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
      assetId: recordId,
      fromStatus: record.status,
      toStatus: EditorialStatus.published,
      actorId: reviewerId,
      actorRole: role,
      notes: 'Approved and published to Knowledge Base & Search',
      timestamp: DateTime.now(),
    );
    final auditLog = List<EditorialAuditEntry>.from(record.auditLog)
      ..add(audit);

    final updated = record.copyWith(
      status: EditorialStatus.published,
      provenance: publishedProvenance,
      auditLog: auditLog,
    );

    await repository.saveRecord(updated);

    // Re-index published asset in titan_search
    await searchRepository.indexItem(SearchIndexItem(
      id: 'pub_idx_${updated.id}',
      contentId: updated.assets.sourceKnowledgeObjectId,
      title: updated.assets.lessonTitle,
      content: updated.assets.summaries.detailedSummary,
      scope: SearchScope.notes,
      tags: ['Published', updated.assets.lessonTitle],
    ));

    // Update titan_knowledge_graph node
    final pubNode = KnowledgeNode(
      id: 'node_pub_${updated.id}',
      title: 'Published: ${updated.assets.lessonTitle}',
      type: KnowledgeNodeType.topic,
      masteryWeight: 1.0,
    );
    await graphRepository.addNode(pubNode);

    return updated;
  }

  /// Schedule Publication for a future date.
  Future<EditorialAssetRecord> schedulePublication({
    required String recordId,
    required DateTime scheduledDate,
    required String actorId,
  }) async {
    final record = await _getRecordOrThrow(recordId);
    final audit = EditorialAuditEntry(
      id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
      assetId: recordId,
      fromStatus: record.status,
      toStatus: record.status,
      actorId: actorId,
      actorRole: EditorialRole.publisher,
      notes: 'Publication scheduled for ${scheduledDate.toIso8601String()}',
      timestamp: DateTime.now(),
    );
    final auditLog = List<EditorialAuditEntry>.from(record.auditLog)
      ..add(audit);

    final updated = record.copyWith(
      scheduledPublishDate: scheduledDate,
      auditLog: auditLog,
    );
    await repository.saveRecord(updated);
    return updated;
  }

  /// State Transition: Reject Asset with feedback comments.
  Future<EditorialAssetRecord> rejectAsset(
      String recordId, String actorId, String reason) async {
    final record = await _getRecordOrThrow(recordId);
    final comments = List<EditorialComment>.from(record.comments);
    comments.add(EditorialComment(
      id: 'c_${DateTime.now().millisecondsSinceEpoch}',
      assetId: recordId,
      authorId: actorId,
      authorName: 'Reviewer $actorId',
      commentText: reason,
      createdAt: DateTime.now(),
    ));

    final audit = EditorialAuditEntry(
      id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
      assetId: recordId,
      fromStatus: record.status,
      toStatus: EditorialStatus.needsReview,
      actorId: actorId,
      actorRole: EditorialRole.seniorReviewer,
      notes: 'Asset rejected with reason: $reason',
      timestamp: DateTime.now(),
    );
    final auditLog = List<EditorialAuditEntry>.from(record.auditLog)
      ..add(audit);

    final updated = record.copyWith(
      status: EditorialStatus.needsReview,
      comments: comments,
      auditLog: auditLog,
    );

    await repository.saveRecord(updated);
    return updated;
  }

  /// Add Internal Editorial Comment.
  Future<EditorialAssetRecord> addComment({
    required String recordId,
    required String authorId,
    required String authorName,
    required String commentText,
  }) async {
    final record = await _getRecordOrThrow(recordId);
    final comments = List<EditorialComment>.from(record.comments)
      ..add(EditorialComment(
        id: 'c_${DateTime.now().millisecondsSinceEpoch}',
        assetId: recordId,
        authorId: authorId,
        authorName: authorName,
        commentText: commentText,
        createdAt: DateTime.now(),
      ));

    final updated = record.copyWith(comments: comments);
    await repository.saveRecord(updated);
    return updated;
  }

  /// State Transition: Unpublish Asset.
  Future<EditorialAssetRecord> unpublishAsset(
      String recordId, String actorId) async {
    final record = await _getRecordOrThrow(recordId);
    final audit = EditorialAuditEntry(
      id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
      assetId: recordId,
      fromStatus: record.status,
      toStatus: EditorialStatus.unpublished,
      actorId: actorId,
      actorRole: EditorialRole.publisher,
      notes: 'Asset unpublished by $actorId',
      timestamp: DateTime.now(),
    );
    final auditLog = List<EditorialAuditEntry>.from(record.auditLog)
      ..add(audit);

    final updated = record.copyWith(
      status: EditorialStatus.unpublished,
      auditLog: auditLog,
    );
    await repository.saveRecord(updated);
    await searchRepository.removeIndexedItem('pub_idx_${record.id}');
    return updated;
  }

  /// State Transition: Archive Asset.
  Future<EditorialAssetRecord> archiveAsset(
      String recordId, String actorId) async {
    final record = await _getRecordOrThrow(recordId);
    final audit = EditorialAuditEntry(
      id: 'aud_${DateTime.now().millisecondsSinceEpoch}',
      assetId: recordId,
      fromStatus: record.status,
      toStatus: EditorialStatus.archived,
      actorId: actorId,
      actorRole: EditorialRole.administrator,
      notes: 'Asset archived',
      timestamp: DateTime.now(),
    );
    final auditLog = List<EditorialAuditEntry>.from(record.auditLog)
      ..add(audit);

    final updated = record.copyWith(
      status: EditorialStatus.archived,
      auditLog: auditLog,
    );
    await repository.saveRecord(updated);
    return updated;
  }

  /// Compute Editorial Analytics.
  Future<EditorialAnalytics> getAnalytics() async {
    final all = await repository.getAllRecords();
    if (all.isEmpty) {
      return const EditorialAnalytics(
        totalAssets: 0,
        pendingReviewCount: 0,
        publishedCount: 0,
        rejectedCount: 0,
        archivedCount: 0,
        approvalRatePercentage: 0.0,
        averageQualityScore: 0.0,
        averageReviewTimeMinutes: 0.0,
        editorProductivity: {},
      );
    }

    final pending = all
        .where((r) =>
            r.status == EditorialStatus.needsReview ||
            r.status == EditorialStatus.editorReview)
        .length;
    final published =
        all.where((r) => r.status == EditorialStatus.published).length;
    final archived =
        all.where((r) => r.status == EditorialStatus.archived).length;
    final rejected = all
        .where((r) => r.comments
            .any((c) => c.commentText.toLowerCase().contains('reject')))
        .length;
    final totalQuality =
        all.fold<double>(0.0, (sum, r) => sum + r.qualityScore.overallScore);

    final productivity = <String, int>{};
    for (final r in all) {
      final ed = r.provenance.editorId;
      if (ed != 'unassigned') {
        productivity[ed] = (productivity[ed] ?? 0) + 1;
      }
    }

    return EditorialAnalytics(
      totalAssets: all.length,
      pendingReviewCount: pending,
      publishedCount: published,
      rejectedCount: rejected,
      archivedCount: archived,
      approvalRatePercentage: (published / all.length) * 100,
      averageQualityScore: totalQuality / all.length,
      averageReviewTimeMinutes: 12.5,
      editorProductivity: productivity,
    );
  }

  Future<EditorialAssetRecord> _getRecordOrThrow(String recordId) async {
    final rec = await repository.getRecordById(recordId);
    if (rec == null) {
      throw ArgumentError('EditorialAssetRecord with id $recordId not found');
    }
    return rec;
  }
}
