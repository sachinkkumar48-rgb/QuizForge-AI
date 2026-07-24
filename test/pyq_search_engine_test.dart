import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_upsc/models/bookmark.dart';
import 'package:quizforge_upsc/models/explanation.dart';
import 'package:quizforge_upsc/models/question.dart';
import 'package:quizforge_upsc/models/user_note.dart';
import 'package:quizforge_upsc/models/view/question_with_details.dart';
import 'package:quizforge_upsc/repositories/bookmark_repository.dart';
import 'package:quizforge_upsc/repositories/user_note_repository.dart';
import 'package:quizforge_upsc/services/search/inverted_index.dart';
import 'package:quizforge_upsc/services/search/pyq_search_engine.dart';
import 'package:quizforge_upsc/services/search/search_query.dart';

import 'dataset_importer_test.dart';

class InMemoryBookmarkRepository implements BookmarkRepository {
  final Map<String, Bookmark> bookmarks = {};

  Future<void> saveBookmark(Bookmark bookmark) async {
    bookmarks[bookmark.questionId] = bookmark;
  }

  @override
  Future<void> toggleBookmark(String questionId,
      {String category = 'General', String? noteSnippet}) async {
    if (bookmarks.containsKey(questionId)) {
      bookmarks.remove(questionId);
    } else {
      bookmarks[questionId] = Bookmark(
        bookmarkId: 'bm_$questionId',
        questionId: questionId,
        category: category,
        noteSnippet: noteSnippet,
      );
    }
  }

  @override
  Future<Bookmark?> getBookmark(String questionId) async {
    return bookmarks[questionId];
  }

  @override
  Future<void> removeBookmark(String questionId) async {
    bookmarks.remove(questionId);
  }

  @override
  Future<bool> isBookmarked(String questionId) async {
    return bookmarks.containsKey(questionId);
  }

  @override
  Future<List<Bookmark>> getBookmarks() async {
    return bookmarks.values.toList();
  }

  @override
  Future<List<String>> getBookmarkedQuestionIds() async {
    return bookmarks.keys.toList();
  }

  @override
  Future<void> clear() async {
    bookmarks.clear();
  }
}

class InMemoryUserNoteRepository implements UserNoteRepository {
  final Map<String, UserNote> notes = {};

  @override
  Future<void> saveNote(UserNote note) async {
    notes[note.questionId] = note;
  }

  @override
  Future<UserNote?> getNoteForQuestion(String questionId) async {
    return notes[questionId];
  }

  @override
  Future<List<UserNote>> getAllNotes() async {
    return notes.values.toList();
  }

  @override
  Future<List<UserNote>> searchNotes(String query) async {
    final qLower = query.toLowerCase();
    return notes.values
        .where((n) =>
            n.title.toLowerCase().contains(qLower) ||
            n.content.toLowerCase().contains(qLower))
        .toList();
  }

  @override
  Future<void> deleteNote(String questionId) async {
    notes.remove(questionId);
  }

  @override
  Future<void> clear() async {
    notes.clear();
  }
}

