import 'package:meta/meta.dart';
import 'annotation.dart';
import 'enums.dart';
import 'highlight.dart';
import 'note_attachment.dart';
import 'note_bookmark.dart';
import 'note_comment.dart';
import 'note_reference.dart';
import 'note_section.dart';
import 'note_summary.dart';
import 'note_tag.dart';
import 'note_version.dart';

/// Primary immutable domain model representing a Smart Note in Project TITAN.
@immutable
class SmartNote {
  final String id;
  final String title;
  final String content;
  final NoteType type;
  final String? contentId;
  final String? collectionId;
  final int? timestampSeconds;
  final int? pageNumber;
  final List<String> knowledgeNodeIds;
  final List<NoteSection> sections;
  final List<NoteTag> tags;
  final List<NoteAttachment> attachments;
  final List<NoteBookmark> bookmarks;
  final List<NoteVersion> versions;
  final List<NoteComment> comments;
  final List<NoteReference> references;
  final List<Highlight> highlights;
  final List<Annotation> annotations;
  final NoteSummary? summary;
  final bool isPinned;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  SmartNote({
    required this.id,
    required this.title,
    required this.content,
    this.type = NoteType.manual,
    this.contentId,
    this.collectionId,
    this.timestampSeconds,
    this.pageNumber,
    required List<String> knowledgeNodeIds,
    required List<NoteSection> sections,
    required List<NoteTag> tags,
    required List<NoteAttachment> attachments,
    required List<NoteBookmark> bookmarks,
    required List<NoteVersion> versions,
    required List<NoteComment> comments,
    required List<NoteReference> references,
    required List<Highlight> highlights,
    required List<Annotation> annotations,
    this.summary,
    this.isPinned = false,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  })  : knowledgeNodeIds = List<String>.unmodifiable(knowledgeNodeIds),
        sections = List<NoteSection>.unmodifiable(sections),
        tags = List<NoteTag>.unmodifiable(tags),
        attachments = List<NoteAttachment>.unmodifiable(attachments),
        bookmarks = List<NoteBookmark>.unmodifiable(bookmarks),
        versions = List<NoteVersion>.unmodifiable(versions),
        comments = List<NoteComment>.unmodifiable(comments),
        references = List<NoteReference>.unmodifiable(references),
        highlights = List<Highlight>.unmodifiable(highlights),
        annotations = List<Annotation>.unmodifiable(annotations);

