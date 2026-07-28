import 'package:meta/meta.dart';
import 'lesson.dart';

/// Immutable domain model representing a course chapter containing multiple lessons.
@immutable
class Chapter {
  final String id;
  final String moduleId;
  final String title;
  final String description;
  final List<Lesson> lessons;
  final int durationMinutes;
  final bool isCompleted;

  Chapter({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.description,
    required List<Lesson> lessons,
    required this.durationMinutes,
    this.isCompleted = false,
  }) : lessons = List<Lesson>.unmodifiable(lessons);

  Chapter copyWith({
    String? id,
    String? moduleId,
    String? title,
    String? description,
    List<Lesson>? lessons,
    int? durationMinutes,
    bool? isCompleted,
  }) {
    return Chapter(
      id: id ?? this.id,
      moduleId: moduleId ?? this.moduleId,
      title: title ?? this.title,
      description: description ?? this.description,
      lessons: lessons ?? this.lessons,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Chapter &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          moduleId == other.moduleId &&
          title == other.title &&
          description == other.description &&
          durationMinutes == other.durationMinutes &&
          isCompleted == other.isCompleted &&
          _listEquals(lessons, other.lessons);

  @override
  int get hashCode => Object.hash(
        id,
        moduleId,
        title,
        description,
        durationMinutes,
        isCompleted,
        Object.hashAll(lessons),
      );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
