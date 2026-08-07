library;

import 'package:garuda_evidence/garuda_evidence.dart';
import '../connector_sdk/raw_evidence_payload.dart';
import '../shared/category_classifier.dart';

/// Gold-standard parser for PIB (Press Information Bureau) Releases.
class PIBRawParser {
  static const String parserVersion = '1.0.0-gold';

  /// Parse a [RawEvidencePayload] into an immutable [EvidenceObject].
  static EvidenceObject parsePayload(RawEvidencePayload payload) {
    final meta = payload.metadata;
    final prid = meta['prid'] as String? ?? payload.sourceIdentifier;
    final title = meta['title'] as String? ?? 'PIB Release $prid';
    final ministry = meta['ministry'] as String? ?? 'Ministry of Information and Broadcasting';
    final rawSummary = meta['summary'] as String? ?? 'Official Press Release from PIB ($ministry).';
    final releaseDate = meta['publicationDate'] is DateTime
        ? meta['publicationDate'] as DateTime
        : (DateTime.tryParse(meta['publicationDate'] as String? ?? '') ?? payload.fetchedAt);

    final articleUrl = meta['articleUrl'] as String? ??
        'https://pib.gov.in/PressReleasePage.aspx?PRID=$prid';
    final pdfUrl = meta['pdfUrl'] as String?;

    final category = CategoryClassifier.classifyCategory(title, rawSummary);
    final tags = CategoryClassifier.extractTags(title, rawSummary);

    final authority = EvidenceAuthority(
      id: 'pib_${ministry.replaceAll(RegExp(r'\s+'), '_').toLowerCase()}',
      name: ministry,
      type: EvidenceSourceType.government,
      jurisdiction: 'India',
    );

    final lineage = EvidenceLineage(
      originalSource: 'PIB Releases',
      originalUrl: articleUrl,
      originalPdf: pdfUrl,
      parserVersion: parserVersion,
      validatorVersion: '1.0.0',
    );

    final lifecycle = EvidenceLifecycle(
      currentState: EvidenceLifecycleState.parsed,
      updatedAt: payload.fetchedAt,
      updatedBy: 'PIBConnector',
    );

    final v1Snapshot = EvidenceVersion(
      versionNumber: 1,
      createdAt: payload.fetchedAt,
      createdBy: 'PIBConnector',
      reason: 'Initial Ingestion',
      checksum: EvidenceHashUtils.sha256String('$title|$rawSummary|$articleUrl'),
      isCurrentVersion: true,
    );

    final attachmentList = <EvidenceAttachment>[];
    if (pdfUrl != null && pdfUrl.isNotEmpty) {
      attachmentList.add(EvidenceAttachment(
        id: 'att_pib_$prid',
        title: 'Official Release Document (PDF)',
        fileType: 'pdf',
        url: pdfUrl,
        mimeType: 'application/pdf',
      ));
    }

    return EvidenceObject(
      id: 'EV-PIB-$prid',
      title: title,
      sourceName: 'PIB Releases',
      sourceType: EvidenceSourceType.government,
      authority: authority,
      publicationDate: releaseDate,
      retrievedDate: payload.fetchedAt,
      category: category,
      subject: category,
      topic: tags.isNotEmpty ? tags.first : category,
      subtopic: ministry,
      keywords: tags,
      language: meta['language'] as String? ?? 'en',
      summary: rawSummary,
      originalUrl: articleUrl,
      pdfUrl: pdfUrl,
      attachments: attachmentList,
      confidenceScore: 0.99,
      verificationStatus: VerificationStatus.verified,
      editorialStatus: EditorialStatus.draft,
      version: 1,
      createdAt: payload.fetchedAt,
      updatedAt: payload.fetchedAt,
      lifecycle: lifecycle,
      versionHistory: [v1Snapshot],
      lineage: lineage,
    );
  }
}
