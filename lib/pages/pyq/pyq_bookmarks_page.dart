import 'package:flutter/material.dart';

import '../../controllers/pyq_controller.dart';
import '../../models/pyq_question_model.dart';
import 'pyq_attempt_page.dart';

class PyqBookmarksPage extends StatefulWidget {
  const PyqBookmarksPage({super.key});

  @override
  State<PyqBookmarksPage> createState() => _PyqBookmarksPageState();
}

class _PyqBookmarksPageState extends State<PyqBookmarksPage> {
  final PyqController pyqController = PyqController();
  List<PyqQuestionModel> bookmarks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final list = await pyqController.getBookmarkedQuestions();
    if (mounted) {
      setState(() {
        bookmarks = list;
        isLoading = false;
      });
    }
  }

  void _removeBookmark(String id) async {
    await pyqController.toggleBookmark(id);
    await _loadBookmarks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bookmarked PYQs"),
        centerTitle: true,
        actions: [
          if (bookmarks.isNotEmpty)
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PyqAttemptPage(
                      questions: bookmarks,
                      title: "Bookmarked PYQs Practice",
                    ),
                  ),
                ).then((_) => _loadBookmarks());
              },
              child: const Text(
                "Practice All",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : bookmarks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.bookmark_outline,
                          size: 70, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        "No Bookmarked Questions Yet",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Bookmark questions during practice to revise them anytime.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bookmarks.length,
                  itemBuilder: (context, index) {
                    final q = bookmarks[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: ListTile(
                        title: Text(
                          q.question,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text("${q.year} • ${q.subject} • ${q.topic}"),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.bookmark, color: Colors.amber),
                          onPressed: () => _removeBookmark(q.id),
                          tooltip: "Remove Bookmark",
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PyqAttemptPage(
                                questions: [q],
                                title: "Bookmarked PYQ",
                              ),
                            ),
                          ).then((_) => _loadBookmarks());
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
