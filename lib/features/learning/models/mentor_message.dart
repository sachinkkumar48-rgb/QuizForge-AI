class MentorMessage {
  final String mentorName;
  final String message;
  final String? question;
  final String? hint;

  const MentorMessage({
    this.mentorName = 'SARTHI',
    required this.message,
    this.question,
    this.hint,
  });

  factory MentorMessage.fromJson(Map<String, dynamic> json) {
    return MentorMessage(
      mentorName: json['mentorName'] as String? ?? 'SARTHI',
      message: json['message'] as String,
      question: json['question'] as String?,
      hint: json['hint'] as String?,
    );
  }
}
