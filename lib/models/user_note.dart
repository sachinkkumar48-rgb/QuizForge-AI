class UserNote {
  final String noteId;
  final String questionId;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;

  UserNote({
    required this.noteId,
    required this.questionId,
    this.title = '',
    required this.content,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.tags = const [],
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  UserNote copyWith({
    String? noteId,
    String? questionId,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
  }) {
    return UserNote(
      noteId: noteId ?? this.noteId,
      questionId: questionId ?? this.questionId,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      tags: tags ?? this.tags,
    );
  }

  factory UserNote.fromJson(Map<String, dynamic> json) {
    return UserNote(
      noteId: json['noteId'] as String? ?? '',
      questionId: json['questionId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'noteId': noteId,
      'questionId': questionId,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'tags': tags,
    };
  }
}
