library;

/// Enums for Live Classes Platform in Project TITAN.
enum LiveSessionStatus {
  scheduled,
  waitingRoomOpen,
  live,
  paused,
  ended,
  cancelled,
}

extension LiveSessionStatusX on LiveSessionStatus {
  String get label {
    switch (this) {
      case LiveSessionStatus.scheduled:
        return 'Scheduled';
      case LiveSessionStatus.waitingRoomOpen:
        return 'Waiting Room Open';
      case LiveSessionStatus.live:
        return 'LIVE';
      case LiveSessionStatus.paused:
        return 'Paused';
      case LiveSessionStatus.ended:
        return 'Ended';
      case LiveSessionStatus.cancelled:
        return 'Cancelled';
    }
  }
}

enum ParticipantRole {
  instructor,
  coHost,
  student,
  guest,
}

enum ChatMessageType {
  text,
  question,
  announcement,
  whiteboardLink,
  system,
}

enum PollStatus {
  draft,
  active,
  closed,
}

enum RecordingStatus {
  notStarted,
  recording,
  processing,
  ready,
  failed,
}

enum LiveResourceType {
  pdf,
  link,
  quiz,
  pyq,
  notes,
}

enum AttendanceStatus {
  present,
  late,
  absent,
  excused,
}
