import 'package:flutter/material.dart';

import '../../controllers/pyq_controller.dart';
import '../../models/pyq_question_model.dart';
import 'pyq_attempt_page.dart';

class PyqSearchPage extends StatefulWidget {
  const PyqSearchPage({super.key});

  @override
  State<PyqSearchPage> createState() => _PyqSearchPageState();
}

class _PyqSearchPageState extends State<PyqSearchPage> {
  final PyqController pyqController = PyqController();
  final TextEditingController searchController = TextEditingController();

  List<PyqQuestionModel> results = [];
  bool isLoading = false;

  int? selectedYear;
  String? selectedSubject;
  String? selectedDifficulty;
  bool onlyBookmarked = false;
  bool onlyIncorrect = false;
  bool unattempted = false;

  final List<String> subjects = [
    "All Subjects",
    "Polity",
    "History",
    "Economy",
    "Geography",
    "Environment",
    "Science & Technology",
  ];

  final List<String> difficulties = [
    "All Difficulties",
    "Easy",
    "Medium",
    "Hard"
  ];

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  Future<void> _performSearch() async {
    setState(() {
      isLoading = true;
    });

    final list = await pyqController.searchQuestions(
      query: searchController.text,
      year: selectedYear,
      subject: (selectedSubject == null || selectedSubject == "All Subjects")
          ? null
          : selectedSubject,
      difficulty: (selectedDifficulty == null ||
              selectedDifficulty == "All Difficulties")
          ? null
          : selectedDifficulty,
      onlyBookmarked: onlyBookmarked ? true : null,
      onlyIncorrect: onlyIncorrect ? true : null,
      unattempted: unattempted ? true : null,
    );

    if (mounted) {
      setState(() {
        results = list;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Search PYQ Database"),
        centerTitle: true,
        actions: [
          if (results.isNotEmpty)
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PyqAttemptPage(
                      questions: results,
                      title: "Filtered PYQ Search Results",
                    ),
                  ),
                );
              },
              child: const Text("Practice Results"),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar & Filters Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: "Search by keyword, concept, or topic...",
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              searchController.clear();
                              _performSearch();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onChanged: (_) => _performSearch(),
                ),
                const SizedBox(height: 12),

                // Filter Chips Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: Text(selectedYear == null
                            ? "Year: All"
                            : "Year: $selectedYear"),
                        selected: selectedYear != null,
                        onSelected: (_) {
                          _showYearFilterPicker();
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: Text(selectedSubject ?? "Subject: All"),
                        selected: selectedSubject != null &&
                            selectedSubject != "All Subjects",
                        onSelected: (_) {
                          _showSubjectFilterPicker();
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: Text(selectedDifficulty ?? "Difficulty: All"),
                        selected: selectedDifficulty != null &&
                            selectedDifficulty != "All Difficulties",
                        onSelected: (_) {
                          _showDifficultyFilterPicker();
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text("Bookmarked"),
                        selected: onlyBookmarked,
                        onSelected: (val) {
                          setState(() => onlyBookmarked = val);
                          _performSearch();
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text("Incorrect"),
                        selected: onlyIncorrect,
                        onSelected: (val) {
                          setState(() => onlyIncorrect = val);
                          _performSearch();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Results List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.search_off,
                                size: 60, color: Colors.grey),
                            SizedBox(height: 12),
                            Text("No questions match your filter criteria."),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final q = results[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            child: ListTile(
                              title: Text(
                                q.question,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  "${q.year} • ${q.subject} • ${q.topic}",
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              trailing: Icon(
                                q.isBookmarked
                                    ? Icons.bookmark
                                    : Icons.chevron_right,
                                color:
                                    q.isBookmarked ? Colors.amber : Colors.grey,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PyqAttemptPage(
                                      questions: [q],
                                      title: "PYQ Details",
                                    ),
                                  ),
                                ).then((_) => _performSearch());
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showYearFilterPicker() {
    final years = [null, ...List.generate(15, (index) => 2025 - index)];
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return ListView(
          shrinkWrap: true,
          children: years.map((y) {
            return ListTile(
              title: Text(y == null ? "All Years" : "$y"),
              selected: selectedYear == y,
              onTap: () {
                Navigator.pop(ctx);
                setState(() => selectedYear = y);
                _performSearch();
              },
            );
          }).toList(),
        );
      },
    );
  }

  void _showSubjectFilterPicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return ListView(
          shrinkWrap: true,
          children: subjects.map((s) {
            return ListTile(
              title: Text(s),
              selected: selectedSubject == s,
              onTap: () {
                Navigator.pop(ctx);
                setState(() => selectedSubject = s);
                _performSearch();
              },
            );
          }).toList(),
        );
      },
    );
  }

  void _showDifficultyFilterPicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return ListView(
          shrinkWrap: true,
          children: difficulties.map((d) {
            return ListTile(
              title: Text(d),
              selected: selectedDifficulty == d,
              onTap: () {
                Navigator.pop(ctx);
                setState(() => selectedDifficulty = d);
                _performSearch();
              },
            );
          }).toList(),
        );
      },
    );
  }
}
