import 'package:meta/meta.dart';

/// Immutable model representing a template for rendering structured AI prompts.
@immutable
class PromptTemplate {
  final String id;
  final String name;
  final String template;
  final String version;

  const PromptTemplate({
    required this.id,
    required this.name,
    required this.template,
    required this.version,
  });

  /// Renders the prompt by replacing placeholders (e.g. `{{variable}}` or `{variable}`) with stringified values.
  String render(Map<String, Object?> variables) {
    var result = template;
    for (final entry in variables.entries) {
      final key = entry.key;
      final val = entry.value?.toString() ?? '';
      result = result.replaceAll('{{$key}}', val).replaceAll('{$key}', val);
    }
    return result;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PromptTemplate &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          template == other.template &&
          version == other.version;

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ template.hashCode ^ version.hashCode;

  @override
  String toString() => 'PromptTemplate($id v$version - $name)';
}
