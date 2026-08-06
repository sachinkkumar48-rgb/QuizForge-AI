import 'package:garuda_knowledge/garuda_knowledge.dart';
import 'package:test/test.dart';

void main() {
  group('KnowledgeSuggestionEngine', () {
    late KnowledgeIndex index;
    late KnowledgeSuggestionEngine suggestionEngine;

    final art21 = KnowledgeObject(
      id: const KnowledgeObjectId('const-art-21'),
      type: KnowledgeObjectType.constitutionArticle,
      title: 'Fundamental Rights and Constitutional Remedies',
      content: 'Writs under Article 32 and Article 226',
      currentVersion: KnowledgeVersion(
        versionNumber: 1,
        commitMessage: 'Init',
        author: 'System',
        timestamp: DateTime.now(),
      ),
      metadata: KnowledgeMetadata(
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'System',
      ),
    );

    setUp(() {
      index = KnowledgeIndex();
      index.index(art21);
      suggestionEngine = KnowledgeSuggestionEngine(index: index);
    });

    test('Expands domain synonyms (e.g. fr -> fundamental rights)', () {
      final suggestions = suggestionEngine.suggest('fr');
      expect(suggestions.contains('fundamental rights') || suggestions.contains('part iii'), isTrue);
    });

    test('Provides did-you-mean spelling correction via edit distance', () {
      final suggestions = suggestionEngine.suggest('Fundamentl');
      expect(suggestions.contains('fundamental'), isTrue);
    });
  });
}
