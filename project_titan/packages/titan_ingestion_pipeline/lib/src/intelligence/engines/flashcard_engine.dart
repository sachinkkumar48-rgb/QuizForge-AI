import '../../models/knowledge_object.dart';
import '../models/generated_learning_assets.dart';

/// Flashcard Engine producing flashcards with hints and revision priorities.
class FlashcardEngine {
  /// Generates a list of [GeneratedFlashcard] from a [KnowledgeObject].
  List<GeneratedFlashcard> generate(KnowledgeObject obj) {
    final flashcards = <GeneratedFlashcard>[];
    var cardIdCounter = 1;

    // 1. Generate cards from Concepts
    for (final concept in obj.concepts) {
      flashcards.add(GeneratedFlashcard(
        id: 'fc_${obj.id}_${cardIdCounter++}',
        sourceKnowledgeObjectId: obj.id,
        front: 'What is ${concept.name}?',
        back: concept.description,
        hint: 'Concept Type: ${concept.type.name}',
        difficulty: concept.type.name == 'definition' ? 'Easy' : 'Medium',
        revisionPriority: 'High',
      ));
    }

    // 2. Generate cards from Glossary Items
    for (final item in obj.glossary) {
      flashcards.add(GeneratedFlashcard(
        id: 'fc_${obj.id}_${cardIdCounter++}',
        sourceKnowledgeObjectId: obj.id,
        front: 'Define: ${item.term}',
        back: item.definition,
        hint: 'Domain: ${item.domain}',
        difficulty: 'Easy',
        revisionPriority: 'Medium',
      ));
    }

    // Fallback card if concepts & glossary were empty
    if (flashcards.isEmpty) {
      flashcards.add(GeneratedFlashcard(
        id: 'fc_${obj.id}_1',
        sourceKnowledgeObjectId: obj.id,
        front: 'Core Topic of ${obj.title}',
        back: obj.title,
        hint: 'Title of the lesson',
        difficulty: 'Easy',
        revisionPriority: 'Medium',
      ));
    }

    return flashcards;
  }
}
