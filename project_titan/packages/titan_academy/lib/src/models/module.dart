import 'package:meta/meta.dart';
import 'chapter.dart';

/// Immutable domain model representing a course module containing chapters.
@immutable
class Module {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final List<Chapter> chapters;
  final int durationMinutes;
  final bool isCompleted;

  Module({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required List<Chapter> chapters,
    required this.durationMinutes,
    this.isCompleted = false,
  }) : chapters = List<Chapter>.unmodifiable(chapters);

  Module copyWith({
    String? id,
    String? courseId,
    String? title,
    String? description,
    List<Chapter>? chapters,
    int? durationMinutes,
    bool? isCompleted,
  }) {
    return Module(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      description: description ?? this.description,
      chapters: chapters ?? this.chapters,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Module &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          courseId == other.courseId &&
          title == other.title &&
          description == other.description &&
          durationMinutes == other.durationMinutes &&
          isCompleted == other.isCompleted &&
          _listEquals(chapters, other.chapters);

  @override
  int get hashCode => Object.hash(
        id,
        courseId,
        title,
        description,
        durationMinutes,
        isCompleted,
        Object.hashAll(chapters),
      );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
