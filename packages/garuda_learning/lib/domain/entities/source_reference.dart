/// Source Reference Entity (TITAN-KO-025.0 P25).
///
/// Immutable value object representing a verified legal, statutory, constitutional,
/// or academic source citation backing a remedial micro-lesson.
///
/// Educational Safety Invariants:
/// - Citations and reference identifiers must NEVER be fabricated.
/// - Verbatim statutory wording must be tied directly to a verified source ID.
/// - Deep links and page numbers provide direct provenance back into source literature.
library;

import 'package:meta/meta.dart';

/// Taxonomy of authoritative source material types.
enum SourceReferenceType {
  /// Constitutional text, articles, schedules, or amendments.
  constitution,

  /// Statutory acts, codes, sections, or statutory rules.
  statute,

  /// Judicial decisions, landmark judgments, or case law ratios.
  caseLaw,

  /// Standard textbooks, academic treatises, or commentary.
  textbook,

  /// Verified past examination questions or official papers.
  pastQuestion,

  /// Official gazette notifications, commission reports, or government circulars.
  officialNotification;

  /// Human-readable display title.
  String get displayName {
    switch (this) {
      case SourceReferenceType.constitution:
        return 'Constitutional Provision';
      case SourceReferenceType.statute:
        return 'Statutory Provision';
      case SourceReferenceType.caseLaw:
        return 'Case Law Citation';
      case SourceReferenceType.textbook:
        return 'Academic Reference';
      case SourceReferenceType.pastQuestion:
        return 'Past Examination Paper';
      case SourceReferenceType.officialNotification:
        return 'Official Notification';
    }
  }

  /// Parses a string name into a [SourceReferenceType], defaulting to [statute].
  static SourceReferenceType fromJson(String? name) {
    if (name == null) return SourceReferenceType.statute;
    return SourceReferenceType.values.firstWhere(
      (e) => e.name == name,
      orElse: () => SourceReferenceType.statute,
    );
  }

  /// Serializes to JSON string.
  String toJson() => name;
}

/// Immutable provenance reference linking remedial content to an authoritative primary source.
@immutable
class SourceReference {
  /// Canonical identifier of the backing document or knowledge product (P11–P16).
  final String sourceId;

  /// Kind of authoritative source material.
  final SourceReferenceType sourceType;

  /// Formal statutory section, case citation, or article reference identifier.
  /// (e.g. "Article 21, Constitution of India", "Section 300 IPC", "AIR 1978 SC 597").
  final String referenceIdentifier;

  /// Optional 1-based page number within the backing source document.
  final int? pageNumber;

  /// Optional selected verbatim or excerpted text from the primary source.
  final String? excerptText;

  /// Optional deep link URI into TITAN Reader or document corpus.
  final String? documentUri;

  /// Immutable source metadata.
  final Map<String, dynamic> metadata;

  SourceReference({
    required this.sourceId,
    required this.sourceType,
    required this.referenceIdentifier,
    this.pageNumber,
    this.excerptText,
    this.documentUri,
    Map<String, dynamic>? metadata,
  }) : metadata = Map<String, dynamic>.unmodifiable(
            metadata ?? const <String, dynamic>{}) {
    if (sourceId.trim().isEmpty) {
      throw ArgumentError('sourceId cannot be empty for SourceReference');
    }
    if (referenceIdentifier.trim().isEmpty) {
      throw ArgumentError(
          'referenceIdentifier cannot be empty for SourceReference');
    }
    if (pageNumber != null && pageNumber! < 1) {
      throw ArgumentError('pageNumber ($pageNumber) must be >= 1 if specified');
    }
  }

  /// Whether this source reference contains a verbatim text excerpt.
  bool get hasExcerpt => excerptText != null && excerptText!.trim().isNotEmpty;

  /// Whether this source reference provides a deep-link URI.
  bool get hasDocumentUri =>
      documentUri != null && documentUri!.trim().isNotEmpty;

  /// Serializes to JSON map.
  Map<String, dynamic> toJson() => {
        'sourceId': sourceId,
        'sourceType': sourceType.name,
        'referenceIdentifier': referenceIdentifier,
        if (pageNumber != null) 'pageNumber': pageNumber,
        if (excerptText != null) 'excerptText': excerptText,
        if (documentUri != null) 'documentUri': documentUri,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  /// Deserializes from JSON map.
  factory SourceReference.fromJson(Map<String, dynamic> json) =>
      SourceReference(
        sourceId: json['sourceId'] as String? ?? '',
        sourceType: SourceReferenceType.fromJson(json['sourceType'] as String?),
        referenceIdentifier: json['referenceIdentifier'] as String? ?? '',
        pageNumber: json['pageNumber'] as int?,
        excerptText: json['excerptText'] as String?,
        documentUri: json['documentUri'] as String?,
        metadata: json['metadata'] != null
            ? Map<String, dynamic>.from(json['metadata'] as Map)
            : null,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SourceReference &&
          runtimeType == other.runtimeType &&
          sourceId == other.sourceId &&
          sourceType == other.sourceType &&
          referenceIdentifier == other.referenceIdentifier &&
          pageNumber == other.pageNumber &&
          excerptText == other.excerptText &&
          documentUri == other.documentUri;

  @override
  int get hashCode => Object.hash(
        sourceId,
        sourceType,
        referenceIdentifier,
        pageNumber,
        excerptText,
        documentUri,
      );

  @override
  String toString() =>
      'SourceReference($sourceType: $referenceIdentifier [sourceId: $sourceId])';
}
