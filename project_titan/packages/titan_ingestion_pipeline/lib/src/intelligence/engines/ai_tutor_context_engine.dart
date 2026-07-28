import '../../models/knowledge_object.dart';
import '../models/generated_learning_assets.dart';

/// AI Tutor Context Engine for preparing AI Tutor system context, FAQs, and misconceptions.
class AITutorContextEngine {
  /// Generates [AITutorContextAsset] from a [KnowledgeObject].
  AITutorContextAsset generate(KnowledgeObject obj) {
    final title = obj.title;
    final conceptSummary =
        obj.concepts.map((c) => '${c.name}: ${c.description}').join('; ');

    final contextPrompt = '''
You are the TITAN AI Mentor specializing in $title.
Knowledge Base Context: $title.
Key Concepts: $conceptSummary.
Source: ${obj.source}.
Instruction: Answer learner questions clearly, using structured Markdown, bullet points, and real-world UPSC examples. Provide hints rather than raw answers when guiding practice.
''';

    final faqs = <String, String>{
      'What is the core purpose of $title?':
          '$title provides the primary framework for governance and legal standards in its domain.',
      'How does $title relate to previous constitutional acts?':
          'It builds upon preceding legislation and incorporates modern precedents.',
      'What are the key terms to remember for $title?': obj.keywords.join(', '),
    };

    final misconceptions = [
      'Misconception: $title applies without any exceptions. (Fact: Subject to reasonable restrictions under law).',
      'Misconception: $title was introduced recently. (Fact: Has historical roots and constitutional precedents).',
    ];

    final analogies = [
      'Analogy: Think of $title as the blueprint of a building—it defines the structural rules and load-bearing walls.',
      'Analogy: $title acts like a referee in a sports match, ensuring all parties adhere to fair play.',
    ];

    final followUpQuestions = [
      'Can you explain the main difference between key concepts in $title?',
      'How would you apply $title to a recent landmark judgment scenario?',
      'What are the 3 key takeaways you should remember for the exam?',
    ];

    return AITutorContextAsset(
      sourceKnowledgeObjectId: obj.id,
      contextPrompt: contextPrompt.trim(),
      faqs: faqs,
      misconceptions: misconceptions,
      analogies: analogies,
      followUpQuestions: followUpQuestions,
    );
  }
}
