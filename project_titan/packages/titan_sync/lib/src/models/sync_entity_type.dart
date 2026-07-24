/// Supported domain entity types for cloud synchronization in Project TITAN.
enum SyncEntityType {
  identity,
  learningProfile,
  revision,
  recommendation,
  planner,
  knowledgeGraph,
  analytics,
  notes,
  userPreferences,
}

/// CRUD action type performed on a sync item.
enum SyncAction {
  create,
  update,
  delete,
}

/// Status of an individual sync item in the local offline queue.
enum SyncItemStatus {
  pending,
  syncing,
  synced,
  failed,
  conflict,
}
