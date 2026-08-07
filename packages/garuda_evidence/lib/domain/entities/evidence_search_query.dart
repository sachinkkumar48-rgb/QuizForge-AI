import 'package:meta/meta.dart';
import 'enums.dart';

/// Search query configuration for querying Evidence Objects across 8 search vectors:
/// Keyword, Semantic, Topic, Authority, Exam, Subject, Date, Tag.
@immutable
class EvidenceSearchQuery {
  final String? keyword;
  final String? semanticQuery;
  final String? topic;
  final String? authorityId;
  final String? examCategory;
  final String? subject;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> tags;
  final EvidenceSourceType? sourceType;
  final VerificationStatus? verificationStatus;
  final int limit;
  final int offset;

  const EvidenceSearchQuery({
    this.keyword,
    this.semanticQuery,
    this.topic,
    this.authorityId,
    this.examCategory,
    this.subject,
    this.startDate,
    this.endDate,
    this.tags = const [],
    this.sourceType,
    this.verificationStatus,
    this.limit = 20,
    this.offset = 0,
  });

  EvidenceSearchQuery copyWith({
    String? keyword,
    String? semanticQuery,
    String? topic,
    String? authorityId,
    String? examCategory,
    String? subject,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? tags,
    EvidenceSourceType? sourceType,
    VerificationStatus? verificationStatus,
    int? limit,
    int? offset,
  }) {
    return EvidenceSearchQuery(
      keyword: keyword ?? this.keyword,
      semanticQuery: semanticQuery ?? this.semanticQuery,
      topic: topic ?? this.topic,
      authorityId: authorityId ?? this.authorityId,
      examCategory: examCategory ?? this.examCategory,
      subject: subject ?? this.subject,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      tags: tags ?? List.from(this.tags),
      sourceType: sourceType ?? this.sourceType,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'keyword': keyword,
      'semanticQuery': semanticQuery,
      'topic': topic,
      'authorityId': authorityId,
      'examCategory': examCategory,
      'subject': subject,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'tags': tags,
      'sourceType': sourceType?.name,
      'verificationStatus': verificationStatus?.name,
      'limit': limit,
      'offset': offset,
    };
  }

  factory EvidenceSearchQuery.fromJson(Map<String, dynamic> json) {
    return EvidenceSearchQuery(
      keyword: json['keyword'] as String?,
      semanticQuery: json['semanticQuery'] as String?,
      topic: json['topic'] as String?,
      authorityId: json['authorityId'] as String?,
      examCategory: json['examCategory'] as String?,
      subject: json['subject'] as String?,
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'] as String)
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'] as String)
          : null,
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      sourceType: json['sourceType'] != null
          ? EvidenceSourceType.values.firstWhere(
              (e) => e.name == json['sourceType'],
              orElse: () => EvidenceSourceType.other,
            )
          : null,
      verificationStatus: json['verificationStatus'] != null
          ? VerificationStatus.values.firstWhere(
              (e) => e.name == json['verificationStatus'],
              orElse: () => VerificationStatus.pending,
            )
          : null,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EvidenceSearchQuery &&
        other.keyword == keyword &&
        other.semanticQuery == semanticQuery &&
        other.topic == topic &&
        other.authorityId == authorityId &&
        other.examCategory == examCategory &&
        other.subject == subject &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.sourceType == sourceType &&
        other.verificationStatus == verificationStatus &&
        other.limit == limit &&
        other.offset == offset;
  }

  @override
  int get hashCode => Object.hash(
        keyword,
        semanticQuery,
        topic,
        authorityId,
        examCategory,
        subject,
        startDate,
        endDate,
        sourceType,
        verificationStatus,
        limit,
        offset,
      );
}
