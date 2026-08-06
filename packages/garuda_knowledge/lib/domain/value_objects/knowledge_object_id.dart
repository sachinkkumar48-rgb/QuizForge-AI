import 'package:meta/meta.dart';

/// Immutable Value Object representing a unique Knowledge Object Identifier.
@immutable
class KnowledgeObjectId {
  final String value;

  const KnowledgeObjectId(this.value)
      : assert(value.length > 0, 'KnowledgeObjectId cannot be empty');

  factory KnowledgeObjectId.fromJson(String json) => KnowledgeObjectId(json);

  String toJson() => value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KnowledgeObjectId &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
