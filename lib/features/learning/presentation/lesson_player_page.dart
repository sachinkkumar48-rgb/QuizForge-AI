import 'package:flutter/material.dart';
import '../controllers/lesson_player_controller.dart';
import '../data/lesson_repository.dart';
import '../models/lesson_model.dart';
import '../widgets/completion_card.dart';
import '../widgets/concept_card.dart';
import '../widgets/example_card.dart';
import '../widgets/lesson_footer.dart';
import '../widgets/lesson_header.dart';
import '../widgets/lesson_progress_bar.dart';
import '../widgets/mentor_hint_card.dart';
import '../widgets/mentor_message_card.dart';
import '../widgets/quiz_card.dart';
import '../widgets/reflection_card.dart';
import '../widgets/revision_card.dart';
import '../widgets/story_card.dart';

class LessonPlayerPage extends StatefulWidget {
  final String lessonId;

  const LessonPlayerPage({
    super.key,
    this.lessonId = 'POL.FR.001',
  });

  @override
  State<LessonPlayerPage> createState() => _LessonPlayerPageState();
}

class _LessonPlayerPageState extends State<LessonPlayerPage> {
  late final LessonPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LessonPlayerController(
      repository: LessonRepository(),
    );
    _controller.addListener(_onControllerChanged);
    _controller.loadLesson(widget.lessonId);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {});
  }

  String _getSectionLabel(StepType type) {
    switch (type) {
      case StepType.story:
        return 'Story';
      case StepType.concept:
        return 'Concept';
      case StepType.example:
        return 'Example';
      case StepType.quiz:
        return 'Practice';
      case StepType.revision:
        return 'Revision';
      case StepType.completion:
        return 'Completion';
    }
  }

  Color _getSectionColor(StepType type, ThemeData theme) {
    switch (type) {
      case StepType.story:
        return theme.colorScheme.secondary;
      case StepType.concept:
        return theme.colorScheme.primary;
      case StepType.example:
        return theme.colorScheme.tertiary;
      case StepType.quiz:
        return Colors.orange.shade800;
      case StepType.revision:
        return Colors.purple.shade700;
      case StepType.completion:
        return Colors.green.shade700;
    }
  }

  void _showAiMentorBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final currentStep = _controller.currentStepData;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (modalContext) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: theme.colorScheme.primary,
                      size: 24.0,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Text(
                    'AI Mentor (SARTHI)',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              if (currentStep?.mentorMessage != null) ...[
                MentorMessageCard(
                  message: currentStep!.mentorMessage!,
                  greeting: 'Hello! I\'m SARTHI, your AI Learning Guide.',
                ),
                const SizedBox(height: 12.0),
              ],
              Text(
                'This feature will be connected to the GARUDA AI Engine in future sprints.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24.0),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(modalContext),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Dynamic step content renderer incorporating core step cards & Mentor Conversation Engine components
  Widget _buildStepWidget(LessonStep step) {
    final theme = Theme.of(context);
    final sectionLabel = _getSectionLabel(step.type);
    final sectionColor = _getSectionColor(step.type, theme);

    Widget mainCard;

    switch (step.type) {
      case StepType.story:
        mainCard = step.story != null
            ? StoryCard(
                storyTitle: step.story!.storyTitle,
                storyContent: step.story!.storyContent,
                reflectionQuestion: step.story!.reflectionQuestion,
              )
            : const SizedBox.shrink();
        break;
      case StepType.concept:
        mainCard = step.concept != null
            ? ConceptCard(
                title: step.concept!.title,
                explanation: step.concept!.explanation,
                keyPoint: step.concept!.keyPoint,
                upscTip: step.concept!.upscTip,
              )
            : const SizedBox.shrink();
        break;
      case StepType.example:
        mainCard = step.example != null
            ? ExampleCard(
                scenario: step.example!.scenario,
                explanation: step.example!.explanation,
                takeaway: step.example!.takeaway,
              )
            : const SizedBox.shrink();
        break;
      case StepType.quiz:
        mainCard = step.quiz != null
            ? QuizCard(
                question: step.quiz!.question,
                options: step.quiz!.options,
                correctIndex: step.quiz!.correctIndex,
                explanation: step.quiz!.explanation,
                hint: step.mentorHint,
              )
            : const SizedBox.shrink();
        break;
      case StepType.revision:
        mainCard = step.revision != null
            ? RevisionCard(
                title: step.revision!.title,
                keyPoints: step.revision!.keyPoints,
              )
            : const SizedBox.shrink();
        break;
      case StepType.completion:
        mainCard = step.completion != null
            ? CompletionCard(
                title: step.completion!.title,
                subtitle: step.completion!.subtitle,
                progressPercentage: step.completion!.progressPercentage,
                buttonText: step.completion!.buttonText,
                onContinue: () {
                  if (_controller.lesson?.id == 'POL.FR.001' || _controller.lesson?.id == 'POL-FR-001') {
                    _controller.loadLesson('POL.FR.002');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Congratulations! You have completed Module 7: Articles 12 & 13.'),
                      ),
                    );
                  }
                },
              )
            : const SizedBox.shrink();
        break;
    }

    return Column(
      children: [
        // Section Label Badge Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: sectionColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(color: sectionColor.withAlpha(100), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: sectionColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    Text(
                      sectionLabel.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: sectionColor,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 1. Mentor Message Card (if provided for the step)
        if (step.mentorMessage != null)
          MentorMessageCard(message: step.mentorMessage!),

        // 2. Main Step Card
        mainCard,

        // 3. Mentor Hint Card (if provided & not already handled in QuizCard)
        if (step.mentorHint != null && step.type != StepType.quiz)
          MentorHintCard(hint: step.mentorHint!),

        // 4. Reflection Question Card (if provided for the step)
        if (step.reflectionQuestion != null)
          ReflectionCard(
            question: step.reflectionQuestion!,
            onContinue: _controller.hasNext ? _controller.nextStep : null,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_controller.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Learning Journey'),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final lesson = _controller.lesson;
    final currentStepData = _controller.currentStepData;

    if (lesson == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(
          child: Text('Failed to load lesson.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text(
              'Learning Journey',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
            ),
            Text(
              lesson.id,
              style: TextStyle(
                fontSize: 12.0,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: theme.colorScheme.surfaceTint,
      ),
      body: Column(
        children: [
          // Animated Progress Bar (Step X of Y & Progress %)
          LessonProgressBar(
            currentStep: _controller.currentStep,
            totalSteps: _controller.totalSteps,
          ),
          // Lesson Header (Title & Estimated Time)
          LessonHeader(
            title: lesson.title,
            estimatedTime: lesson.estimatedTime,
            subject: lesson.subject,
          ),
          const Divider(height: 1.0),
          // Scrollable Lesson Content Area with Smooth Step Transition
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.04, 0.0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(_controller.currentStepIndex),
                  child: currentStepData != null
                      ? _buildStepWidget(currentStepData)
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ],
      ),
      // Bottom Navigation Footer
      bottomNavigationBar: LessonFooter(
        onPrevious: _controller.hasPrevious ? _controller.previousStep : null,
        onNext: _controller.hasNext ? _controller.nextStep : null,
        onAiMentor: () => _showAiMentorBottomSheet(context),
        completionPercentage: _controller.completionPercentage,
        hasPrevious: _controller.hasPrevious,
        hasNext: _controller.hasNext,
      ),
    );
  }
}
