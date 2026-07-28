import '../../models/knowledge_object.dart';
import '../models/generated_learning_assets.dart';

/// Revision Engine producing One Page Notes, Last Minute Notes, and Exam Checklists.
class RevisionEngine {
  /// Generates [GeneratedRevisionNotes] from a [KnowledgeObject].
  GeneratedRevisionNotes generate(KnowledgeObject obj) {
    final title = obj.title;
    final conceptList =
        obj.concepts.map((c) => '• ${c.name}: ${c.description}').join('\n');
    final termsList =
        obj.glossary.map((g) => '• ${g.term}: ${g.definition}').join('\n');

    final onePageNotes = '''
==================================================
ONE PAGE NOTES: $title
==================================================
Source Document: ${obj.source} | Language: ${obj.language} | Est Time: ${obj.estimatedReadingTime} min

KEY CONCEPTS & DEFINITIONS:
$conceptList

GLOSSARY & TERMINOLOGY:
$termsList

HIGH YIELD SUMMARY:
${obj.keywords.join(', ')}
==================================================
''';

    final lastMinuteNotes = '''
⚡ LAST MINUTE CHEAT SHEET: $title
• Core Theme: $title
• Must Remember: ${obj.keywords.take(4).join(', ')}
• Top Terms: ${obj.glossary.take(3).map((g) => g.term).join(' | ')}
''';

    final examNotes = '''
📝 EXAM NOTES & MAINS POINTERS ($title):
1. Introduction: Define $title and state constitutional/domain scope.
2. Core Features: ${obj.concepts.take(3).map((c) => c.name).join(', ')}.
3. Landmark Precedents / Acts: ${obj.concepts.where((c) => c.type.name == 'act' || c.type.name == 'article').map((c) => c.name).join(', ')}.
4. Conclusion: Summarize legal and administrative impact.
''';

    final quickRevisionChecklist = [
      'Understand definition of $title',
      'Recall key concepts: ${obj.concepts.take(3).map((c) => c.name).join(', ')}',
      'Review glossary terms: ${obj.glossary.take(2).map((g) => g.term).join(', ')}',
      'Solve practice questions & flashcards for $title',
    ];

    return GeneratedRevisionNotes(
      sourceKnowledgeObjectId: obj.id,
      onePageNotes: onePageNotes.trim(),
      lastMinuteNotes: lastMinuteNotes.trim(),
      examNotes: examNotes.trim(),
      quickRevisionChecklist: quickRevisionChecklist,
    );
  }
}
