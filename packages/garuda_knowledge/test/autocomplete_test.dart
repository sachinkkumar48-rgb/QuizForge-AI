import 'package:garuda_knowledge/garuda_knowledge.dart';
import 'package:test/test.dart';

void main() {
  group('KnowledgeAutocomplete Engine', () {
    late KnowledgeIndex index;
    late KnowledgeAutocomplete autocomplete;

    final art21 = KnowledgeObject(
      id: const KnowledgeObjectId('const-art-21'),
      type: KnowledgeObjectType.constitutionArticle,
      title: 'Article 21: Protection of Life',
      content: 'Personal liberty',
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
        customAttributes: {
          'article_number': '21',
          'case_name': 'Maneka Gandhi v. Union of India',
          'act': 'Constitution of India',
          'aliases': ['Right to Life'],
        },
      ),
    );

    setUp(() {
      index = KnowledgeIndex();
      index.index(art21);
      autocomplete = KnowledgeAutocomplete(index: index);
    });

    test('Autocompletes title, case name, and aliases by prefix', () {
      final titleSuggestions = autocomplete.autocomplete('Article 21');
      expect(titleSuggestions.contains('Article 21: Protection of Life'), isTrue);

      final caseSuggestions = autocomplete.autocomplete('Maneka');
      expect(caseSuggestions.contains('Maneka Gandhi v. Union of India'), isTrue);

      final aliasSuggestions = autocomplete.autocomplete('Right to');
      expect(aliasSuggestions.contains('Right to Life'), isTrue);
    });
  });
}
