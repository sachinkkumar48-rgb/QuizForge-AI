import 'package:meta/meta.dart';
import '../domain/enums/knowledge_object_type.dart';
import '../domain/enums/relationship_type.dart';
import '../filters/knowledge_filter.dart';

/// Supported query modes for Universal Knowledge Search.
enum KnowledgeQueryType {
  exactMatch,
  prefixSearch,
  fuzzySearch,
  phraseSearch,
  booleanSearch,
  tagSearch,
  relationshipSearch,
  crossPackageSearch,
  filteredSearch,
}

/// Query specification container defining query parameters and execution options.
@immutable
class KnowledgeQuery {
  final String rawQuery;
  final KnowledgeQueryType queryType;
  final KnowledgeFilter filter;
  final KnowledgeObjectType? targetType;
  final String? targetTag;
  final RelationshipType? relationshipType;
  final String? relationshipTargetId;
  final double minScore;
  final int limit;
  final int offset;

  const KnowledgeQuery({
    this.rawQuery = '',
    this.queryType = KnowledgeQueryType.crossPackageSearch,
    this.filter = const KnowledgeFilter(),
    this.targetType,
    this.targetTag,
    this.relationshipType,
    this.relationshipTargetId,
    this.minScore = 0.05,
    this.limit = 50,
    this.offset = 0,
  });
}
