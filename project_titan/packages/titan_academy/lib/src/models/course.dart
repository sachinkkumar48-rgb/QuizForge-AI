import 'package:meta/meta.dart';
import 'instructor.dart';
import 'module.dart';

/// Immutable domain model representing a full academic course.
@immutable
class Course {
  final String id;
  final String title;
  final String description;
  final String subject;
  final String level; // 'Beginner', 'Intermediate', 'Advanced'
  final Instructor instructor;
  final List<Module> modules;
  final double estimatedHours;
  final double rating;
  final int enrolledCount;
  final String imageUrl;
  final List<String> tags;
  final String? knowledgeNodeId;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.level,
    required this.instructor,
    required List<Module> modules,
    required this.estimatedHours,
    required this.rating,
    required this.enrolledCount,
    required this.imageUrl,
    required List<String> tags,
    this.knowledgeNodeId,
  })  : modules = List<Module>.unmodifiable(modules),
        tags = List<String>.unmodifiable(tags);

  Course copyWith({
    String? id,
    String? title,
    String? description,
    String? subject,
    String? level,
    Instructor? instructor,
    List<Module>? modules,
    double? estimatedHours,
    double? rating,
    int? enrolledCount,
    String? imageUrl,
    List<String>? tags,
    String? knowledgeNodeId,
  }) {
    return Course(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      subject: subject ?? this.subject,
      level: level ?? this.level,
      instructor: instructor ?? this.instructor,
      modules: modules ?? this.modules,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      rating: rating ?? this.rating,
      enrolledCount: enrolledCount ?? this.enrolledCount,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      knowledgeNodeId: knowledgeNodeId ?? this.knowledgeNodeId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Course &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          subject == other.subject &&
          level == other.level &&
          instructor == other.instructor &&
          estimatedHours == other.estimatedHours &&
          rating == other.rating &&
          enrolledCount == other.enrolledCount &&
          imageUrl == other.imageUrl &&
          knowledgeNodeId == other.knowledgeNodeId &&
          _listEquals(modules, other.modules) &&
          _listEquals(tags, other.tags);

  @override
  int get hashCode => Object.hash(
        id,
        title,
        description,
        subject,
        level,
        instructor,
        estimatedHours,
        rating,
        enrolledCount,
        imageUrl,
        knowledgeNodeId,
        Object.hashAll(modules),
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
