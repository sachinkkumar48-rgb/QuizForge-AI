import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';
import '../../domain/entities/knowledge_source.dart';
import 'knowledge_document_type.dart';
import 'knowledge_editorial_status.dart';

/// Immutable entity representing an incoming document to be ingested into GARUDA.
@immutable
class KnowledgeDocument {
  final String documentId;
  final KnowledgeSource source;
  final KnowledgeDocumentType type;
  final String title;
  final String content;
  final DateTime publicationDate;
  final String version;
  final String language;
  final String checksum;
  final String? officialUrl;
  final DateTime retrievedDate;
  final String parserVersion;
  final KnowledgeEditorialStatus editorialStatus;
  final Map<String, dynamic> metadata;

  const KnowledgeDocument({
    required this.documentId,
    required this.source,
    required this.type,
    required this.title,
    required this.content,
    required this.publicationDate,
    this.version = '1.0.0',
    this.language = 'en',
    required this.checksum,
    this.officialUrl,
    required this.retrievedDate,
    this.parserVersion = '1.0.0',
    this.editorialStatus = KnowledgeEditorialStatus.draft,
    this.metadata = const {},
  });

  /// Factory helper to create a KnowledgeDocument with auto-computed SHA-256 checksum.
  factory KnowledgeDocument.create({
    required String documentId,
    required KnowledgeSource source,
    required KnowledgeDocumentType type,
    required String title,
    required String content,
    required DateTime publicationDate,
    String version = '1.0.0',
    String language = 'en',
    String? officialUrl,
    DateTime? retrievedDate,
    String parserVersion = '1.0.0',
    KnowledgeEditorialStatus editorialStatus = KnowledgeEditorialStatus.draft,
    Map<String, dynamic> metadata = const {},
  }) {
    final bytes = utf8.encode(content);
    final computedChecksum = sha256.convert(bytes).toString();

    return KnowledgeDocument(
      documentId: documentId,
      source: source,
      type: type,
      title: title,
      content: content,
      publicationDate: publicationDate,
      version: version,
      language: language,
      checksum: computedChecksum,
      officialUrl: officialUrl,
      retrievedDate: retrievedDate ?? DateTime.now(),
      parserVersion: parserVersion,
      editorialStatus: editorialStatus,
      metadata: metadata,
    );
  }

  /// Verifies if the stored checksum matches the content SHA-256 hash.
  bool verifyChecksum() {
    final computed = sha256.convert(utf8.encode(content)).toString();
    return computed == checksum;
  }

  KnowledgeDocument copyWith({
    String? documentId,
    KnowledgeSource? source,
    KnowledgeDocumentType? type,
    String? title,
    String? content,
    DateTime? publicationDate,
    String? version,
    String? language,
    String? checksum,
    String? officialUrl,
    DateTime? retrievedDate,
    String? parserVersion,
    KnowledgeEditorialStatus? editorialStatus,
    Map<String, dynamic>? metadata,
  }) {
    return KnowledgeDocument(
      documentId: documentId ?? this.documentId,
      source: source ?? this.source,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      publicationDate: publicationDate ?? this.publicationDate,
      version: version ?? this.version,
      language: language ?? this.language,
      checksum: checksum ?? this.checksum,
      officialUrl: officialUrl ?? this.officialUrl,
      retrievedDate: retrievedDate ?? this.retrievedDate,
      parserVersion: parserVersion ?? this.parserVersion,
      editorialStatus: editorialStatus ?? this.editorialStatus,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'documentId': documentId,
        'source': source.toJson(),
        'type': type.toJson(),
        'title': title,
        'content': content,
        'publicationDate': publicationDate.toIso8601String(),
        'version': version,
        'language': language,
        'checksum': checksum,
        'officialUrl': officialUrl,
        'retrievedDate': retrievedDate.toIso8601String(),
        'parserVersion': parserVersion,
        'editorialStatus': editorialStatus.toJson(),
        'metadata': metadata,
      };

  factory KnowledgeDocument.fromJson(Map<String, dynamic> json) {
    return KnowledgeDocument(
      documentId: json['documentId'] as String? ?? '',
      source: KnowledgeSource.fromJson(json['source'] as Map<String, dynamic>? ?? {}),
      type: KnowledgeDocumentType.fromJson(json['type'] as String? ?? 'generic'),
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      publicationDate: json['publicationDate'] != null
          ? DateTime.parse(json['publicationDate'] as String)
          : DateTime.now(),
      version: json['version'] as String? ?? '1.0.0',
      language: json['language'] as String? ?? 'en',
      checksum: json['checksum'] as String? ?? '',
      officialUrl: json['officialUrl'] as String?,
      retrievedDate: json['retrievedDate'] != null
          ? DateTime.parse(json['retrievedDate'] as String)
          : DateTime.now(),
      parserVersion: json['parserVersion'] as String? ?? '1.0.0',
      editorialStatus: KnowledgeEditorialStatus.fromJson(
        json['editorialStatus'] as String? ?? 'draft',
      ),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KnowledgeDocument &&
          runtimeType == other.runtimeType &&
          documentId == other.documentId &&
          checksum == other.checksum;

  @override
  int get hashCode => Object.hash(documentId, checksum);
}
