import 'package:flutter/material.dart';

import '../controllers/quiz_session_controller.dart';
import '../models/quiz_model.dart';
import 'result_page.dart';
import 'review_page.dart';

class QuizPage extends StatefulWidget {
  final List<QuizQuestion> questions;
  final String sourceName;

  const QuizPage({
    super.key,
    required this.questions,
    required this.sourceName,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  late final QuizSessionController controller;

  @override
  void initState() {
    super.initState();
    controller = QuizSessionController(
      sourceName: widget.sourceName,
      questions: widget.questions,
      onStateChanged: () {
        setState(() {});
      },
      onTimeUp: (analytics) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultPage(
              analytics: analytics,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Widget buildOption(String option) {
    final bool selected =
        controller.answers[controller.currentQuestionIndex] == option;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(60),
            backgroundColor:
                selected ? Colors.deepPurple : Colors.deepPurple.shade100,
            foregroundColor: selected ? Colors.white : Colors.black87,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: () => controller.selectAnswer(option),
          child: Text(
            option,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (controller.questions.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text("No questions available."),
        ),
      );
    }

    final progress =
        (controller.currentQuestionIndex + 1) / controller.questions.length;
    final currentStatus =
        controller.statuses[controller.currentQuestionIndex] ??
            QuestionStatus.notVisited;
    final question = controller.currentQuestion;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Question ${controller.currentQuestionIndex + 1}/${controller.questions.length}",
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.rate_review_outlined,
                color: Colors.deepPurple),
            tooltip: "Review",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReviewPage(controller: controller),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Icon(Icons.timer, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text(
                  controller.formattedRemainingTime,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLargeScreen = constraints.maxWidth > 800;

            final mainContent = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(20),
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          question.question,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ...question.options.map(
                          buildOption,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: controller.toggleMarkForReview,
                          icon: Icon(
                            currentStatus == QuestionStatus.markedForReview
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                          ),
                          label: Text(
                            currentStatus == QuestionStatus.markedForReview
                                ? "Marked for Review"
                                : "Mark for Review",
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: controller.currentQuestionIndex == 0
                                    ? null
                                    : controller.previousQuestion,
                                icon: const Icon(
                                  Icons.arrow_back,
                                ),
                                label: const Text(
                                  "Previous",
                                ),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(56),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () {
                                  controller.nextQuestion(
                                    onFinished: (analytics) {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ResultPage(
                                            analytics: analytics,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                                icon: Icon(
                                  controller.currentQuestionIndex ==
                                          controller.questions.length - 1
                                      ? Icons.check_circle
                                      : Icons.arrow_forward,
                                ),
                                label: Text(
                                  controller.currentQuestionIndex ==
                                          controller.questions.length - 1
                                      ? "Finish Quiz"
                                      : "Next",
                                ),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(56),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            controller.answers[
                                        controller.currentQuestionIndex] ==
                                    null
                                ? "Not Attempted"
                                : "Answer Selected",
                            style: TextStyle(
                              color: controller.answers[
                                          controller.currentQuestionIndex] ==
                                      null
                                  ? Colors.orange
                                  : Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );

            Widget paletteWidget(double buttonSize) {
              return Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.grid_on,
                              color: Colors.deepPurple, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "Question Palette",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children:
                            List.generate(controller.questions.length, (index) {
                          final status = controller.statuses[index] ??
                              QuestionStatus.notVisited;
                          final isCurrent =
                              index == controller.currentQuestionIndex;

                          Color bgColor;
                          Color fgColor = Colors.white;

                          switch (status) {
                            case QuestionStatus.notVisited:
                              bgColor = Colors.grey.shade300;
                              fgColor = Colors.black87;
                              break;
                            case QuestionStatus.visited:
                              bgColor = Colors.amber.shade600;
                              break;
                            case QuestionStatus.answered:
                              bgColor = Colors.green.shade600;
                              break;
                            case QuestionStatus.markedForReview:
                              bgColor = Colors.purple.shade600;
                              break;
                          }

                          return InkWell(
                            onTap: () => controller.jumpToQuestion(index),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: buttonSize,
                              height: buttonSize,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(10),
                                border: isCurrent
                                    ? Border.all(
                                        color: Colors.deepPurple,
                                        width: 3.5,
                                      )
                                    : Border.all(
                                        color: Colors.transparent,
                                        width: 3.5,
                                      ),
                              ),
                              child: Text(
                                "${index + 1}",
                                style: TextStyle(
                                  color: fgColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          _LegendItem(
                              color: Colors.grey.shade300, text: "Not Visited"),
                          _LegendItem(
                              color: Colors.amber.shade600, text: "Visited"),
                          _LegendItem(
                              color: Colors.green.shade600, text: "Answered"),
                          _LegendItem(
                              color: Colors.purple.shade600, text: "Review"),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: isLargeScreen
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: mainContent,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: paletteWidget(44),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        mainContent,
                        const SizedBox(height: 16),
                        paletteWidget(40),
                        const SizedBox(height: 24),
                        Center(
                          child: Text(
                            "UPSC Practice Mode • You may skip questions",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendItem({
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
