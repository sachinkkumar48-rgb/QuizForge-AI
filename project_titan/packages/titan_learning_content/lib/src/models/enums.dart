/// Supported educational content types in Project TITAN.
enum ContentType {
  video,
  pdf,
  notes,
  audio,
  liveClass,
  quiz,
  pyq,
  assignment,
  flashcards,
  mindMap,
  interactive,
  aiConversation,
  revision,
  lab,
  simulation,
}

/// Learning activity event types tracked by LearningActivityEngine.
enum LearningActivityType {
  started,
  viewed,
  played,
  read,
  paused,
  resumed,
  attempted,
  completed,
  revised,
  downloaded,
  shared,
  askedAI,
  discussed,
}
