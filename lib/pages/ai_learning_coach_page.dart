import 'package:flutter/material.dart';

import '../controllers/learning_coach_controller.dart';
import '../models/analytics_engine_models.dart';
import '../models/pyq_question_model.dart';
import '../services/analytics_service.dart';
import '../services/ai/coach/learning_coach_factory.dart';

/// Comprehensive AI Learning Coach Dashboard Page showcasing provider decoupling
/// (Gemini, OpenAI, Claude, Local LLM) and all 6 core features:
/// 1. Weekly report
/// 2. Weak topics
/// 3. Recommended PYQs
/// 4. Recommended AI quizzes
/// 5. Study hours suggestion
/// 6. Motivational insights
class AiLearningCoachPage extends StatefulWidget {
  final List<PyqQuestionModel> questions;
  final LearningCoachController? controller;

  const AiLearningCoachPage({
    super.key,
    required this.questions,
    this.controller,
  });

  @override
  State<AiLearningCoachPage> createState() => _AiLearningCoachPageState();
}

class _AiLearningCoachPageState extends State<AiLearningCoachPage> {
  late final LearningCoachController _controller;
  late final LearningInsightsModel _insights;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? LearningCoachController();
    _insights = AnalyticsService().computeLearningInsights(widget.questions);
    _controller.analyzePerformance(_insights);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final analysis = _controller.analysis;

        return Scaffold(
          appBar: AppBar(
            title: const Text('AI Learning Coach'),
            actions: [
              PopupMenuButton<CoachProviderType>(
                icon: const Icon(Icons.tune),
                tooltip: 'Switch AI Provider',
                initialValue: _controller.activeProviderType,
                onSelected: (type) {
                  _controller.switchProvider(type);
                  _controller.analyzePerformance(_insights);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: CoachProviderType.gemini,
                    child: Text('Google Gemini Coach'),
                  ),
                  const PopupMenuItem(
                    value: CoachProviderType.openAi,
                    child: Text('OpenAI GPT Coach'),
                  ),
                  const PopupMenuItem(
                    value: CoachProviderType.claude,
                    child: Text('Anthropic Claude Coach'),
                  ),
                  const PopupMenuItem(
                    value: CoachProviderType.localLlm,
                    child: Text('Local LLM (Offline Coach)'),
                  ),
                ],
              ),
            ],
          ),
          body: _controller.isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('AI Coach is analyzing your performance metrics...'),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Active Provider Banner
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.primaryContainer.withAlpha(80),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.smart_toy, color: Colors.indigo),
                            const SizedBox(width: 10),
                            Text(
                              'Active Coach: ${_controller.coach.providerName}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 1. Motivational Insights Banner
                      if (analysis != null &&
                          analysis.motivationalInsights.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.amber.shade700,
                                Colors.deepOrange.shade600
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.auto_awesome,
                                  color: Colors.white, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  analysis.motivationalInsights,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // 2. Weekly Report Card
                      if (analysis != null) ...[
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.assessment,
                                        color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Weekly Performance Report',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  analysis.weeklyReport,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 3. Weak Topics Breakdown
                        Text(
                          'Identified Weak Topics',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (analysis.weakTopics.isEmpty)
                          const Text('No weak topics detected!')
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: analysis.weakTopics.map((topic) {
                              return ActionChip(
                                avatar: const Icon(Icons.psychology,
                                    size: 16, color: Colors.deepOrange),
                                label: Text(topic),
                                backgroundColor: Colors.red.shade50,
                                onPressed: () {
                                  _controller.explainWeakness(topic, 42.0);
                                  _showExplanationModal(context, topic);
                                },
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: 20),

                        // 4. Study Hours Suggestion Allocation
                        Card(
                          elevation: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.schedule,
                                        color: Colors.purple),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Suggested Daily Study Hours',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ...analysis.studyHoursSuggestion.entries
                                    .map((e) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 4.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(e.key,
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600)),
                                              Chip(
                                                label:
                                                    Text('${e.value} hrs/day'),
                                                backgroundColor:
                                                    Colors.purple.shade50,
                                              ),
                                            ],
                                          ),
                                        )),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 5. Recommended PYQs & AI Quizzes
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Recommended PYQs
                            Expanded(
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(14.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Recommended PYQs',
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ...analysis.recommendedPyqs.map(
                                        (pyq) => Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 4.0),
                                          child: Text('• $pyq',
                                              style: const TextStyle(
                                                  fontSize: 12)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Recommended AI Quizzes
                            Expanded(
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(14.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Recommended AI Quizzes',
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ...analysis.recommendedAiQuizzes.map(
                                        (quiz) => Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 4.0),
                                          child: Text('• $quiz',
                                              style: const TextStyle(
                                                  fontSize: 12)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // 6. Action Button: Generate Study Plan
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton.icon(
                            onPressed: () {
                              _controller.generateStudyPlan(
                                weakTopics: analysis.weakTopics,
                                totalDays: 7,
                                dailyHoursAvailable: 4.5,
                              );
                              _showStudyPlanModal(context);
                            },
                            icon: const Icon(Icons.event_note),
                            label: const Text(
                                'Generate Customized 7-Day Study Plan'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }

  void _showExplanationModal(BuildContext context, String topic) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final exp = _controller.explanation;

            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Conceptual Breakdown: $topic',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    if (exp == null)
                      const CircularProgressIndicator()
                    else ...[
                      Text(exp.explanation),
                      const SizedBox(height: 12),
                      const Text('Root Causes:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      ...exp.rootCauses.map((rc) => Text('• $rc')),
                      const SizedBox(height: 12),
                      const Text('Remedial Actions:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      ...exp.remedialActions.map((ra) => Text('• $ra')),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showStudyPlanModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final plan = _controller.studyPlan;

            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.event_note, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            plan?.title ?? 'Customized Study Plan',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const Divider(),
                      if (plan == null)
                        const Center(child: CircularProgressIndicator())
                      else
                        Expanded(
                          child: ListView(
                            controller: scrollController,
                            children: [
                              Text(
                                  'Daily Commitment: ${plan.suggestedHoursPerDay} hrs/day across ${plan.totalDays} Days',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              const Text('Daily Schedule:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              ...plan.dailyFocusAreas.map(
                                (df) => ListTile(
                                  dense: true,
                                  leading: const Icon(
                                      Icons.check_circle_outline,
                                      color: Colors.green),
                                  title: Text(df),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text('Key Milestones:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              ...plan.milestones.map((m) => Text('• $m')),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
