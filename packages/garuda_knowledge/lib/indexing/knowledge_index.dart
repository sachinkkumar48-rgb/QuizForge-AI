import '../domain/entities/knowledge_object.dart';
import '../domain/enums/knowledge_object_type.dart';
import '../domain/enums/relationship_type.dart';
import '../text/knowledge_normalizer.dart';
import '../text/knowledge_tokenizer.dart';

/// Inverted multi-field offline search index storing references to Knowledge Objects.
class KnowledgeIndex {
  final KnowledgeTokenizer tokenizer;
  final KnowledgeNormalizer normalizer;

  // Dedicated Inverted Indexes (Token -> Set<ObjectId>)
  final Map<String, Set<String>> _idIndex = {};
  final Map<KnowledgeObjectType, Set<String>> _typeIndex = {};
  final Map<String, Set<String>> _titleIndex = {};
  final Map<String, Set<String>> _aliasIndex = {};
  final Map<String, Set<String>> _keywordIndex = {};
  final Map<String, Set<String>> _tagIndex = {};
  final Map<String, Set<String>> _subjectIndex = {};
  final Map<String, Set<String>> _topicIndex = {};
  final Map<String, Set<String>> _subtopicIndex = {};
  final Map<String, Set<String>> _conceptIndex = {};
  final Map<String, Set<String>> _microConceptIndex = {};
  final Map<String, Set<String>> _articleNumberIndex = {};
  final Map<String, Set<String>> _actIndex = {};
  final Map<String, Set<String>> _caseIndex = {};
  final Map<String, Set<String>> _doctrineIndex = {};
  final Map<String, Set<String>> _committeeIndex = {};
  final Map<String, Set<String>> _reportIndex = {};
  final Map<String, Set<String>> _schemeIndex = {};
  final Map<String, Set<String>> _institutionIndex = {};
  final Map<String, Set<String>> _currentAffairsIndex = {};
  final Map<String, Set<String>> _pyqIndex = {};
  final Map<String, Set<String>> _evidenceIndex = {};
  final Map<String, Set<String>> _relationshipIndex = {};
  final Map<String, Set<String>> _versionIndex = {};
  final Map<String, Set<String>> _editorialStatusIndex = {};
  final Map<String, Set<String>> _packageIndex = {};

  // Stored Objects Map
  final Map<String, KnowledgeObject> _storedObjects = {};

  KnowledgeIndex({KnowledgeTokenizer? tokenizer, KnowledgeNormalizer? normalizer})
      : tokenizer = tokenizer ?? KnowledgeTokenizer(),
        normalizer = normalizer ?? KnowledgeNormalizer();

  int get totalIndexedObjects => _storedObjects.length;
  Map<String, KnowledgeObject> get storedObjects => Map.unmodifiable(_storedObjects);

