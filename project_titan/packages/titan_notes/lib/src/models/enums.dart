/// Supported smart note types.
enum NoteType {
  manual,
  aiGenerated,
  timestamp,
  transcript,
  pdf,
  highlight,
  bookmark,
  revision,
  flashcard,
}

extension NoteTypeX on NoteType {
  String get label {
    switch (this) {
      case NoteType.manual:
        return 'Manual Note';
      case NoteType.aiGenerated:
        return 'AI Generated';
      case NoteType.timestamp:
        return 'Timestamp Note';
      case NoteType.transcript:
        return 'Transcript Note';
      case NoteType.pdf:
        return 'PDF Note';
      case NoteType.highlight:
        return 'Highlight Note';
      case NoteType.bookmark:
        return 'Bookmark Note';
      case NoteType.revision:
        return 'Revision Note';
      case NoteType.flashcard:
        return 'Flashcard Note';
    }
  }
}

/// Supported highlight color options.
enum HighlightColor {
  yellow,
  green,
  blue,
  pink,
  orange,
  purple,
}

extension HighlightColorX on HighlightColor {
  String get hexCode {
    switch (this) {
      case HighlightColor.yellow:
        return '#FFF176';
      case HighlightColor.green:
        return '#81C784';
      case HighlightColor.blue:
        return '#64B5F6';
      case HighlightColor.pink:
        return '#F06292';
      case HighlightColor.orange:
        return '#FFB74D';
      case HighlightColor.purple:
        return '#BA68C8';
    }
  }
}
