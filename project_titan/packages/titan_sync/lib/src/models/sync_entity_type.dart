/// Supported domain entity types for cloud synchronization across all TITAN subsystems.
enum SyncEntityType {
  identity,
  learningProfile,
  learningJourney,
  planner,
  notes,
  bookmarks,
  videoProgress,
  assessmentResults,
  revision,
  recommendation,
  dashboard,
  analytics,
  knowledgeGraph,
  userPreferences,
}

/// CRUD / Synchronization action type performed on a sync item or delta operation.
enum SyncAction {
  create,
  update,
  delete,
  merge,
}

/// Status of an individual sync item in the local offline queue.
enum SyncItemStatus {
  pending,
  syncing,
  synced,
  failed,
  conflict,
}
