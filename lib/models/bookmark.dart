class Bookmark {
  final String bookmarkId;
  final String questionId;
  final DateTime createdAt;
  final String category; // High Priority, Confusing, Must Review
  final String? noteSnippet;

  Bookmark({
    required this.bookmarkId,
    required this.questionId,
    DateTime? createdAt,
    this.category = 'General',
    this.noteSnippet,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      bookmarkId: json['bookmarkId'] as String? ?? '',
      questionId: json['questionId'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      category: json['category'] as String? ?? 'General',
      noteSnippet: json['noteSnippet'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookmarkId': bookmarkId,
      'questionId': questionId,
      'createdAt': createdAt.toIso8601String(),
      'category': category,
      if (noteSnippet != null) 'noteSnippet': noteSnippet,
    };
  }
}
