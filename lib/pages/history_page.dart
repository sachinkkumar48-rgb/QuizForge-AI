import 'package:flutter/material.dart';
import '../models/quiz_analytics.dart';
import '../models/quiz_attempt.dart';
import '../repositories/quiz_history_repository.dart';
import 'attempt_summary_page.dart';

enum SortOption {
  newest,
  oldest,
  highestAccuracy,
  lowestAccuracy,
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final QuizHistoryRepository _repository = QuizHistoryRepository();
  List<QuizAttempt> _allAttempts = [];
  bool _isLoading = true;
  String _searchQuery = "";
  SortOption _sortBy = SortOption.newest;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final attempts = await _repository.getAttempts();
      setState(() {
        _allAttempts = attempts;
        _invalidateFilterCache();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading history: $e")),
        );
      }
    }
  }

  Future<void> _deleteAttempt(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Attempt"),
        content: const Text("Are you sure you want to delete this attempt?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _repository.deleteAttempt(id);
        await _loadHistory();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error deleting attempt: $e")),
          );
        }
      }
    }
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear History"),
        content: const Text(
            "Are you sure you want to delete all quiz history? This cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Clear All"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _repository.clearHistory();
        await _loadHistory();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error clearing history: $e")),
          );
        }
      }
    }
  }

  List<QuizAttempt>? _cachedFilteredAttempts;

  void _invalidateFilterCache() {
    _cachedFilteredAttempts = null;
  }

  List<QuizAttempt> get _filteredAttempts {
    if (_cachedFilteredAttempts != null) {
      return _cachedFilteredAttempts!;
    }

    var list = _allAttempts.where((attempt) {
      return attempt.sourceName
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
    }).toList();

    switch (_sortBy) {
      case SortOption.newest:
        list.sort((a, b) => b.completedAt.compareTo(a.completedAt));
        break;
      case SortOption.oldest:
        list.sort((a, b) => a.completedAt.compareTo(b.completedAt));
        break;
      case SortOption.highestAccuracy:
        list.sort(
            (a, b) => b.analytics.accuracy.compareTo(a.analytics.accuracy));
        break;
      case SortOption.lowestAccuracy:
        list.sort(
            (a, b) => a.analytics.accuracy.compareTo(b.analytics.accuracy));
        break;
    }
    _cachedFilteredAttempts = list;
    return list;
  }

  Color _getPerformanceColor(PerformanceLevel level) {
    switch (level) {
      case PerformanceLevel.excellent:
        return Colors.green;
      case PerformanceLevel.good:
        return Colors.blue;
      case PerformanceLevel.average:
        return Colors.orange;
      case PerformanceLevel.needsImprovement:
        return Colors.red;
    }
  }

  String _getPerformanceText(PerformanceLevel level) {
    switch (level) {
      case PerformanceLevel.excellent:
        return "Excellent";
      case PerformanceLevel.good:
        return "Good";
      case PerformanceLevel.average:
        return "Average";
      case PerformanceLevel.needsImprovement:
        return "Needs Improvement";
    }
  }

  String _formatDate(DateTime dateTime) {
    final year = dateTime.year;
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return "$year-$month-$day";
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredAttempts;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Quiz History"),
        centerTitle: true,
        actions: [
          if (_allAttempts.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.red),
              tooltip: "Clear All History",
              onPressed: _clearHistory,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 600;

                  final searchBar = TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                        _invalidateFilterCache();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Search by PDF/Test name...",
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = "";
                                  _invalidateFilterCache();
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 16),
                    ),
                  );

                  final sortDropdown = DropdownButtonFormField<SortOption>(
                    initialValue: _sortBy,
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _sortBy = val;
                          _invalidateFilterCache();
                        });
                      }
                    },
                    decoration: InputDecoration(
                      labelText: "Sort By",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 12),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: SortOption.newest, child: Text("Newest")),
                      DropdownMenuItem(
                          value: SortOption.oldest, child: Text("Oldest")),
                      DropdownMenuItem(
                          value: SortOption.highestAccuracy,
                          child: Text("Highest Accuracy")),
                      DropdownMenuItem(
                          value: SortOption.lowestAccuracy,
                          child: Text("Lowest Accuracy")),
                    ],
                  );

                  if (isWide) {
                    return Row(
                      children: [
                        Expanded(flex: 3, child: searchBar),
                        const SizedBox(width: 16),
                        Expanded(flex: 2, child: sortDropdown),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        searchBar,
                        const SizedBox(height: 12),
                        sortDropdown,
                      ],
                    );
                  }
                },
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _searchQuery.isNotEmpty
                                    ? Icons.search_off
                                    : Icons.history_edu,
                                size: 80,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? "No matching attempts found."
                                    : "No quiz history yet.",
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? "Try changing your search term."
                                    : "Complete a quiz to see it here.",
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final attempt = filtered[index];
                            final color = _getPerformanceColor(
                                attempt.analytics.performanceLevel);
                            final perfText = _getPerformanceText(
                                attempt.analytics.performanceLevel);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          AttemptSummaryPage(attempt: attempt),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      // Circle accuracy indicator
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: color, width: 2),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          "${attempt.analytics.accuracy.toStringAsFixed(0)}%",
                                          style: TextStyle(
                                            color: color,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              attempt.sourceName,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "Date: ${_formatDate(attempt.completedAt)}",
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 4,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: color.withValues(
                                                        alpha: 0.12),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Text(
                                                    perfText,
                                                    style: TextStyle(
                                                      color: color,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade100,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    border: Border.all(
                                                        color: Colors
                                                            .grey.shade300),
                                                  ),
                                                  child: Text(
                                                    "${attempt.analytics.totalQuestions} Questions",
                                                    style: TextStyle(
                                                      color:
                                                          Colors.grey.shade800,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade100,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    border: Border.all(
                                                        color: Colors
                                                            .grey.shade300),
                                                  ),
                                                  child: Text(
                                                    attempt.analytics
                                                        .formattedTimeSpent,
                                                    style: TextStyle(
                                                      color:
                                                          Colors.grey.shade800,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            color: Colors.grey),
                                        onPressed: () =>
                                            _deleteAttempt(attempt.id),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
