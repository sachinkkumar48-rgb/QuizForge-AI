import '../domain/enums/knowledge_object_type.dart';
import '../domain/enums/relationship_type.dart';
import '../filters/knowledge_filter.dart';
import 'knowledge_query.dart';

/// Fluent Builder pattern for constructing KnowledgeQuery objects cleanly.
class KnowledgeQueryBuilder {
  String _rawQuery = '';
  KnowledgeQueryType _queryType = KnowledgeQueryType.crossPackageSearch;
  KnowledgeFilter _filter = const KnowledgeFilter();
  KnowledgeObjectType? _targetType;
  String? _targetTag;
  RelationshipType? _relationshipType;
  String? _relationshipTargetId;
  double _minScore = 0.05;
  int _limit = 50;
  int _offset = 0;

  KnowledgeQueryBuilder query(String q) {
    _rawQuery = q;
    return this;
  }

  KnowledgeQueryBuilder type(KnowledgeQueryType t) {
    _queryType = t;
    return this;
  }

  KnowledgeQueryBuilder filter(KnowledgeFilter f) {
    _filter = f;
    return this;
  }

  KnowledgeQueryBuilder targetObjectType(KnowledgeObjectType objectType) {
    _targetType = objectType;
    return this;
  }

  KnowledgeQueryBuilder tag(String tag) {
    _targetTag = tag;
    return this;
  }

  KnowledgeQueryBuilder relationship(RelationshipType relType, {String? targetId}) {
    _relationshipType = relType;
    _relationshipTargetId = targetId;
    return this;
  }

  KnowledgeQueryBuilder minScore(double score) {
    _minScore = score;
    return this;
  }

  KnowledgeQueryBuilder limit(int l) {
    _limit = l;
    return this;
  }

  KnowledgeQueryBuilder offset(int o) {
    _offset = o;
    return this;
  }

  KnowledgeQuery build() {
    return KnowledgeQuery(
      rawQuery: _rawQuery,
      queryType: _queryType,
      filter: _filter,
      targetType: _targetType,
      targetTag: _targetTag,
      relationshipType: _relationshipType,
      relationshipTargetId: _relationshipTargetId,
      minScore: _minScore,
      limit: _limit,
      offset: _offset,
    );
  }
}
