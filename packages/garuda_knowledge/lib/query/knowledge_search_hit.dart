import 'package:meta/meta.dart';
import '../domain/entities/knowledge_object.dart';

/// Single search match entry containing score breakdown and matched fields.
@immutable
class KnowledgeSearchHit {
  final KnowledgeObject object;
  final double score;
  final Set<String> matchedFields;
  final Map<String, double> scoreBreakdown;
  final String? snippet;

  const KnowledgeSearchHit({
    required this.object,
    required this.score,
    this.matchedFields = const {},
    this.scoreBreakdown = const {},
    this.snippet,
  });
}