  /// Indexes a single KnowledgeObject across all 26 dedicated secondary index dimensions.
  void index(KnowledgeObject obj) {
    final id = obj.id.value;
    _storedObjects[id] = obj;

    // 1. Knowledge ID
    _idIndex.putIfAbsent(id.toLowerCase(), () => {}).add(id);

    // 2. Object Type
    _typeIndex.putIfAbsent(obj.type, () => {}).add(id);

    // 3. Title (Full & Tokens)
    final normalizedTitle = normalizer.normalize(obj.title);
    _titleIndex.putIfAbsent(normalizedTitle, () => {}).add(id);
    for (final token in tokenizer.tokenize(obj.title)) {
      _titleIndex.putIfAbsent(token, () => {}).add(id);
    }

    // 4. Aliases (from metadata or attributes)
    final aliases = obj.metadata.customAttributes['aliases'];
    if (aliases is List) {
      for (final alias in aliases) {
        final normAlias = normalizer.normalize(alias.toString());
        _aliasIndex.putIfAbsent(normAlias, () => {}).add(id);
      }
    }

    // 5. Keywords
    final fullText = '${obj.title} ${obj.summary ?? ''} ${obj.content}';
    for (final token in tokenizer.tokenize(fullText)) {
      _keywordIndex.putIfAbsent(token, () => {}).add(id);
    }

    // 6. Tags
    for (final tag in obj.tags) {
      final tagNorm = normalizer.normalize(tag.name);
      _tagIndex.putIfAbsent(tagNorm, () => {}).add(id);
    }

    // 7. Subject
    final subject = obj.metadata.customAttributes['subject'] ?? obj.category?.name;
    if (subject != null) {
      _subjectIndex.putIfAbsent(normalizer.normalize(subject.toString()), () => {}).add(id);
    }

    // 8. Topic
    final topic = obj.metadata.customAttributes['topic'];
    if (topic != null) {
      _topicIndex.putIfAbsent(normalizer.normalize(topic.toString()), () => {}).add(id);
    }

    // 9. Subtopic
    final subtopic = obj.metadata.customAttributes['subtopic'];
    if (subtopic != null) {
      _subtopicIndex.putIfAbsent(normalizer.normalize(subtopic.toString()), () => {}).add(id);
    }

    // 10. Concept
    final concept = obj.metadata.customAttributes['concept'];
    if (concept != null) {
      _conceptIndex.putIfAbsent(normalizer.normalize(concept.toString()), () => {}).add(id);
    }

    // 11. Micro Concept
    final microConcept = obj.metadata.customAttributes['micro_concept'];
    if (microConcept != null) {
      _microConceptIndex.putIfAbsent(normalizer.normalize(microConcept.toString()), () => {}).add(id);
    }

    // 12. Article Number
    final articleNo = obj.metadata.customAttributes['article_number'] ?? _extractArticle(obj.title);
    if (articleNo != null) {
      final normArt = normalizer.normalizeArticleNumber(articleNo.toString());
      _articleNumberIndex.putIfAbsent(normArt, () => {}).add(id);
    }

    // 13. Act
    final act = obj.metadata.customAttributes['act'];
    if (act != null) {
      _actIndex.putIfAbsent(normalizer.normalize(act.toString()), () => {}).add(id);
    }

    // 14. Case
    final caseName = obj.metadata.customAttributes['case_name'] ?? (obj.type == KnowledgeObjectType.caseLaw ? obj.title : null);
    if (caseName != null) {
      _caseIndex.putIfAbsent(normalizer.normalizeCaseName(caseName.toString()), () => {}).add(id);
    }

    // 15. Doctrine
    final doctrine = obj.metadata.customAttributes['doctrine'] ?? (obj.type == KnowledgeObjectType.doctrine ? obj.title : null);
    if (doctrine != null) {
      _doctrineIndex.putIfAbsent(normalizer.normalize(doctrine.toString()), () => {}).add(id);
    }

    // 16. Committee
    final committee = obj.metadata.customAttributes['committee'];
    if (committee != null) {
      _committeeIndex.putIfAbsent(normalizer.normalize(committee.toString()), () => {}).add(id);
    }

    // 17. Report
    final report = obj.metadata.customAttributes['report'];
    if (report != null) {
      _reportIndex.putIfAbsent(normalizer.normalize(report.toString()), () => {}).add(id);
    }

    // 18. Scheme
    final scheme = obj.metadata.customAttributes['scheme'];
    if (scheme != null) {
      _schemeIndex.putIfAbsent(normalizer.normalize(scheme.toString()), () => {}).add(id);
    }

    // 19. Institution
    final institution = obj.metadata.customAttributes['institution'];
    if (institution != null) {
      _institutionIndex.putIfAbsent(normalizer.normalize(institution.toString()), () => {}).add(id);
    }

    // 20. Current Affairs
    final ca = obj.metadata.customAttributes['current_affairs'];
    if (ca != null) {
      _currentAffairsIndex.putIfAbsent(normalizer.normalize(ca.toString()), () => {}).add(id);
    }

    // 21. PYQ
    final pyq = obj.metadata.customAttributes['pyq_id'] ?? (obj.type == KnowledgeObjectType.pyq ? obj.id.value : null);
    if (pyq != null) {
      _pyqIndex.putIfAbsent(pyq.toString().toLowerCase(), () => {}).add(id);
    }

    // 22. Evidence
    for (final ev in obj.evidenceReferences) {
      _evidenceIndex.putIfAbsent(ev.evidenceId.toLowerCase(), () => {}).add(id);
    }

    // 23. Relationships
    for (final rel in obj.relationships) {
      final key = '${rel.type.toJson()}:${rel.targetId.value}';
      _relationshipIndex.putIfAbsent(key.toLowerCase(), () => {}).add(id);
      _relationshipIndex.putIfAbsent(rel.type.toJson().toLowerCase(), () => {}).add(id);
    }

    // 24. Version
    _versionIndex.putIfAbsent(obj.currentVersion.versionString.toLowerCase(), () => {}).add(id);

    // 25. Editorial Status
    final status = obj.metadata.customAttributes['editorial_status'] ?? 'published';
    _editorialStatusIndex.putIfAbsent(status.toString().toLowerCase(), () => {}).add(id);

    // 26. Package / Source
    _packageIndex.putIfAbsent(obj.metadata.packageOrigin.toLowerCase(), () => {}).add(id);
  }

