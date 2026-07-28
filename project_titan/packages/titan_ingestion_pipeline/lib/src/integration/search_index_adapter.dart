import 'package:titan_search/titan_search.dart';
import '../models/knowledge_object.dart';

/// Integration adapter connecting Knowledge Objects with titan_search.
class SearchIndexAdapter {
  final SearchRepository searchRepository;

  SearchIndexAdapter({required this.searchRepository});

  /// Indexes a canonical [KnowledgeObject] into titan_search.
  Future<void> indexKnowledgeObject(KnowledgeObject object) async {
    final fullText =
        object.contentBlocks.map((b) => b.toJson().values.join(' ')).join(' ');

    final searchDoc = SearchIndexItem(
      id: 'idx_${object.id}',
      contentId: object.id,
      title: object.title,
      content: fullText,
      scope: SearchScope.notes,
      conceptIds: object.concepts.map((c) => c.id).toList(),
      tags: object.keywords,
      metadata: {
        'source': object.source,
        'language': object.language,
        'difficulty': object.difficulty,
        'chapter': object.chapter ?? '',
        'module': object.module ?? '',
      },
    );

    await searchRepository.indexItem(searchDoc);
  }
}
