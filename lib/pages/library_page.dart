import 'package:flutter/material.dart';
import '../models/quiz_source.dart';
import '../repositories/quiz_source_repository.dart';
import '../repositories/quiz_history_repository.dart';
import '../repositories/quiz_session_repository.dart';
import '../services/cache_service.dart';
import 'quiz_page.dart';

enum SortOption {
  newestImport,
  oldestImport,
  nameAZ,
  mostAttempted,
  recentlyUsed,
  favoritesFirst,
}

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final QuizSourceRepository _repository = QuizSourceRepository();
  List<QuizSource> _allSources = [];
  bool _isLoading = true;
  String _searchQuery = "";
  SortOption _sortBy = SortOption.newestImport;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSources();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSources() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final sources = await _repository.getSources();
      setState(() {
        _allSources = sources;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading PDF library: $e")),
        );
      }
    }
  }

  Future<void> _toggleFavorite(QuizSource source) async {
    try {
      await _repository.toggleFavorite(source.id);
      await _loadSources();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating favorite: $e")),
        );
      }
    }
  }

  Future<void> _renameSource(QuizSource source) async {
    final controller = TextEditingController(text: source.name);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Rename PDF"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "PDF Name",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Rename"),
          ),
        ],
      ),
    );

    if (confirm == true && controller.text.trim().isNotEmpty) {
      try {
        final newName = controller.text.trim();
        final updated = source.copyWith(name: newName);
        await _repository.updateSource(updated);

        // Rename corresponding attempts
        final historyRepo = QuizHistoryRepository();
        final attempts = await historyRepo.getAttempts();
        for (final attempt in attempts) {
          if (attempt.sourceName == source.name) {
            final updatedAttempt = attempt.copyWith(sourceName: newName);
            await historyRepo.saveAttempt(updatedAttempt);
          }
        }

        // Rename active session
        final sessionRepo = QuizSessionRepository();
        final session = await sessionRepo.loadSession();
        if (session != null && session.sourceName == source.name) {
          final updatedSession = session.copyWith(sourceName: newName);
          await sessionRepo.saveSession(updatedSession);
        }

        await _loadSources();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error renaming: $e")),
          );
        }
      }
    }
  }

  Future<void> _deleteSource(QuizSource source) async {
    bool deleteHistory = true;
    bool deleteSession = true;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("Delete PDF Asset"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Are you sure you want to delete '${source.name}'?"),
              const SizedBox(height: 16),
              CheckboxListTile(
                value: deleteHistory,
                title: const Text("Delete quiz history for this PDF"),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  setStateDialog(() {
                    deleteHistory = val ?? false;
                  });
                },
              ),
              CheckboxListTile(
                value: deleteSession,
                title: const Text("Delete unfinished sessions for this PDF"),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  setStateDialog(() {
                    deleteSession = val ?? false;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text("Delete"),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      try {
        await _repository.deleteSource(source.id);

        if (deleteHistory) {
          final historyRepo = QuizHistoryRepository();
          final attempts = await historyRepo.getAttempts();
          for (final attempt in attempts) {
            if (attempt.sourceName == source.name) {
              await historyRepo.deleteAttempt(attempt.id);
            }
          }
        }

        if (deleteSession) {
          final sessionRepo = QuizSessionRepository();
          final session = await sessionRepo.loadSession();
          if (session != null && session.sourceName == source.name) {
            await sessionRepo.deleteSession();
          }
        }

        await _loadSources();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error deleting: $e")),
          );
        }
      }
    }
  }

  Future<void> _openQuiz(QuizSource source) async {
    try {
      final questions = await CacheService.loadQuiz(source.id);
      if (questions == null || questions.isEmpty) {
        throw Exception("Could not load questions for this PDF from cache.");
      }

      final updated = source.copyWith(lastOpenedAt: DateTime.now());
      await _repository.updateSource(updated);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuizPage(
            questions: questions,
            sourceName: source.name,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error opening quiz: $e")),
        );
      }
    }
  }

  List<QuizSource> get _filteredSources {
    var list = _allSources.where((s) {
      return s.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    switch (_sortBy) {
      case SortOption.newestImport:
        list.sort((a, b) => b.importedAt.compareTo(a.importedAt));
        break;
      case SortOption.oldestImport:
        list.sort((a, b) => a.importedAt.compareTo(b.importedAt));
        break;
      case SortOption.nameAZ:
        list.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case SortOption.mostAttempted:
        list.sort((a, b) => b.attemptCount.compareTo(a.attemptCount));
        break;
      case SortOption.recentlyUsed:
        list.sort((a, b) {
          final timeA =
              a.lastOpenedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final timeB =
              b.lastOpenedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return timeB.compareTo(timeA);
        });
        break;
      case SortOption.favoritesFirst:
        list.sort((a, b) {
          if (a.favorite && !b.favorite) return -1;
          if (!a.favorite && b.favorite) return 1;
          return b.importedAt.compareTo(a.importedAt);
        });
        break;
    }
    return list;
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return "Never";
    final year = dateTime.year;
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return "$year-$month-$day";
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredSources;

    return Scaffold(
      appBar: AppBar(
        title: const Text("PDF Library"),
        centerTitle: true,
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
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Search PDF library...",
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = "";
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
                          value: SortOption.newestImport,
                          child: Text("Newest Import")),
                      DropdownMenuItem(
                          value: SortOption.oldestImport,
                          child: Text("Oldest Import")),
                      DropdownMenuItem(
                          value: SortOption.nameAZ, child: Text("Name A–Z")),
                      DropdownMenuItem(
                          value: SortOption.mostAttempted,
                          child: Text("Most Attempted")),
                      DropdownMenuItem(
                          value: SortOption.recentlyUsed,
                          child: Text("Recently Used")),
                      DropdownMenuItem(
                          value: SortOption.favoritesFirst,
                          child: Text("Favorites First")),
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
                                    : Icons.library_books,
                                size: 80,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? "No matching PDFs found."
                                    : "Your PDF library is empty.",
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? "Try another name."
                                    : "Import PDFs from the Home screen.",
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
                            final source = filtered[index];

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                         CircleAvatar(
                                           backgroundColor:
                                               Colors.deepPurple.shade100,
                                           foregroundColor: Colors.deepPurple,
                                           child: const Icon(Icons.picture_as_pdf),
                                         ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                source.name,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                "Imported: ${_formatDate(source.importedAt)}",
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            source.favorite
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color: source.favorite
                                                ? Colors.red
                                                : Colors.grey,
                                          ),
                                          onPressed: () =>
                                              _toggleFavorite(source),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        _Badge(
                                          text:
                                              "${source.questionCount} Questions",
                                          icon: Icons.question_mark,
                                        ),
                                        const SizedBox(width: 8),
                                        _Badge(
                                          text:
                                              "${source.attemptCount} Attempts",
                                          icon: Icons.history_edu,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Text(
                                          "Last Attempt: ${_formatDate(source.lastAttemptedAt)}",
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600),
                                        ),
                                        const Spacer(),
                                        PopupMenuButton<String>(
                                          onSelected: (action) {
                                            if (action == 'rename') {
                                              _renameSource(source);
                                            } else if (action == 'delete') {
                                              _deleteSource(source);
                                            }
                                          },
                                          itemBuilder: (context) => const [
                                            PopupMenuItem(
                                              value: 'rename',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit, size: 18),
                                                  SizedBox(width: 8),
                                                  Text("Rename"),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete,
                                                      color: Colors.red,
                                                      size: 18),
                                                  SizedBox(width: 8),
                                                  Text("Delete",
                                                      style: TextStyle(
                                                          color: Colors.red)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 8),
                                        FilledButton.icon(
                                          icon: const Icon(Icons.play_arrow,
                                              size: 16),
                                          label: const Text("Open Quiz"),
                                          onPressed: () => _openQuiz(source),
                                        ),
                                      ],
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
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final IconData icon;

  const _Badge({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade800),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