  /// Removes an object from all indexes.
  void unindex(String id) {
    final obj = _storedObjects.remove(id);
    if (obj == null) return;

    for (final set in _idIndex.values) { set.remove(id); }
    for (final set in _typeIndex.values) { set.remove(id); }
    for (final set in _titleIndex.values) { set.remove(id); }
    for (final set in _aliasIndex.values) { set.remove(id); }
    for (final set in _keywordIndex.values) { set.remove(id); }
    for (final set in _tagIndex.values) { set.remove(id); }
    for (final set in _subjectIndex.values) { set.remove(id); }
    for (final set in _topicIndex.values) { set.remove(id); }
    for (final set in _subtopicIndex.values) { set.remove(id); }
    for (final set in _conceptIndex.values) { set.remove(id); }
    for (final set in _microConceptIndex.values) { set.remove(id); }
    for (final set in _articleNumberIndex.values) { set.remove(id); }
    for (final set in _actIndex.values) { set.remove(id); }
    for (final set in _caseIndex.values) { set.remove(id); }
    for (final set in _doctrineIndex.values) { set.remove(id); }
    for (final set in _committeeIndex.values) { set.remove(id); }
    for (final set in _reportIndex.values) { set.remove(id); }
    for (final set in _schemeIndex.values) { set.remove(id); }
    for (final set in _institutionIndex.values) { set.remove(id); }
    for (final set in _currentAffairsIndex.values) { set.remove(id); }
    for (final set in _pyqIndex.values) { set.remove(id); }
    for (final set in _evidenceIndex.values) { set.remove(id); }
    for (final set in _relationshipIndex.values) { set.remove(id); }
    for (final set in _versionIndex.values) { set.remove(id); }
    for (final set in _editorialStatusIndex.values) { set.remove(id); }
    for (final set in _packageIndex.values) { set.remove(id); }
  }

  /// Clears all index maps completely.
  void clear() {
    _storedObjects.clear();
    _idIndex.clear();
    _typeIndex.clear();
    _titleIndex.clear();
    _aliasIndex.clear();
    _keywordIndex.clear();
    _tagIndex.clear();
    _subjectIndex.clear();
    _topicIndex.clear();
    _subtopicIndex.clear();
    _conceptIndex.clear();
    _microConceptIndex.clear();
    _articleNumberIndex.clear();
    _actIndex.clear();
    _caseIndex.clear();
    _doctrineIndex.clear();
    _committeeIndex.clear();
    _reportIndex.clear();
    _schemeIndex.clear();
    _institutionIndex.clear();
    _currentAffairsIndex.clear();
    _pyqIndex.clear();
    _evidenceIndex.clear();
    _relationshipIndex.clear();
    _versionIndex.clear();
    _editorialStatusIndex.clear();
    _packageIndex.clear();
  }

  // Set-based lookup getters for query engine
  Set<String> searchIds(String id) => _idIndex[id.toLowerCase()] ?? const {};
  Set<String> searchTypes(KnowledgeObjectType type) => _typeIndex[type] ?? const {};
  Set<String> searchKeywords(String term) => _keywordIndex[normalizer.normalize(term)] ?? const {};
  Set<String> searchTags(String tag) => _tagIndex[normalizer.normalize(tag)] ?? const {};
  Set<String> searchArticles(String art) => _articleNumberIndex[normalizer.normalizeArticleNumber(art)] ?? const {};
  Set<String> searchCases(String c) => _caseIndex[normalizer.normalizeCaseName(c)] ?? const {};
  Set<String> searchActs(String act) => _actIndex[normalizer.normalize(act)] ?? const {};
  Set<String> searchConcepts(String conc) => _conceptIndex[normalizer.normalize(conc)] ?? const {};
  Set<String> searchPackages(String pkg) => _packageIndex[pkg.toLowerCase()] ?? const {};
  Set<String> searchRelationships(RelationshipType type, {String? targetId}) {
    if (targetId != null) {
      final key = '${type.toJson()}:$targetId'.toLowerCase();
      return _relationshipIndex[key] ?? const {};
    }
    return _relationshipIndex[type.toJson().toLowerCase()] ?? const {};
  }

  Set<String> searchField(String fieldName, String value) {
    final norm = normalizer.normalize(value);
    switch (fieldName.toLowerCase()) {
      case 'subject': return _subjectIndex[norm] ?? const {};
      case 'topic': return _topicIndex[norm] ?? const {};
      case 'subtopic': return _subtopicIndex[norm] ?? const {};
      case 'micro_concept': return _microConceptIndex[norm] ?? const {};
      case 'committee': return _committeeIndex[norm] ?? const {};
      case 'report': return _reportIndex[norm] ?? const {};
      case 'scheme': return _schemeIndex[norm] ?? const {};
      case 'institution': return _institutionIndex[norm] ?? const {};
      case 'current_affairs': return _currentAffairsIndex[norm] ?? const {};
      case 'pyq': return _pyqIndex[value.toLowerCase()] ?? const {};
      case 'evidence': return _evidenceIndex[value.toLowerCase()] ?? const {};
      case 'version': return _versionIndex[value.toLowerCase()] ?? const {};
      case 'editorial_status': return _editorialStatusIndex[value.toLowerCase()] ?? const {};
      case 'alias': return _aliasIndex[norm] ?? const {};
      default: return const {};
    }
  }

  String? _extractArticle(String title) {
    final match = RegExp(r'\b(article|art\.?)\s*(\d+[a-z]?)\b', caseSensitive: false).firstMatch(title);
    return match?.group(2);
  }
}