  SmartNote copyWith({
    String? id,
    String? title,
    String? content,
    NoteType? type,
    String? contentId,
    String? collectionId,
    int? timestampSeconds,
    int? pageNumber,
    List<String>? knowledgeNodeIds,
    List<NoteSection>? sections,
    List<NoteTag>? tags,
    List<NoteAttachment>? attachments,
    List<NoteBookmark>? bookmarks,
    List<NoteVersion>? versions,
    List<NoteComment>? comments,
    List<NoteReference>? references,
    List<Highlight>? highlights,
    List<Annotation>? annotations,
    NoteSummary? summary,
    bool? isPinned,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SmartNote(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      contentId: contentId ?? this.contentId,
      collectionId: collectionId ?? this.collectionId,
      timestampSeconds: timestampSeconds ?? this.timestampSeconds,
      pageNumber: pageNumber ?? this.pageNumber,
      knowledgeNodeIds: knowledgeNodeIds ?? this.knowledgeNodeIds,
      sections: sections ?? this.sections,
      tags: tags ?? this.tags,
      attachments: attachments ?? this.attachments,
      bookmarks: bookmarks ?? this.bookmarks,
      versions: versions ?? this.versions,
      comments: comments ?? this.comments,
      references: references ?? this.references,
      highlights: highlights ?? this.highlights,
      annotations: annotations ?? this.annotations,
      summary: summary ?? this.summary,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'type': type.name,
        'contentId': contentId,
        'collectionId': collectionId,
        'timestampSeconds': timestampSeconds,
        'pageNumber': pageNumber,
        'knowledgeNodeIds': knowledgeNodeIds,
        'sections': sections.map((s) => s.toJson()).toList(),
        'tags': tags.map((t) => t.toJson()).toList(),
        'attachments': attachments.map((a) => a.toJson()).toList(),
        'bookmarks': bookmarks.map((b) => b.toJson()).toList(),
        'versions': versions.map((v) => v.toJson()).toList(),
        'comments': comments.map((c) => c.toJson()).toList(),
        'references': references.map((r) => r.toJson()).toList(),
        'highlights': highlights.map((h) => h.toJson()).toList(),
        'annotations': annotations.map((a) => a.toJson()).toList(),
        'summary': summary?.toJson(),
        'isPinned': isPinned,
        'isArchived': isArchived,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory SmartNote.fromJson(Map<String, dynamic> json) => SmartNote(
        id: json['id'] as String,
        title: json['title'] as String,
        content: json['content'] as String,
        type: NoteType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => NoteType.manual,
        ),
        contentId: json['contentId'] as String?,
        collectionId: json['collectionId'] as String?,
        timestampSeconds: json['timestampSeconds'] as int?,
        pageNumber: json['pageNumber'] as int?,
        knowledgeNodeIds:
            (json['knowledgeNodeIds'] as List? ?? []).cast<String>(),
        sections: (json['sections'] as List? ?? [])
            .map((s) =>
                NoteSection.fromJson(Map<String, dynamic>.from(s as Map)))
            .toList(),
        tags: (json['tags'] as List? ?? [])
            .map((t) => NoteTag.fromJson(Map<String, dynamic>.from(t as Map)))
            .toList(),
        attachments: (json['attachments'] as List? ?? [])
            .map((a) =>
                NoteAttachment.fromJson(Map<String, dynamic>.from(a as Map)))
            .toList(),
        bookmarks: (json['bookmarks'] as List? ?? [])
            .map((b) =>
                NoteBookmark.fromJson(Map<String, dynamic>.from(b as Map)))
            .toList(),
        versions: (json['versions'] as List? ?? [])
            .map((v) =>
                NoteVersion.fromJson(Map<String, dynamic>.from(v as Map)))
            .toList(),
        comments: (json['comments'] as List? ?? [])
            .map((c) =>
                NoteComment.fromJson(Map<String, dynamic>.from(c as Map)))
            .toList(),
        references: (json['references'] as List? ?? [])
            .map((r) =>
                NoteReference.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList(),
        highlights: (json['highlights'] as List? ?? [])
            .map((h) => Highlight.fromJson(Map<String, dynamic>.from(h as Map)))
            .toList(),
        annotations: (json['annotations'] as List? ?? [])
            .map(
                (a) => Annotation.fromJson(Map<String, dynamic>.from(a as Map)))
            .toList(),
        summary: json['summary'] != null
            ? NoteSummary.fromJson(
                Map<String, dynamic>.from(json['summary'] as Map))
            : null,
        isPinned: json['isPinned'] as bool? ?? false,
        isArchived: json['isArchived'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmartNote &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          content == other.content &&
          type == other.type &&
          contentId == other.contentId &&
          collectionId == other.collectionId &&
          timestampSeconds == other.timestampSeconds &&
          pageNumber == other.pageNumber &&
          isPinned == other.isPinned &&
          isArchived == other.isArchived &&
          summary == other.summary &&
          _listEquals(knowledgeNodeIds, other.knowledgeNodeIds) &&
          _listEquals(sections, other.sections) &&
          _listEquals(tags, other.tags) &&
          _listEquals(attachments, other.attachments) &&
          _listEquals(bookmarks, other.bookmarks) &&
          _listEquals(versions, other.versions) &&
          _listEquals(comments, other.comments) &&
          _listEquals(references, other.references) &&
          _listEquals(highlights, other.highlights) &&
          _listEquals(annotations, other.annotations);

  @override
  int get hashCode => Object.hashAll([
        id,
        title,
        content,
        type,
        contentId,
        collectionId,
        timestampSeconds,
        pageNumber,
        isPinned,
        isArchived,
        summary,
        Object.hashAll(knowledgeNodeIds),
        Object.hashAll(sections),
        Object.hashAll(tags),
        Object.hashAll(attachments),
        Object.hashAll(bookmarks),
        Object.hashAll(versions),
        Object.hashAll(comments),
        Object.hashAll(references),
        Object.hashAll(highlights),
        Object.hashAll(annotations),
      ]);
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
