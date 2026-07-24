/// Content scopes supported by the TITAN Semantic Search Engine.
enum SearchScope {
  pdf,
  notes,
  knowledgeGraph,
  currentAffairs,
  pyqs,
  revision,
  planner,
}

extension SearchScopeExtension on SearchScope {
  String get displayName {
    switch (this) {
      case SearchScope.pdf:
        return 'PDF Documents';
      case SearchScope.notes:
        return 'Study Notes';
      case SearchScope.knowledgeGraph:
        return 'Knowledge Graph';
      case SearchScope.currentAffairs:
        return 'Current Affairs';
      case SearchScope.pyqs:
        return 'PYQs';
      case SearchScope.revision:
        return 'Revision Queue';
      case SearchScope.planner:
        return 'Planner';
    }
  }
}
