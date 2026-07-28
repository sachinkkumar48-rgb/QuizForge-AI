import '../../models/knowledge_object.dart';
import '../models/generated_learning_assets.dart';

/// Mind Map Engine producing hierarchical graph structures from KnowledgeObjects.
class MindMapEngine {
  /// Generates a [MindMapStructure] graph from a [KnowledgeObject].
  MindMapStructure generate(KnowledgeObject obj) {
    final rootId = 'node_root_${obj.id}';
    final rootNode = MindMapNode(
      id: rootId,
      label: obj.title,
      level: 0,
    );

    final nodes = <MindMapNode>[rootNode];
    final branches = <String>[];
    final dependencies = <String, List<String>>{};

    var nodeCounter = 1;

    // 1. Add Concept Branches (Level 1)
    final conceptBranchIds = <String>[];
    for (final concept in obj.concepts) {
      final nodeId = 'node_mm_${obj.id}_${nodeCounter++}';
      branches.add(concept.name);
      conceptBranchIds.add(nodeId);
      nodes.add(MindMapNode(
        id: nodeId,
        label: concept.name,
        level: 1,
        parentId: rootId,
      ));
    }
    dependencies[rootId] = conceptBranchIds;

    // 2. Add Content Block Sub-branches (Level 2)
    for (final block in obj.contentBlocks) {
      final json = block.toJson();
      if (json['type'] == 'heading') {
        final nodeId = 'node_mm_${obj.id}_${nodeCounter++}';
        final text = json['text'] as String? ?? 'Section';
        branches.add(text);
        nodes.add(MindMapNode(
          id: nodeId,
          label: text,
          level: 2,
          parentId: rootId,
        ));
      }
    }

    return MindMapStructure(
      id: 'mm_${obj.id}',
      sourceKnowledgeObjectId: obj.id,
      title: obj.title,
      rootNode: rootNode,
      nodes: nodes,
      branches: branches,
      dependencies: dependencies,
    );
  }
}
