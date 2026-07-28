import 'prompt_template.dart';

/// Centralized engine for managing, registering, and rendering AI prompt templates
/// across all TITAN features without hardcoding prompts in widgets.
class PromptTemplateEngine {
  final Map<String, PromptTemplate> _templates = {};

  PromptTemplateEngine() {
    _registerDefaultTemplates();
  }

  /// Register a [PromptTemplate] in the engine.
  void register(PromptTemplate template) {
    _templates[template.id] = template;
  }

  /// Returns template by [id], or null if not found.
  PromptTemplate? getTemplate(String id) => _templates[id];

  /// Renders prompt for [templateId] using provided [variables].
  /// Throws [ArgumentError] if template with [templateId] is not registered.
  String render(String templateId, Map<String, Object?> variables) {
    final template = _templates[templateId];
    if (template == null) {
      throw ArgumentError('Prompt template "$templateId" is not registered.');
    }
    return template.render(variables);
  }

  /// Returns list of all registered prompt templates.
  List<PromptTemplate> get registeredTemplates =>
      List.unmodifiable(_templates.values);

  /// Registers core TITAN prompt templates.
  void _registerDefaultTemplates() {
    register(const PromptTemplate(
      id: 'tutor_explain',
      name: 'AI Tutor Concept Explanation',
      version: '1.0.0',
      template: '''
You are an expert AI Tutor for UPSC CSE exam preparation.
User Goal: Master concept "{{concept}}" in subject "{{subject}}".
Learner Context: Target Exam: {{targetExam}}, Mastery Level: {{masteryLevel}}.

Task: Explain "{{concept}}" in detail with:
1. Core Definition & Key Principles
2. Historical / Contextual Relevance
3. Real-world Examples / Case Studies
4. Key UPSC Exam Takeaways & Model Answer Pointers
5. Related Sub-topics to explore.

Context: {{context}}
User Question: {{query}}
''',
    ));

    register(const PromptTemplate(
      id: 'mentor_guide',
      name: 'AI Personal Mentor Guidance',
      version: '1.0.0',
      template: '''
You are TITAN, a high-performance personal AI Mentor for UPSC preparation.
Learner Profile:
- Name: {{userName}}
- Target Exam: {{targetExam}}
- Weak Subjects: {{weakSubjects}}
- Strong Subjects: {{strongSubjects}}
- Recent Active Concept: {{recommendedTopic}}
- Pending Revisions: {{pendingRevisionsCount}}
- Daily Target: {{studyHoursCompleted}}/{{studyHoursTarget}} hours

Context Assembly:
{{context}}

Provide encouraging, actionable, and structured guidance addressing: {{userQuery}}
''',
    ));

    register(const PromptTemplate(
      id: 'quiz_generate',
      name: 'Quiz Generation',
      version: '1.0.0',
      template: '''
Generate {{questionCount}} high-yield multiple-choice questions for UPSC preparation.
Subject: {{subject}}
Topic: {{topic}}
Difficulty: {{difficulty}}

Context:
{{context}}

Return output strictly as valid JSON formatted as:
[
  {
    "id": "q1",
    "question": "Question text",
    "options": ["Option A", "Option B", "Option C", "Option D"],
    "correctIndex": 0,
    "explanation": "Detailed explanation of correct answer."
  }
]
''',
    ));

    register(const PromptTemplate(
      id: 'summary_lesson',
      name: 'Lesson Summarization',
      version: '1.0.0',
      template: '''
Summarize the following lesson content for quick UPSC revision:
Topic: {{topic}}
Content: {{content}}

Provide:
1. Concise 3-bullet Executive Summary
2. Core Takeaways & Keywords
3. Memory Anchors / Mnemonics (if applicable)
''',
    ));

    register(const PromptTemplate(
      id: 'revision_suggest',
      name: 'Spaced Revision Suggestion',
      version: '1.0.0',
      template: '''
Analyze the learner's spaced repetition queue and recommend optimal revision strategy.
Pending Revisions Count: {{pendingRevisionsCount}}
Weak Subjects: {{weakSubjects}}
Recent Search History: {{recentSearchQueries}}

Suggest top 3 high-priority topics to revise today with justification.
''',
    ));

    register(const PromptTemplate(
      id: 'planner_generate',
      name: 'Study Plan Generator',
      version: '1.0.0',
      template: '''
Create a customized daily/weekly UPSC study schedule.
Available Daily Hours: {{availableHours}}
Target Exam Date: {{targetExamDate}}
Focus Subjects: {{focusSubjects}}

Generate structured daily time blocks covering Static syllabus, Current Affairs, Practice Quizzes, and Spaced Revision.
''',
    ));

    register(const PromptTemplate(
      id: 'mindmap_generate',
      name: 'Mind Map Generator',
      version: '1.0.0',
      template: '''
Generate a hierarchical mind map structure for topic: "{{topic}}".
Subject: {{subject}}
Detail Level: {{detailLevel}}

Return JSON representation of mind map nodes:
{
  "root": "{{topic}}",
  "branches": [
    {
      "title": "Subtopic Title",
      "children": ["Point 1", "Point 2"]
    }
  ]
}
''',
    ));

    register(const PromptTemplate(
      id: 'notes_generate',
      name: 'AI Notes Generator',
      version: '1.0.0',
      template: '''
Convert the following explanation or study material into structured revision notes:
Topic: {{topic}}
Raw Content: {{content}}

Format with Markdown headings, key bullet points, definition boxes, and exam tips.
''',
    ));

    register(const PromptTemplate(
      id: 'evaluate_answer',
      name: 'Descriptive Answer Evaluation',
      version: '1.0.0',
      template: '''
Evaluate the user's descriptive answer for UPSC Mains:
Question: {{question}}
Subject: {{subject}}
User Answer: {{userAnswer}}

Provide:
1. Score out of 10
2. Structure & Presentation Assessment
3. Content Coverage & Fact Accuracy
4. Value Addition / Map / Diagram Recommendations
5. Model Improvements
''',
    ));

    register(const PromptTemplate(
      id: 'daily_targets',
      name: 'Daily Learning Targets Generator',
      version: '1.0.0',
      template: '''
Generate 3 concrete daily targets for UPSC aspirant {{userName}}.
Target Exam: {{targetExam}}
Completed Today: {{studyHoursCompleted}} hrs / Goal: {{studyHoursTarget}} hrs
Weak Areas: {{weakSubjects}}

Return 3 specific, measurable study goals.
''',
    ));

    register(const PromptTemplate(
      id: 'motivation_generate',
      name: 'Motivational Nudge Generator',
      version: '1.0.0',
      template: '''
Generate an inspiring, disciplined motivational quote and mentor reflection for a UPSC aspirant.
Learner Streak: {{streakDays}} days
Recent Performance Accuracy: {{accuracyRate}}%
Name: {{userName}}
''',
    ));
  }
}
