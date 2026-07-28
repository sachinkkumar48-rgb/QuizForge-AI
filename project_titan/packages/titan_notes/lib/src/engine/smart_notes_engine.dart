import '../models/notes_models.dart';

/// Pure Dart Smart Notes Engine providing intelligent merging, organization, deduplication,
/// summarization, keyword extraction, auto-tagging, AI enhancement, and timestamp linking.
class SmartNotesEngine {
  const SmartNotesEngine();

  /// Merges multiple notes into a single unified note document.
  SmartNote mergeNotes(List<SmartNote> notes, {required String newTitle}) {
    if (notes.isEmpty) {
      throw ArgumentError('Cannot merge an empty list of notes.');
    }

    final mergedContent =
        notes.map((n) => '### ${n.title}\n${n.content}').join('\n\n');
    final allSections = <NoteSection>[];
    final allTags = <NoteTag>[];
    final allNodeIds = <String>{};
    final allHighlights = <Highlight>[];
    final allAnnotations = <Annotation>[];

    for (final note in notes) {
      allSections.addAll(note.sections);
      for (final tag in note.tags) {
        if (!allTags
            .any((t) => t.label.toLowerCase() == tag.label.toLowerCase())) {
          allTags.add(tag);
        }
      }
      allNodeIds.addAll(note.knowledgeNodeIds);
      allHighlights.addAll(note.highlights);
      allAnnotations.addAll(note.annotations);
    }

    final now = DateTime.now();
    return SmartNote(
      id: 'merged_${now.millisecondsSinceEpoch}',
      title: newTitle,
      content: mergedContent,
      type: NoteType.manual,
      knowledgeNodeIds: allNodeIds.toList(),
      sections: allSections,
      tags: allTags,
      attachments: const [],
      bookmarks: const [],
      versions: [
        NoteVersion(
          versionNumber: 1,
          title: newTitle,
          content: mergedContent,
          author: 'SmartNotesEngine',
          createdAt: now,
        ),
      ],
      comments: const [],
      references: const [],
      highlights: allHighlights,
      annotations: allAnnotations,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Organizes a list of notes by subject or collection.
  Map<String, List<SmartNote>> organizeNotes(List<SmartNote> notes) {
    final map = <String, List<SmartNote>>{};
    for (final note in notes) {
      final key = note.collectionId ??
          (note.tags.isNotEmpty ? note.tags.first.label : 'General');
      map.putIfAbsent(key, () => []).add(note);
    }
    return map;
  }

  /// Deduplicates a list of notes based on title and content similarity.
  List<SmartNote> deduplicate(List<SmartNote> notes) {
    final result = <SmartNote>[];
    for (final note in notes) {
      final isDuplicate = result.any(
        (existing) =>
            existing.title.toLowerCase().trim() ==
                note.title.toLowerCase().trim() ||
            (existing.content.isNotEmpty && existing.content == note.content),
      );
      if (!isDuplicate) {
        result.add(note);
      }
    }
    return result;
  }

  /// Summarizes a smart note into an AI executive summary structure.
  NoteSummary summarize(SmartNote note) {
    final lines =
        note.content.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final overview =
        lines.isNotEmpty ? lines.first : 'No summary content available.';
    final keyTakeaways = lines.length > 1
        ? lines.sublist(1, lines.length > 4 ? 4 : lines.length)
        : <String>['Key concepts extracted from ${note.title}'];
    final upscRelevance = <String>[
      'Relevant for GS Paper preparation and Prelims statement verification.',
    ];

    return NoteSummary(
      overview: overview,
      keyTakeaways: keyTakeaways,
      upscRelevance: upscRelevance,
    );
  }

  /// Extracts key UPSC keywords from note content.
  List<String> keywordExtraction(SmartNote note) {
    final text = '${note.title} ${note.content}'.toLowerCase();
    final candidateKeywords = [
      'preamble',
      'constitution',
      'fundamental rights',
      'judiciary',
      'parliament',
      'governance',
      'polity',
      'economy',
      'history',
      'geography',
      'environment',
      'ethics',
    ];

    return candidateKeywords.where((kw) => text.contains(kw)).toList();
  }

  /// Auto-tags a note based on extracted keywords.
  List<NoteTag> autoTagging(SmartNote note) {
    final keywords = keywordExtraction(note);
    final existingLabels = note.tags.map((t) => t.label.toLowerCase()).toSet();
    final newTags = List<NoteTag>.from(note.tags);

    for (final kw in keywords) {
      if (!existingLabels.contains(kw)) {
        newTags.add(
          NoteTag(
            id: 'tag_${kw}_${DateTime.now().millisecondsSinceEpoch}',
            label: kw.toUpperCase(),
          ),
        );
      }
    }
    return newTags;
  }

  /// Enhances note content with structured formatting and AI improvements.
  SmartNote aiEnhancement(SmartNote note) {
    final enhancedContent = '## ${note.title}\n\n'
        '**AI Overview:** Key concepts for UPSC GS.\n\n'
        '${note.content}\n\n'
        '--- \n*AI Enhanced for revision.*';

    final summary = summarize(note);
    final autoTags = autoTagging(note);

    return note.copyWith(
      content: enhancedContent,
      summary: summary,
      tags: autoTags,
      type: NoteType.aiGenerated,
      updatedAt: DateTime.now(),
    );
  }

  /// Links a note to a specific video timestamp.
  SmartNote timestampLinking(SmartNote note, int timestampSeconds) {
    return note.copyWith(
      timestampSeconds: timestampSeconds,
      type: NoteType.timestamp,
      updatedAt: DateTime.now(),
    );
  }
}
