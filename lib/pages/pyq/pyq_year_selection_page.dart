import 'package:flutter/material.dart';

import '../../controllers/pyq_controller.dart';
import '../../models/pyq_question_model.dart';
import 'pyq_attempt_page.dart';

class PyqYearSelectionPage extends StatefulWidget {
  const PyqYearSelectionPage({super.key});

  @override
  State<PyqYearSelectionPage> createState() => _PyqYearSelectionPageState();
}

class _PyqYearSelectionPageState extends State<PyqYearSelectionPage> {
  final PyqController pyqController = PyqController();
  List<PyqQuestionModel> allQuestions = [];
  bool isLoading = true;

  final List<int> years =
      List.generate(15, (index) => 2025 - index); // 2025 down to 2011

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final list = await pyqController.getAllQuestions();
    if (mounted) {
      setState(() {
        allQuestions = list;
        isLoading = false;
      });
    }
  }

  void _startYearSession(int year) async {
    final questionsForYear = allQuestions.where((q) => q.year == year).toList();

    if (questionsForYear.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("No questions loaded for year $year yet."),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PyqAttemptPage(
          questions: questionsForYear,
          title: "UPSC CSE Prelims $year",
        ),
      ),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Year-Wise PYQs"),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.3,
                ),
                itemCount: years.length,
                itemBuilder: (context, index) {
                  final year = years[index];
                  final yearQuestions =
                      allQuestions.where((q) => q.year == year).toList();
                  final attempted =
                      yearQuestions.where((q) => q.isAttempted).length;
                  final count = yearQuestions.length;

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: Colors.deepPurple.withValues(alpha: 0.2),
                      ),
                    ),
                    color: Colors.deepPurple.withValues(alpha: 0.04),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _startYearSession(year),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "$year",
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward,
                                  color: Colors.deepPurple,
                                  size: 20,
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "UPSC Prelims Paper 1",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  count > 0
                                      ? "$attempted / $count Attempted"
                                      : "Import Available",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
