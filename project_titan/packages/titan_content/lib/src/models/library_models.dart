import 'package:meta/meta.dart';

/// Immutable model representing a bookmark in a digital library document.
@immutable
class Bookmark {
  final String id;
  final String documentId;
  final int pageNumber;
  final String label;
  final DateTime createdAt;

  const Bookmark({
    required this.id,
    required this.documentId,
    required this.pageNumber,
    required this.label,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Bookmark &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          documentId == other.documentId &&
          pageNumber == other.pageNumber &&
          label == other.label &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(id, documentId, pageNumber, label, createdAt);
}

/// Immutable reading progress model for tracking document completion state.
@immutable
class ReadingProgress {
  final int currentPage;
  final int totalPages;
  final double completionPercentage;
  final DateTime lastReadAt;

  const ReadingProgress({
    required this.currentPage,
    required this.totalPages,
    required this.completionPercentage,
    required this.lastReadAt,
  });

  factory ReadingProgress.initial(int totalPages) {
    return ReadingProgress(
      currentPage: 1,
      totalPages: totalPages > 0 ? totalPages : 1,
      completionPercentage: 0.0,
      lastReadAt: DateTime.now(),
    );
  }

  ReadingProgress copyWith({
    int? currentPage,
    int? totalPages,
    DateTime? lastReadAt,
  }) {
    final updatedCurrent = currentPage ?? this.currentPage;
    final updatedTotal = totalPages ?? this.totalPages;
    final percentage = updatedTotal > 0
        ? ((updatedCurrent / updatedTotal) * 100.0).clamp(0.0, 100.0)
        : 0.0;

    return ReadingProgress(
      currentPage: updatedCurrent,
      totalPages: updatedTotal,
      completionPercentage: double.parse(percentage.toStringAsFixed(1)),
      lastReadAt: lastReadAt ?? DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadingProgress &&
          runtimeType == other.runtimeType &&
          currentPage == other.currentPage &&
          totalPages == other.totalPages &&
          completionPercentage == other.completionPercentage &&
          lastReadAt == other.lastReadAt;

  @override
  int get hashCode =>
      Object.hash(currentPage, totalPages, completionPercentage, lastReadAt);
}

/// Placeholder model for text highlights in PDF documents.
@immutable
class HighlightAnnotation {
  final String id;
  final String documentId;
  final int pageNumber;
  final String selectedText;
  final String colorHex;
  final DateTime createdAt;

  const HighlightAnnotation({
    required this.id,
    required this.documentId,
    required this.pageNumber,
    required this.selectedText,
    required this.colorHex,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HighlightAnnotation &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          documentId == other.documentId &&
          pageNumber == other.pageNumber &&
          selectedText == other.selectedText &&
          colorHex == other.colorHex &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
      id, documentId, pageNumber, selectedText, colorHex, createdAt);
}

/// Placeholder model for notes added to PDF documents.
@immutable
class NoteAnnotation {
  final String id;
  final String documentId;
  final int pageNumber;
  final String noteText;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NoteAnnotation({
    required this.id,
    required this.documentId,
    required this.pageNumber,
    required this.noteText,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteAnnotation &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          documentId == other.documentId &&
          pageNumber == other.pageNumber &&
          noteText == other.noteText &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      Object.hash(id, documentId, pageNumber, noteText, createdAt, updatedAt);
}

/// Placeholder model for AI generated summaries and annotations.
@immutable
class AiAnnotation {
  final String id;
  final String documentId;
  final int pageNumber;
  final String prompt;
  final String aiSummary;
  final List<String> keyTakeaways;
  final List<String> tags;

  AiAnnotation({
    required this.id,
    required this.documentId,
    required this.pageNumber,
    required this.prompt,
    required this.aiSummary,
    required List<String> keyTakeaways,
    required List<String> tags,
  })  : keyTakeaways = List<String>.unmodifiable(keyTakeaways),
        tags = List<String>.unmodifiable(tags);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiAnnotation &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          documentId == other.documentId &&
          pageNumber == other.pageNumber &&
          prompt == other.prompt &&
          aiSummary == other.aiSummary &&
          _listEquals(keyTakeaways, other.keyTakeaways) &&
          _listEquals(tags, other.tags);

  @override
  int get hashCode => Object.hash(
        id,
        documentId,
        pageNumber,
        prompt,
        aiSummary,
        Object.hashAll(keyTakeaways),
        Object.hashAll(tags),
      );
}

/// Immutable model representing a folder in the Digital Library.
@immutable
class LibraryFolder {
  final String id;
  final String name;
  final String iconName;
  final String category;
  final List<String> documentIds;
  final DateTime createdAt;

  LibraryFolder({
    required this.id,
    required this.name,
    required this.iconName,
    required this.category,
    required List<String> documentIds,
    required this.createdAt,
  }) : documentIds = List<String>.unmodifiable(documentIds);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LibraryFolder &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          iconName == other.iconName &&
          category == other.category &&
          createdAt == other.createdAt &&
          _listEquals(documentIds, other.documentIds);

  @override
  int get hashCode => Object.hash(
        id,
        name,
        iconName,
        category,
        createdAt,
        Object.hashAll(documentIds),
      );
}

/// Immutable domain model representing a PDF document in the Digital Library.
@immutable
class LibraryDocument {
  final String id;
  final String title;
  final String filePath;
  final int fileSize;
  final int pageCount;
  final String category;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime lastReadAt;
  final ReadingProgress progress;
  final List<Bookmark> bookmarks;
  final List<HighlightAnnotation> highlights;
  final List<NoteAnnotation> notes;
  final List<AiAnnotation> aiAnnotations;
  final List<String> tags;

  LibraryDocument({
    required this.id,
    required this.title,
    required this.filePath,
    required this.fileSize,
    required this.pageCount,
    required this.category,
    this.isFavorite = false,
    required this.createdAt,
    required this.lastReadAt,
    required this.progress,
    List<Bookmark>? bookmarks,
    List<HighlightAnnotation>? highlights,
    List<NoteAnnotation>? notes,
    List<AiAnnotation>? aiAnnotations,
    List<String>? tags,
  })  : bookmarks = List<Bookmark>.unmodifiable(bookmarks ?? const []),
        highlights =
            List<HighlightAnnotation>.unmodifiable(highlights ?? const []),
        notes = List<NoteAnnotation>.unmodifiable(notes ?? const []),
        aiAnnotations =
            List<AiAnnotation>.unmodifiable(aiAnnotations ?? const []),
        tags = List<String>.unmodifiable(tags ?? const []);

  LibraryDocument copyWith({
    String? title,
    String? category,
    bool? isFavorite,
    DateTime? lastReadAt,
    ReadingProgress? progress,
    List<Bookmark>? bookmarks,
    List<HighlightAnnotation>? highlights,
    List<NoteAnnotation>? notes,
    List<AiAnnotation>? aiAnnotations,
    List<String>? tags,
  }) {
    return LibraryDocument(
      id: id,
      title: title ?? this.title,
      filePath: filePath,
      fileSize: fileSize,
      pageCount: pageCount,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      progress: progress ?? this.progress,
      bookmarks: bookmarks ?? this.bookmarks,
      highlights: highlights ?? this.highlights,
      notes: notes ?? this.notes,
      aiAnnotations: aiAnnotations ?? this.aiAnnotations,
      tags: tags ?? this.tags,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LibraryDocument &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          filePath == other.filePath &&
          fileSize == other.fileSize &&
          pageCount == other.pageCount &&
          category == other.category &&
          isFavorite == other.isFavorite &&
          createdAt == other.createdAt &&
          lastReadAt == other.lastReadAt &&
          progress == other.progress &&
          _listEquals(bookmarks, other.bookmarks) &&
          _listEquals(highlights, other.highlights) &&
          _listEquals(notes, other.notes) &&
          _listEquals(aiAnnotations, other.aiAnnotations) &&
          _listEquals(tags, other.tags);

  @override
  int get hashCode => Object.hash(
        id,
        title,
        filePath,
        fileSize,
        pageCount,
        category,
        isFavorite,
        createdAt,
        lastReadAt,
        progress,
        Object.hashAll(bookmarks),
        Object.hashAll(highlights),
        Object.hashAll(notes),
        Object.hashAll(aiAnnotations),
        Object.hashAll(tags),
      );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
