import 'package:meta/meta.dart';

/// Immutable domain model representing a single lesson within a chapter.
@immutable
class Lesson {
  final String id;
  final String chapterId;
  final String title;
  final String description;
  final int durationMinutes;
  final String? videoUrl;
  final bool isCompleted;
  final String type; // 'video', 'article', 'quiz', 'interactive'
  final String content;
  final int order;
  final String topic;

  const Lesson({
    required this.id,
    required this.chapterId,
    required this.title,
    required this.description,
    required this.durationMinutes,
    this.videoUrl,
    this.isCompleted = false,
    required this.type,
    required this.content,
    required this.order,
    required this.topic,
  });

  Lesson copyWith({
    String? id,
    String? chapterId,
    String? title,
    String? description,
    int? durationMinutes,
    String? videoUrl,
    bool? isCompleted,
    String? type,
    String? content,
    int? order,
    String? topic,
  }) {
    return Lesson(
      id: id ?? this.id,
      chapterId: chapterId ?? this.chapterId,
      title: title ?? this.title,
      description: description ?? this.description,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      videoUrl: videoUrl ?? this.videoUrl,
      isCompleted: isCompleted ?? this.isCompleted,
      type: type ?? this.type,
      content: content ?? this.content,
      order: order ?? this.order,
      topic: topic ?? this.topic,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Lesson &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          chapterId == other.chapterId &&
          title == other.title &&
          description == other.description &&
          durationMinutes == other.durationMinutes &&
          videoUrl == other.videoUrl &&
          isCompleted == other.isCompleted &&
          type == other.type &&
          content == other.content &&
          order == other.order &&
          topic == other.topic;

  @override
  int get hashCode => Object.hash(
        id,
        chapterId,
        title,
        description,
        durationMinutes,
        videoUrl,
        isCompleted,
        type,
        content,
        order,
        topic,
      );
}
