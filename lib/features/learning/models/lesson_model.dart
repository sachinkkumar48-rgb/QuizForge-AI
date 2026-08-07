import 'mentor_message.dart';

enum StepType { concept, story, example, quiz, revision, completion }

class ConceptData {
  final String title;
  final String explanation;
  final String keyPoint;
  final String upscTip;

  const ConceptData({
    required this.title,
    required this.explanation,
    required this.keyPoint,
    required this.upscTip,
  });

  factory ConceptData.fromJson(Map<String, dynamic> json) {
    return ConceptData(
      title: json['title'] as String,
      explanation: json['explanation'] as String,
      keyPoint: json['keyPoint'] as String,
      upscTip: json['upscTip'] as String,
    );
  }
}

class StoryData {
  final String storyTitle;
  final String storyContent;
  final String reflectionQuestion;

  const StoryData({
    required this.storyTitle,
    required this.storyContent,
    required this.reflectionQuestion,
  });

  factory StoryData.fromJson(Map<String, dynamic> json) {
    return StoryData(
      storyTitle: json['storyTitle'] as String,
      storyContent: json['storyContent'] as String,
      reflectionQuestion: json['reflectionQuestion'] as String,
    );
  }
}

class ExampleData {
  final String scenario;
  final String explanation;
  final String takeaway;

  const ExampleData({
    required this.scenario,
    required this.explanation,
    required this.takeaway,
  });

  factory ExampleData.fromJson(Map<String, dynamic> json) {
    return ExampleData(
      scenario: json['scenario'] as String,
      explanation: json['explanation'] as String,
      takeaway: json['takeaway'] as String,
    );
  }
}

class QuizData {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const QuizData({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  factory QuizData.fromJson(Map<String, dynamic> json) {
    return QuizData(
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List),
      correctIndex: json['correctIndex'] as int,
      explanation: json['explanation'] as String,
    );
  }
}

class RevisionData {
  final String title;
  final List<String> keyPoints;

  const RevisionData({
    required this.title,
    required this.keyPoints,
  });

  factory RevisionData.fromJson(Map<String, dynamic> json) {
    return RevisionData(
      title: json['title'] as String,
      keyPoints: List<String>.from(json['keyPoints'] as List),
    );
  }
}

class CompletionData {
  final String title;
  final String subtitle;
  final int progressPercentage;
  final String buttonText;

  const CompletionData({
    required this.title,
    required this.subtitle,
    required this.progressPercentage,
    required this.buttonText,
  });

  factory CompletionData.fromJson(Map<String, dynamic> json) {
    return CompletionData(
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      progressPercentage: json['progressPercentage'] as int,
      buttonText: json['buttonText'] as String,
    );
  }
}

class LessonStep {
  final String id;
  final StepType type;
  final ConceptData? concept;
  final StoryData? story;
  final ExampleData? example;
  final QuizData? quiz;
  final RevisionData? revision;
  final CompletionData? completion;

  // Optional Mentor Conversation Fields
  final String? mentorMessage;
  final String? mentorQuestion;
  final String? mentorHint;
  final String? reflectionQuestion;
  final MentorMessage? mentorMessageObj;

  const LessonStep({
    required this.id,
    required this.type,
    this.concept,
    this.story,
    this.example,
    this.quiz,
    this.revision,
    this.completion,
    this.mentorMessage,
    this.mentorQuestion,
    this.mentorHint,
    this.reflectionQuestion,
    this.mentorMessageObj,
  });

  factory LessonStep.fromJson(Map<String, dynamic> json) {
    final typeString = json['type'] as String;
    final stepType = StepType.values.firstWhere(
      (e) => e.name.toLowerCase() == typeString.toLowerCase(),
      orElse: () => StepType.concept,
    );

    return LessonStep(
      id: json['id'] as String,
      type: stepType,
      concept: json['concept'] != null
          ? ConceptData.fromJson(json['concept'] as Map<String, dynamic>)
          : null,
      story: json['story'] != null
          ? StoryData.fromJson(json['story'] as Map<String, dynamic>)
          : null,
      example: json['example'] != null
          ? ExampleData.fromJson(json['example'] as Map<String, dynamic>)
          : null,
      quiz: json['quiz'] != null
          ? QuizData.fromJson(json['quiz'] as Map<String, dynamic>)
          : null,
      revision: json['revision'] != null
          ? RevisionData.fromJson(json['revision'] as Map<String, dynamic>)
          : null,
      completion: json['completion'] != null
          ? CompletionData.fromJson(json['completion'] as Map<String, dynamic>)
          : null,
      mentorMessage: json['mentorMessage'] as String?,
      mentorQuestion: json['mentorQuestion'] as String?,
      mentorHint: json['mentorHint'] as String?,
      reflectionQuestion: json['reflectionQuestion'] as String?,
      mentorMessageObj: json['mentorMessageObj'] != null
          ? MentorMessage.fromJson(json['mentorMessageObj'] as Map<String, dynamic>)
          : null,
    );
  }
}

class LessonModel {
  final String id;
  final String title;
  final String subject;
  final String estimatedTime;
  final List<LessonStep> steps;

  const LessonModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.estimatedTime,
    required this.steps,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      id: json['id'] as String,
      title: json['title'] as String,
      subject: json['subject'] as String,
      estimatedTime: json['estimatedTime'] as String,
      steps: (json['steps'] as List)
          .map((step) => LessonStep.fromJson(step as Map<String, dynamic>))
          .toList(),
    );
  }
}
