/// JSON case renderer (TITAN-KO-015.0 P8).
///
/// JSON export reuses the repository's canonical serialization —
/// `CaseKnowledgeObject.toJson()` — verbatim. There is deliberately no second
/// competing serialization model: the canonical map already preserves every
/// case field, evidence metadata, structured precedent relationships, and UPSC
/// intelligence, and the renderer adds no fabricated fields and drops no data.
///
/// Output is deterministic: map insertion order follows the canonical
/// serialization, and the pretty-printer uses a fixed 2-space indent.
library;

import 'dart:convert';

import '../domain/entities/case_knowledge_object.dart';

class JsonCaseRenderer {
  /// The canonical case map — identical to `CaseKnowledgeObject.toJson()`.
  static Map<String, dynamic> renderMap(CaseKnowledgeObject c) => c.toJson();

  /// A deterministic, UTF-8-safe JSON string of the canonical case map.
  static String renderString(CaseKnowledgeObject c) =>
      const JsonEncoder.withIndent('  ').convert(c.toJson());

  /// A deterministic JSON string for the full corpus (an array of canonical
  /// case maps, in the given order).
  static String renderCorpusString(List<CaseKnowledgeObject> cases) =>
      const JsonEncoder.withIndent('  ')
          .convert(cases.map((c) => c.toJson()).toList());
}
