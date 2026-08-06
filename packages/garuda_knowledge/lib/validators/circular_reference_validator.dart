import '../domain/entities/knowledge_object.dart';
import 'validation_result.dart';

class CircularReferenceValidator {
  ValidationResult validate(List<KnowledgeObject> objects) {
    final issues = <ValidationIssue>[];
    final adj = <String, List<String>>{};

    for (final obj in objects) {
      adj[obj.id.value] = obj.relationships.map((r) => r.targetId.value).toList();
    }

    final visited = <String>{};
    final recStack = <String>{};

    bool dfs(String node, List<String> path) {
      visited.add(node);
      recStack.add(node);
      path.add(node);

      final neighbors = adj[node] ?? [];
      for (final nxt in neighbors) {
        if (!visited.contains(nxt)) {
          if (dfs(nxt, path)) return true;
        } else if (recStack.contains(nxt)) {
          final cyclePath = [...path, nxt].join(' -> ');
          issues.add(ValidationIssue(
            code: 'CIRCULAR_REFERENCE',
            message: 'Circular relationship cycle detected: $cyclePath',
            objectId: node,
            severity: ValidationSeverity.error,
          ));
          return true;
        }
      }

      recStack.remove(node);
      path.removeLast();
      return false;
    }

    for (final node in adj.keys) {
      if (!visited.contains(node)) {
        dfs(node, []);
      }
    }

    return ValidationResult(issues: issues);
  }
}