void main() {
  group('High-Performance Inverted Search Engine Tests', () {
    late InMemoryQuestionRepository questionRepo;
    late InMemoryExplanationRepository explanationRepo;
    late InMemoryBookmarkRepository bookmarkRepo;
    late InMemoryUserNoteRepository userNoteRepo;
    late PyqSearchEngine searchEngine;

    late QuestionWithDetails detail1;
    late QuestionWithDetails detail2;
    late QuestionWithDetails detail3;

    setUp(() async {
      questionRepo = InMemoryQuestionRepository();
      explanationRepo = InMemoryExplanationRepository();
      bookmarkRepo = InMemoryBookmarkRepository();
      userNoteRepo = InMemoryUserNoteRepository();

      searchEngine = PyqSearchEngine(
        questionRepository: questionRepo,
        explanationRepository: explanationRepo,
        bookmarkRepository: bookmarkRepo,
        userNoteRepository: userNoteRepo,
      );

      final q1 = Question(
        id: 'UPSC_PRE_GS1_2025_Q001',
        exam: 'UPSC CSE Prelims',
        year: 2025,
        paper: 'GS Paper I',
        subject: 'Polity',
        topic: 'Preamble & Fundamental Rights',
        difficulty: 'Medium',
        question:
            'Which article of the Indian Constitution guarantees Right to Equality?',
        options: ['Article 14', 'Article 19', 'Article 21', 'Article 32'],
        correctAnswer: 'Article 14',
        tags: ['Constitution', 'Fundamental Rights'],
      );

      final q2 = Question(
        id: 'UPSC_PRE_GS1_2024_Q002',
        exam: 'UPSC CSE Prelims',
        year: 2024,
        paper: 'GS Paper I',
        subject: 'Economy',
        topic: 'Monetary Policy & RBI',
        difficulty: 'Hard',
        question:
            'What is the primary objective of the Reserve Bank of India monetary policy?',
        options: [
          'Price stability',
          'Exchange rate fix',
          'Fiscal deficit',
          'Stock market'
        ],
        correctAnswer: 'Price stability',
        tags: ['Banking', 'Inflation'],
      );

      final q3 = Question(
        id: 'BPSC_PRE_GS_2024_Q001',
        exam: 'BPSC CCE',
        year: 2024,
        paper: 'General Studies',
        subject: 'History',
        topic: 'Bihar Modern History',
        difficulty: 'Easy',
        question: 'Who founded the Bihar Provincial Kisan Sabha in 1929?',
        options: [
          'Swami Sahajanand',
          'Rajendra Prasad',
          'Jayaprakash',
          'Kunwar Singh'
        ],
        correctAnswer: 'Swami Sahajanand',
        tags: ['Kisan Sabha', 'Modern Bihar'],
      );

      detail1 = QuestionWithDetails(
        question: q1,
        explanations: [
          Explanation(
            explanationId: 'exp_1',
            questionId: q1.id,
            explanationType: 'Official',
            content:
                'Article 14 guarantees equality before law and equal protection of laws.',
            source: 'Official UPSC Key',
          )
        ],
        userNote: UserNote(
          noteId: 'note_1',
          questionId: q1.id,
          content: 'Remember basic structure doctrine from Kesavananda case.',
        ),
        bookmark: Bookmark(bookmarkId: 'bm_${q1.id}', questionId: q1.id),
      );

      detail2 = QuestionWithDetails(
        question: q2,
        explanations: [
          Explanation(
            explanationId: 'exp_2',
            questionId: q2.id,
            explanationType: 'AI_Generated',
            content:
                'Section 45ZA mandates flexible inflation targeting framework.',
            source: 'Gemini AI',
          )
        ],
      );

      detail3 = QuestionWithDetails(
        question: q3,
        explanations: [],
      );

      await searchEngine.buildIndex(
        preloadedDetails: [detail1, detail2, detail3],
        vectorsMap: {
          q1.id: [1.0, 0.0, 0.0],
          q2.id: [0.0, 1.0, 0.0],
          q3.id: [0.0, 0.0, 1.0],
        },
      );
    });

    test('Search by Question text, Subject, Topic, Year, and Difficulty', () {
      final res1 =
          searchEngine.search(const SearchQuery(queryText: 'Equality'));
      expect(res1.totalMatches, equals(1));
      expect(res1.items.first.questionDetails.question.id,
          equals('UPSC_PRE_GS1_2025_Q001'));

      final res2 = searchEngine.search(const SearchQuery(subject: 'Economy'));
      expect(res2.totalMatches, equals(1));
      expect(res2.items.first.questionDetails.question.id,
          equals('UPSC_PRE_GS1_2024_Q002'));

      final res3 = searchEngine.search(const SearchQuery(year: 2024));
      expect(res3.totalMatches, equals(2));

      final res4 = searchEngine.search(const SearchQuery(difficulty: 'Hard'));
      expect(res4.totalMatches, equals(1));
      expect(res4.items.first.questionDetails.question.id,
          equals('UPSC_PRE_GS1_2024_Q002'));
    });

    test('Search across Explanations, User Notes, and Bookmarks', () {
      // Search in Explanation text
      final resExp =
          searchEngine.search(const SearchQuery(queryText: 'inflation'));
      expect(resExp.totalMatches, equals(1));
      expect(resExp.items.first.questionDetails.question.id,
          equals('UPSC_PRE_GS1_2024_Q002'));

      // Search in User Notes content
      final resNote =
          searchEngine.search(const SearchQuery(queryText: 'Kesavananda'));
      expect(resNote.totalMatches, equals(1));
      expect(resNote.items.first.questionDetails.question.id,
          equals('UPSC_PRE_GS1_2025_Q001'));

      // Filter by Bookmarked only
      final resBm =
          searchEngine.search(const SearchQuery(onlyBookmarked: true));
      expect(resBm.totalMatches, equals(1));
      expect(resBm.items.first.questionDetails.question.id,
          equals('UPSC_PRE_GS1_2025_Q001'));

      // Filter by Notes only
      final resNotesOnly =
          searchEngine.search(const SearchQuery(onlyWithNotes: true));
      expect(resNotesOnly.totalMatches, equals(1));
    });

    test('Fuzzy search matches misspelled query terms', () {
      final fuzzyRes = searchEngine
          .search(const SearchQuery(queryText: 'Equlity', enableFuzzy: true));
      expect(fuzzyRes.totalMatches, greaterThanOrEqualTo(1));
      expect(fuzzyRes.items.first.questionDetails.question.id,
          equals('UPSC_PRE_GS1_2025_Q001'));
    });

    test('Snippet highlighting computes valid offset ranges', () {
      final res = searchEngine.search(const SearchQuery(queryText: 'Equality'));
      expect(res.items.isNotEmpty, isTrue);

      final item = res.items.first;
      expect(item.matchSnippets.isNotEmpty, isTrue);
      final qSnippet =
          item.matchSnippets.firstWhere((s) => s.fieldName == 'question');
      expect(qSnippet.highlightRanges.isNotEmpty, isTrue);
      expect(qSnippet.snippetText, contains('Equality'));
    });

    test('Search by Tags, Topic, Subject, Year, and Difficulty filters', () {
      final resTagFilter =
          searchEngine.search(const SearchQuery(tags: ['Inflation']));
      expect(resTagFilter.totalMatches, equals(1));
      expect(resTagFilter.items.first.questionDetails.question.id,
          equals('UPSC_PRE_GS1_2024_Q002'));

      final resTopicFilter = searchEngine
          .search(const SearchQuery(topic: 'Monetary Policy & RBI'));
      expect(resTopicFilter.totalMatches, equals(1));

      final resSubjectFilter =
          searchEngine.search(const SearchQuery(subject: 'Polity'));
      expect(resSubjectFilter.totalMatches, equals(1));

      final resYearFilter = searchEngine.search(const SearchQuery(year: 2025));
      expect(resYearFilter.totalMatches, equals(1));

      final resDiffFilter =
          searchEngine.search(const SearchQuery(difficulty: 'Easy'));
      expect(resDiffFilter.totalMatches, equals(1));
    });

    test('Search by Bookmark Note Snippet and User Note Title', () async {
      final detailWithBmSnippet = QuestionWithDetails(
        question: Question(
          id: 'TEST_BM_001',
          exam: 'UPSC CSE Prelims',
          year: 2023,
          paper: 'GS Paper I',
          subject: 'Geography',
          topic: 'Physical Geography',
          difficulty: 'Medium',
          question: 'Consider the following statements regarding El Nino...',
          options: ['Option A', 'Option B', 'Option C', 'Option D'],
          correctAnswer: 'Option A',
          tags: ['Climate', 'Oceanography'],
        ),
        explanations: [],
        userNote: UserNote(
          noteId: 'note_geo',
          questionId: 'TEST_BM_001',
          title: 'Pacific Ocean Currents',
          content: 'Walker circulation weakening leads to El Nino phenomenon.',
          tags: ['Oceanography'],
        ),
        bookmark: Bookmark(
          bookmarkId: 'bm_geo',
          questionId: 'TEST_BM_001',
          category: 'High Priority',
          noteSnippet: 'Crucial for Mains GS3 environment section',
        ),
      );

      final localIndex = InvertedIndex();
      localIndex.index(detailWithBmSnippet);

      // Search in Bookmark Note Snippet
      final resBm =
          localIndex.query(const SearchQuery(queryText: 'environment'));
      expect(resBm.totalMatches, equals(1));
      expect(
          resBm.items.first.matchSnippets.any((s) => s.fieldName == 'bookmark'),
          isTrue);

      // Search in User Note Title
      final resNoteTitle =
          localIndex.query(const SearchQuery(queryText: 'Pacific Ocean'));
      expect(resNoteTitle.totalMatches, equals(1));
      expect(
          resNoteTitle.items.first.matchSnippets
              .any((s) => s.fieldName == 'userNote'),
          isTrue);
    });

    test(
        'Instant execution metric indicates index lookup avoids slow performance',
        () {
      final res =
          searchEngine.search(const SearchQuery(queryText: 'Constitution'));
      expect(res.executionTimeMs, lessThan(100));
    });

    test('Semantic Vector Cosine Similarity calculation', () {
      final simExact = InvertedIndex.cosineSimilarity([1.0, 0.0], [1.0, 0.0]);
      expect(simExact, equals(1.0));

      final simOrthogonal =
          InvertedIndex.cosineSimilarity([1.0, 0.0], [0.0, 1.0]);
      expect(simOrthogonal, equals(0.0));

      final vecQuery = const SearchQuery(queryVector: [1.0, 0.0, 0.0]);
      final vecRes = searchEngine.search(vecQuery);
      expect(vecRes.items.first.questionDetails.question.id,
          equals('UPSC_PRE_GS1_2025_Q001'));
    });
  });
}
