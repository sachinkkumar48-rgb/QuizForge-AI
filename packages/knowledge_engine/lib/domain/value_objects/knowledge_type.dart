/// KnowledgeType enum representing the source/category of a knowledge object
/// within the TITAN Knowledge Intelligence Engine (KIE) foundation.
enum KnowledgeType {
  /// Portable Document Format source.
  pdf,

  /// Web, news, or blog article source.
  article,

  /// Previous Year Question paper or question item.
  pyq,

  /// User, study, or synthetic note source.
  note,

  /// Textbook or reference book source.
  book,

  /// Official, statistical, or analytical report source.
  report,

  /// Video or audiovisual source.
  video,

  /// Other custom or unclassified knowledge source.
  other,
}
