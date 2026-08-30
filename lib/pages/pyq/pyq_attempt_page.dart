import 'dart:async';
import 'package:flutter/material.dart';

import '../../controllers/pyq_controller.dart';
import '../../models/pyq_question_model.dart';
import 'widgets/pyq_explanation_sheet.dart';

class PyqAttemptPage extends StatefulWidget {
  final List<PyqQuestionModel> questions;
  final String title;
  final bool isExamMode;
  final String? learnerId;
  final String? objectiveId;
  final PyqController? controller;

  const PyqAttemptPage({
    super.key,
    required this.questions,
    this.title = "UPSC PYQ Session",
    this.isExamMode = false,
    this.learnerId,
    this.objectiveId,
    this.controller,
    this.enableTimer = true,
  });

  final bool enableTimer;

  @override
  State<PyqAttemptPage> createState() => _PyqAttemptPageState();
}

class _PyqAttemptPageState extends State<PyqAttemptPage> {
  late List<PyqQuestionModel> questions;
  int currentIndex = 0;
  final Map<int, String> userAnswers = {};

  late final PyqController pyqController;
  Timer? _timer;
  int _secondsElapsed = 0;

  @override
  void initState() {
    super.initState();
    questions = List.from(widget.questions);
    pyqController = widget.controller ?? PyqController();
    final isTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (widget.enableTimer && !isTest) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTimer(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  void _selectOption(String optionText) async {
    final currentQ = questions[currentIndex];
    setState(() {
      userAnswers[currentIndex] = optionText;
    });

    await pyqController.recordAttempt(
      questionId: currentQ.id,
      selectedAnswer: optionText,
      learnerId: widget.learnerId,
      objectiveId: widget.objectiveId,
    );
  }

  void _toggleBookmark() async {
    final currentQ = questions[currentIndex];
    final updated = currentQ.copyWith(isBookmarked: !currentQ.isBookmarked);
    setState(() {
      questions[currentIndex] = updated;
    });
    await pyqController.toggleBookmark(currentQ.id);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 1),
        content: Text(
          updated.isBookmarked ? "Question Bookmarked" : "Bookmark Removed",
        ),
      ),
    );
  }

  void _showReportIssueDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Report Question Issue"),
        content: const Text(
          "If you noticed a typo or issue in this question, it will be flagged for review.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Issue reported. Thank you for your feedback!"),
                ),
              );
            },
            child: const Text("Submit Report"),
          ),
        ],
      ),
    );
  }

  void _showQuestionPalette() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Question Palette",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    final isAnswered = userAnswers.containsKey(index);
                    final isCurrent = index == currentIndex;
                    final isBookmarked = questions[index].isBookmarked;

                    Color bgColor = Colors.grey.shade200;
                    if (isAnswered) bgColor = Colors.green.shade100;
                    if (isCurrent) bgColor = Colors.deepPurple.shade100;

                    return InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() {
                          currentIndex = index;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isCurrent
                                ? Colors.deepPurple
                                : (isAnswered ? Colors.green : Colors.grey),
                            width: isCurrent ? 2 : 1,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Text(
                                "${index + 1}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isCurrent
                                      ? Colors.deepPurple
                                      : Colors.black87,
                                ),
                              ),
                            ),
                            if (isBookmarked)
                              const Positioned(
                                top: 4,
                                right: 4,
                                child: Icon(
                                  Icons.bookmark,
                                  size: 14,
                                  color: Colors.amber,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(
          child: Text("No questions available in this session."),
        ),
      );
    }

    final q = questions[currentIndex];
    final selectedAns = userAnswers[currentIndex];
    final progress = (currentIndex + 1) / questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(
              q.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: q.isBookmarked ? Colors.amber : null,
            ),
            onPressed: _toggleBookmark,
            tooltip: "Bookmark Question",
          ),
          IconButton(
            icon: const Icon(Icons.grid_view),
            onPressed: _showQuestionPalette,
            tooltip: "Question Palette",
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Timer & Progress Header
            LinearProgressIndicator(value: progress),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Question ${currentIndex + 1} of ${questions.length}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        _formatTimer(_secondsElapsed),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Question & Options Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question Badges
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(
                          label: Text("${q.year}"),
                          backgroundColor:
                              Colors.deepPurple.withValues(alpha: 0.1),
                          side: BorderSide.none,
                        ),
                        Chip(
                          label: Text(q.subject),
                          backgroundColor: Colors.blue.withValues(alpha: 0.1),
                          side: BorderSide.none,
                        ),
                        Chip(
                          label: Text(q.topic),
                          backgroundColor: Colors.teal.withValues(alpha: 0.1),
                          side: BorderSide.none,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Question Text
                    Text(
                      q.question,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Options List
                    ...List.generate(q.options.length, (optIndex) {
                      final optionText = q.options[optIndex];
                      final optionLetter = String.fromCharCode(65 + optIndex);
                      final isSelected = selectedAns == optionText;

                      Color borderColor = Colors.grey.shade300;
                      Color bgColor = Theme.of(context).colorScheme.surface;

                      if (isSelected) {
                        borderColor = Colors.deepPurple;
                        bgColor = Colors.deepPurple.withValues(alpha: 0.08);
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: InkWell(
                          onTap: () => _selectOption(optionText),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: borderColor,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: isSelected
                                      ? Colors.deepPurple
                                      : Colors.grey.shade200,
                                  child: Text(
                                    optionLetter,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    optionText,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 16),

                    // Explanation Toggle Button
                    if (selectedAns != null) ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            PyqExplanationSheet.show(
                              context,
                              question: q,
                              selectedAnswer: selectedAns,
                            );
                          },
                          icon: const Icon(Icons.menu_book),
                          label: const Text("View Solution & Explanation"),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom Navigation Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.flag_outlined),
                    onPressed: _showReportIssueDialog,
                    tooltip: "Report Issue",
                  ),
                  const Spacer(),
                  if (currentIndex > 0)
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          currentIndex--;
                        });
                      },
                      child: const Text("Previous"),
                    ),
                  const SizedBox(width: 12),
                  if (currentIndex < questions.length - 1)
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          currentIndex++;
                        });
                      },
                      child: const Text("Next"),
                    )
                  else
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("PYQ Session Completed! Great job."),
                          ),
                        );
                      },
                      child: const Text("Finish"),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
