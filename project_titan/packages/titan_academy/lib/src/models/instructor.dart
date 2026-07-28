import 'package:meta/meta.dart';

/// Immutable domain model representing a course instructor.
@immutable
class Instructor {
  final String id;
  final String name;
  final String title;
  final String bio;
  final String avatarUrl;
  final List<String> qualifications;
  final double rating;
  final int studentCount;

  Instructor({
    required this.id,
    required this.name,
    required this.title,
    required this.bio,
    required this.avatarUrl,
    required List<String> qualifications,
    required this.rating,
    required this.studentCount,
  }) : qualifications = List<String>.unmodifiable(qualifications);

  Instructor copyWith({
    String? id,
    String? name,
    String? title,
    String? bio,
    String? avatarUrl,
    List<String>? qualifications,
    double? rating,
    int? studentCount,
  }) {
    return Instructor(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      qualifications: qualifications ?? this.qualifications,
      rating: rating ?? this.rating,
      studentCount: studentCount ?? this.studentCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Instructor &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          title == other.title &&
          bio == other.bio &&
          avatarUrl == other.avatarUrl &&
          rating == other.rating &&
          studentCount == other.studentCount &&
          _listEquals(qualifications, other.qualifications);

  @override
  int get hashCode => Object.hash(
        id,
        name,
        title,
        bio,
        avatarUrl,
        rating,
        studentCount,
        Object.hashAll(qualifications),
      );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
