import 'package:meta/meta.dart';

/// Immutable metadata describing a TITAN module's specification and identity.
@immutable
class TitanModuleInfo {
  final String name;
  final String version;
  final String description;
  final String author;
  final List<String> dependencies;

  TitanModuleInfo({
    required this.name,
    required this.version,
    required this.description,
    required this.author,
    List<String>? dependencies,
  }) : dependencies = List<String>.unmodifiable(dependencies ?? const []);

  const TitanModuleInfo.constInfo({
    required this.name,
    required this.version,
    required this.description,
    required this.author,
    required this.dependencies,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TitanModuleInfo || runtimeType != other.runtimeType) {
      return false;
    }
    if (name != other.name ||
        version != other.version ||
        description != other.description ||
        author != other.author) {
      return false;
    }
    if (dependencies.length != other.dependencies.length) {
      return false;
    }
    for (var i = 0; i < dependencies.length; i++) {
      if (dependencies[i] != other.dependencies[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      name.hashCode ^
      version.hashCode ^
      description.hashCode ^
      author.hashCode ^
      dependencies.hashCode;

  @override
  String toString() => 'TitanModuleInfo($name v$version by $author)';
}
