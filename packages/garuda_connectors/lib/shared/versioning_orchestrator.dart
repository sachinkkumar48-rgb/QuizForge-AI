library;

import 'package:garuda_evidence/garuda_evidence.dart';

/// Orchestrates non-destructive version creation when an existing EvidenceObject changes.
class VersioningOrchestrator {
  /// Create next version of evidence object without overwriting previous history.
  static EvidenceObject createNextVersion({
    required EvidenceObject existing,
    required EvidenceObject updatedContent,
    required String editorOrConnector,
    required String reason,
  }) {
    final newVersionNumber = existing.version + 1;
    final now = DateTime.now();

    final newChecksum = EvidenceHashUtils.sha256String(
      '${updatedContent.title}|${updatedContent.summary}|${updatedContent.originalUrl}',
    );

    final snapshot = EvidenceVersion(
      versionNumber: newVersionNumber,
      createdAt: now,
      createdBy: editorOrConnector,
      reason: reason,
      checksum: newChecksum,
      previousVersion: existing.version,
      isCurrentVersion: true,
    );

    final updatedHistory = [
      ...existing.versionHistory.map((v) => v.markPrevious()),
      snapshot,
    ];

    final updatedLifecycle = existing.activeLifecycle.transitionTo(
      EvidenceLifecycleState.reviewPending,
      by: editorOrConnector,
      notes: 'New version $newVersionNumber generated ($reason)',
    );

    return existing.copyWith(
      title: updatedContent.title,
      summary: updatedContent.summary,
      originalUrl: updatedContent.originalUrl,
      pdfUrl: updatedContent.pdfUrl ?? existing.pdfUrl,
      category: updatedContent.category,
      subject: updatedContent.subject,
      topic: updatedContent.topic,
      subtopic: updatedContent.subtopic,
      keywords: updatedContent.keywords,
      attachments: updatedContent.attachments,
      version: newVersionNumber,
      updatedAt: now,
      lifecycle: updatedLifecycle,
      versionHistory: updatedHistory,
    );
  }
}
