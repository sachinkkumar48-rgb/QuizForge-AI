import 'package:flutter/foundation.dart';

/// Priority level for a study plan item.
enum PlanPriority { high, medium, low }

/// Represents a scheduled study task or topic item in the mentor study plan.
@immutable
class StudyPlanItem {
  final String id;
  final String subject;
  final String topic;
  final int estimatedMinutes;
  final bool isCompleted;
  final DateTime recommendedDate;
  final PlanPriority priority;
  final String actionType; // e.g., 'PYQ Practice', 'AI Quiz', 'Theory Revision'

  const StudyPlanItem({
    required this.id,
    required this.subject,
    required this.topic,
    required this.estimatedMinutes,
    this.isCompleted = false,
    required this.recommendedDate,
    required this.priority,
    required this.actionType,
  });

  StudyPlanItem copyWith({
    String? id,
    String? subject,
    String? topic,
    int? estimatedMinutes,
    bool? isCompleted,
    DateTime? recommendedDate,
    PlanPriority? priority,
    String? actionType,
  }) {
    return StudyPlanItem(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
      recommendedDate: recommendedDate ?? this.recommendedDate,
      priority: priority ?? this.priority,
      actionType: actionType ?? this.actionType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'topic': topic,
      'estimatedMinutes': estimatedMinutes,
      'isCompleted': isCompleted,
      'recommendedDate': recommendedDate.toIso8601String(),
      'priority': priority.name,
      'actionType': actionType,
    };
  }

  factory StudyPlanItem.fromJson(Map<String, dynamic> json) {
    return StudyPlanItem(
      id: json['id'] as String,
      subject: json['subject'] as String,
      topic: json['topic'] as String,
      estimatedMinutes: json['estimatedMinutes'] as int,
      isCompleted: json['isCompleted'] as bool? ?? false,
      recommendedDate: DateTime.parse(json['recommendedDate'] as String),
      priority: PlanPriority.values.byName(json['priority'] as String),
      actionType: json['actionType'] as String,
    );
  }
}

/// Represents an identified weak topic needing revision.
@immutable
class WeakTopicInfo {
  final String id;
  final String subject;
  final String topic;
  final double accuracyPercentage;
  final int questionsAttempted;
  final String recommendedAction;

  const WeakTopicInfo({
    required this.id,
    required this.subject,
    required this.topic,
    required this.accuracyPercentage,
    required this.questionsAttempted,
    required this.recommendedAction,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'topic': topic,
      'accuracyPercentage': accuracyPercentage,
      'questionsAttempted': questionsAttempted,
      'recommendedAction': recommendedAction,
    };
  }

  factory WeakTopicInfo.fromJson(Map<String, dynamic> json) {
    return WeakTopicInfo(
      id: json['id'] as String,
      subject: json['subject'] as String,
      topic: json['topic'] as String,
      accuracyPercentage: (json['accuracyPercentage'] as num).toDouble(),
      questionsAttempted: json['questionsAttempted'] as int,
      recommendedAction: json['recommendedAction'] as String,
    );
  }
}

/// Represents an actionable AI mentor recommendation/insight tile.
@immutable
class MentorRecommendation {
  final String id;
  final String title;
  final String description;
  final String category;
  final String iconName;
  final int impactScore; // 1 to 100

  const MentorRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.iconName,
    required this.impactScore,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'iconName': iconName,
      'impactScore': impactScore,
    };
  }

  factory MentorRecommendation.fromJson(Map<String, dynamic> json) {
    return MentorRecommendation(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      iconName: json['iconName'] as String,
      impactScore: json['impactScore'] as int,
    );
  }
}

/// Aggregated domain entity containing full AI mentor data.
@immutable
class AIMentorData {
  final String mentorGreeting;
  final String overallAdvice;
  final List<WeakTopicInfo> weakTopics;
  final List<StudyPlanItem> studyPlan;
  final List<MentorRecommendation> recommendations;
  final double suggestedDailyStudyHours;

  const AIMentorData({
    required this.mentorGreeting,
    required this.overallAdvice,
    required this.weakTopics,
    required this.studyPlan,
    required this.recommendations,
    required this.suggestedDailyStudyHours,
  });

  AIMentorData copyWith({
    String? mentorGreeting,
    String? overallAdvice,
    List<WeakTopicInfo>? weakTopics,
    List<StudyPlanItem>? studyPlan,
    List<MentorRecommendation>? recommendations,
    double? suggestedDailyStudyHours,
  }) {
    return AIMentorData(
      mentorGreeting: mentorGreeting ?? this.mentorGreeting,
      overallAdvice: overallAdvice ?? this.overallAdvice,
      weakTopics: weakTopics ?? this.weakTopics,
      studyPlan: studyPlan ?? this.studyPlan,
      recommendations: recommendations ?? this.recommendations,
      suggestedDailyStudyHours:
          suggestedDailyStudyHours ?? this.suggestedDailyStudyHours,
    );
  }
}
