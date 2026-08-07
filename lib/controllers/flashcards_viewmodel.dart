import 'dart:math';
import 'package:flutter/foundation.dart';

/// DTO representing a GARUDA AI Generated Flashcard
class FlashcardDto {
  final String id;
  final String question;
  final String answer;
  final String hint;
  final String difficulty; // 'Easy', 'Medium', 'Hard'
  final String topic;
  final List<String> tags;
  final String source; // 'PDF Grounded' or 'GARUDA Tutor'
  final String? pdfDocumentName;
  final int? pageNumber;
  final String? citation;
  final bool isBookmarked;
  final bool isFavorite;
  final bool isKnown;
  final bool isInRevisionQueue;
  final double easeFactor; // SM-2 ease factor (default 2.5)
  final int intervalDays; // SM-2 interval in days
  final int repetitions; // SM-2 repetition count
  final DateTime? nextReviewDate;

  const FlashcardDto({
    required this.id,
    required this.question,
    required this.answer,
    required this.hint,
    required this.difficulty,
    required this.topic,
    required this.tags,
    required this.source,
    this.pdfDocumentName,
    this.pageNumber,
    this.citation,
    this.isBookmarked = false,
    this.isFavorite = false,
    this.isKnown = false,
    this.isInRevisionQueue = false,
    this.easeFactor = 2.5,
    this.intervalDays = 1,
    this.repetitions = 0,
    this.nextReviewDate,
  });

  bool get isPdfGrounded => pdfDocumentName != null && pdfDocumentName!.isNotEmpty;

  FlashcardDto copyWith({
    String? id,
    String? question,
    String? answer,
    String? hint,
    String? difficulty,
    String? topic,
    List<String>? tags,
    String? source,
    String? pdfDocumentName,
    int? pageNumber,
    String? citation,
    bool? isBookmarked,
    bool? isFavorite,
    bool? isKnown,
    bool? isInRevisionQueue,
    double? easeFactor,
    int? intervalDays,
    int? repetitions,
    DateTime? nextReviewDate,
  }) {
    return FlashcardDto(
      id: id ?? this.id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      hint: hint ?? this.hint,
      difficulty: difficulty ?? this.difficulty,
      topic: topic ?? this.topic,
      tags: tags ?? this.tags,
      source: source ?? this.source,
      pdfDocumentName: pdfDocumentName ?? this.pdfDocumentName,
      pageNumber: pageNumber ?? this.pageNumber,
      citation: citation ?? this.citation,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isFavorite: isFavorite ?? this.isFavorite,
      isKnown: isKnown ?? this.isKnown,
      isInRevisionQueue: isInRevisionQueue ?? this.isInRevisionQueue,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      repetitions: repetitions ?? this.repetitions,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
    );
  }
}

/// DTO representing GARUDA AI Smart Notes
class SmartNoteDto {
  final String id;
  final String title;
  final String topic;
  final String aiSummary;
  final List<String> keyPoints;
  final List<String> importantFacts;
  final Map<String, String> definitions;
  final List<Map<String, String>> timeline; // e.g. [{"year": "1950", "event": "Constitution Enacted"}]
  final List<List<String>> tableData; // e.g. [Header, Row1, Row2]
  final List<String> examples;
  final List<String> importantQuotes;
  final String revisionNotes;
  final String sourceType; // 'pdf' or 'tutor'
  final String? pdfDocumentName;
  final int? pageNumber;
  final String? citation;
  final String? tutorSessionTopic;

  const SmartNoteDto({
    required this.id,
    required this.title,
    required this.topic,
    required this.aiSummary,
    required this.keyPoints,
    required this.importantFacts,
    required this.definitions,
    required this.timeline,
    required this.tableData,
    required this.examples,
    required this.importantQuotes,
    required this.revisionNotes,
    required this.sourceType,
    this.pdfDocumentName,
    this.pageNumber,
    this.citation,
    this.tutorSessionTopic,
  });

  bool get isPdfGrounded => sourceType == 'pdf' && pdfDocumentName != null;
}

/// Abstract Repository Interface for GARUDA Flashcards & Smart Notes
abstract class FlashcardsRepository {
  Future<List<FlashcardDto>> loadFlashcards({required String topicId, String? pdfDocumentId});
  Future<SmartNoteDto> loadSmartNotes({required String topicId, String? pdfDocumentId});
  Future<void> saveFlashcardState(FlashcardDto flashcard);
}

/// Mock Implementation of FlashcardsRepository for Zero-Network Testing & Execution
class MockFlashcardsRepository implements FlashcardsRepository {
  @override
  Future<List<FlashcardDto>> loadFlashcards({required String topicId, String? pdfDocumentId}) async {
    final isPdf = pdfDocumentId != null && pdfDocumentId.isNotEmpty;
    final pdfName = isPdf ? 'Indian_Constitution_Summary.pdf' : null;

    return [
      FlashcardDto(
        id: 'fc_001',
        question: 'What is Article 14 of the Indian Constitution?',
        answer: 'Article 14 guarantees Equality Before Law (negative concept from UK) and Equal Protection of Laws (positive concept from US) to all persons within the territory of India.',
        hint: 'Think about equality principles derived from British and American legal traditions.',
        difficulty: 'Medium',
        topic: 'Polity & Governance',
        tags: ['Fundamental Rights', 'Article 14', 'Constitution'],
        source: isPdf ? 'PDF Knowledge Workflow' : 'Tutor Workflow',
        pdfDocumentName: pdfName,
        pageNumber: isPdf ? 14 : null,
        citation: isPdf ? 'Ref: Section 3.2, Page 14' : null,
      ),
      FlashcardDto(
        id: 'fc_002',
        question: 'What is the standard doctrine established in Kesavananda Bharati case (1973)?',
        answer: 'The Supreme Court laid down the Basic Structure Doctrine, ruling that Parliament cannot alter the basic structure or essential framework of the Constitution under Article 368.',
        hint: 'Focus on constitutional amendment limitations.',
        difficulty: 'Hard',
        topic: 'Polity & Governance',
        tags: ['Judiciary', 'Basic Structure', 'Landmark Judgments'],
        source: isPdf ? 'PDF Knowledge Workflow' : 'Tutor Workflow',
        pdfDocumentName: pdfName,
        pageNumber: isPdf ? 22 : null,
        citation: isPdf ? 'Ref: Landmark Judgements, Page 22' : null,
      ),
      FlashcardDto(
        id: 'fc_003',
        question: 'What are the main objective components of Monetary Policy Committee (MPC)?',
        answer: 'The MPC is a 6-member committee constituted by the Central Government to determine the policy interest rate (Repo Rate) required to achieve the inflation target (4% +/- 2%).',
        hint: 'Consider composition and target inflation band.',
        difficulty: 'Easy',
        topic: 'Economy',
        tags: ['Monetary Policy', 'RBI', 'Inflation'],
        source: 'Tutor Workflow',
      ),
    ];
  }

  @override
  Future<SmartNoteDto> loadSmartNotes({required String topicId, String? pdfDocumentId}) async {
    final isPdf = pdfDocumentId != null && pdfDocumentId.isNotEmpty;

    return SmartNoteDto(
      id: 'sn_101',
      title: 'Comprehensive Notes: Fundamental Rights & Article 14',
      topic: 'Polity & Governance',
      aiSummary: 'Article 14 is the cornerstone of democratic equality under Part III of the Constitution. It applies to both citizens and non-citizens, forbidding class legislation while permitting reasonable classification based on intelligible differentia.',
      keyPoints: [
        'Equality Before Law is a negative concept derived from British common law.',
        'Equal Protection of Laws is a positive concept derived from the American Constitution.',
        'Reasonable classification must have intelligible differentia and a rational nexus to the objective sought.',
        'Rule of Law as propounded by A.V. Dicey forms part of the Basic Structure.',
      ],
      importantFacts: [
        'Article 14 applies to legal entities, corporations, and non-citizens as well.',
        'Exceptions include President & Governors under Article 361, diplomatic immunity, and foreign sovereigns.',
      ],
      definitions: {
        'Intelligible Differentia': 'Distinction that can be understood and supported by logical distinction.',
        'Rational Nexus': 'Logical connection between the classification criteria and the objective of the statute.',
      },
      timeline: [
        {'year': '1950', 'event': 'Enactment of Article 14 in Part III'},
        {'year': '1973', 'event': 'Kesavananda Bharati case incorporates Rule of Law in Basic Structure'},
        {'year': '1978', 'event': 'Maneka Gandhi case expands non-arbitrariness standard under Article 14'},
      ],
      tableData: [
        ['Feature', 'Equality Before Law', 'Equal Protection of Laws'],
        ['Origin', 'British Common Law', 'US Constitution'],
        ['Concept Type', 'Negative (No privilege)', 'Positive (Equal treatment in equal circumstances)'],
        ['Applicability', 'All individuals equally', 'Equals treated equally'],
      ],
      examples: [
        'Special courts for speedier trial of specific grave offences with valid classification.',
        'Taxation statutes differentiating income slabs for progressive taxation.',
      ],
      importantQuotes: [
        '"Equality is a dynamic concept with many aspects and dimensions and it cannot be "cribbed, cabined and confined" within traditional limits." - Supreme Court in E.P. Royappa Case',
      ],
      revisionNotes: 'Quick Glance: Article 14 = Equality Before Law (UK) + Equal Protection (US). Key tests: Intelligible Differentia & Rational Nexus. Basic Structure element.',
      sourceType: isPdf ? 'pdf' : 'tutor',
      pdfDocumentName: isPdf ? 'Indian_Constitution_Summary.pdf' : null,
      pageNumber: isPdf ? 14 : null,
      citation: isPdf ? 'Ref: Section 3.2, Page 14' : null,
      tutorSessionTopic: isPdf ? null : 'Polity: Fundamental Rights Masterclass',
    );
  }

  @override
  Future<void> saveFlashcardState(FlashcardDto flashcard) async {
    // Zero-network local persistence stub
  }
}

/// ViewModel for GARUDA Flashcards & Smart Notes (MVVM Architecture)
class FlashcardsViewModel extends ChangeNotifier {
  final FlashcardsRepository repository;
  final String topicId;
  final String? pdfDocumentId;

  List<FlashcardDto> _allFlashcards = [];
  List<FlashcardDto> _filteredFlashcards = [];
  SmartNoteDto? _smartNote;

  int _currentIndex = 0;
  bool _isFlipped = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Search & Filter state
  String _searchQuery = '';
  String _selectedDifficulty = 'All';
  bool _filterBookmarkedOnly = false;
  bool _filterFavoritesOnly = false;

  FlashcardsViewModel({
    required this.topicId,
    this.pdfDocumentId,
    FlashcardsRepository? repository,
  }) : repository = repository ?? MockFlashcardsRepository();

  List<FlashcardDto> get flashcards => List.unmodifiable(_filteredFlashcards);
  SmartNoteDto? get smartNote => _smartNote;
  int get currentIndex => _currentIndex;
  bool get isFlipped => _isFlipped;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedDifficulty => _selectedDifficulty;
  bool get filterBookmarkedOnly => _filterBookmarkedOnly;
  bool get filterFavoritesOnly => _filterFavoritesOnly;

  FlashcardDto? get currentCard =>
      _filteredFlashcards.isNotEmpty && _currentIndex < _filteredFlashcards.length
          ? _filteredFlashcards[_currentIndex]
          : null;

  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allFlashcards = await repository.loadFlashcards(topicId: topicId, pdfDocumentId: pdfDocumentId);
      _smartNote = await repository.loadSmartNotes(topicId: topicId, pdfDocumentId: pdfDocumentId);
      _applyFilters();
      _isLoading = false;
    } catch (e) {
      _errorMessage = 'Failed to load Flashcards and Smart Notes: $e';
      _isLoading = false;
    }
    notifyListeners();
  }

  void flipCard() {
    _isFlipped = !_isFlipped;
    notifyListeners();
  }

  void nextCard() {
    if (_filteredFlashcards.isNotEmpty) {
      _currentIndex = (_currentIndex + 1) % _filteredFlashcards.length;
      _isFlipped = false;
      notifyListeners();
    }
  }

  void previousCard() {
    if (_filteredFlashcards.isNotEmpty) {
      _currentIndex = (_currentIndex - 1 + _filteredFlashcards.length) % _filteredFlashcards.length;
      _isFlipped = false;
      notifyListeners();
    }
  }

  void shuffleCards() {
    _filteredFlashcards.shuffle(Random());
    _currentIndex = 0;
    _isFlipped = false;
    notifyListeners();
  }

  void toggleBookmark() {
    final card = currentCard;
    if (card != null) {
      final updated = card.copyWith(isBookmarked: !card.isBookmarked);
      _updateCardInList(updated);
    }
  }

  void toggleFavorite() {
    final card = currentCard;
    if (card != null) {
      final updated = card.copyWith(isFavorite: !card.isFavorite);
      _updateCardInList(updated);
    }
  }

  /// Adaptive Revision Engine (SM-2 Spaced Repetition Queue Integration)
  void markCardKnown({required bool known}) {
    final card = currentCard;
    if (card == null) return;

    // Quality rating: 5 if known, 1 if unknown
    final quality = known ? 5 : 1;
    final oldEase = card.easeFactor;
    final oldRep = card.repetitions;
    final oldInterval = card.intervalDays;

    double newEase;
    int newRep;
    int newInterval;

    if (known) {
      newRep = oldRep + 1;
      if (newRep == 1) {
        newInterval = 1;
      } else if (newRep == 2) {
        newInterval = 6;
      } else {
        newInterval = (oldInterval * oldEase).round();
      }
      newEase = oldEase + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
      if (newEase < 1.3) newEase = 1.3;
    } else {
      newRep = 0;
      newInterval = 1;
      newEase = max(1.3, oldEase - 0.2);
    }

    final nextReview = DateTime.now().add(Duration(days: newInterval));

    final updatedCard = card.copyWith(
      isKnown: known,
      isInRevisionQueue: true,
      easeFactor: newEase,
      repetitions: newRep,
      intervalDays: newInterval,
      nextReviewDate: nextReview,
    );

    _updateCardInList(updatedCard);
    repository.saveFlashcardState(updatedCard);
    nextCard();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void setDifficultyFilter(String difficulty) {
    _selectedDifficulty = difficulty;
    _applyFilters();
  }

  void toggleBookmarkFilter() {
    _filterBookmarkedOnly = !_filterBookmarkedOnly;
    _applyFilters();
  }

  void toggleFavoriteFilter() {
    _filterFavoritesOnly = !_filterFavoritesOnly;
    _applyFilters();
  }

  void _applyFilters() {
    _filteredFlashcards = _allFlashcards.where((card) {
      final matchesSearch = _searchQuery.isEmpty ||
          card.question.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          card.answer.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          card.topic.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          card.tags.any((t) => t.toLowerCase().contains(_searchQuery.toLowerCase()));

      final matchesDifficulty =
          _selectedDifficulty == 'All' || card.difficulty.toLowerCase() == _selectedDifficulty.toLowerCase();

      final matchesBookmark = !_filterBookmarkedOnly || card.isBookmarked;
      final matchesFavorite = !_filterFavoritesOnly || card.isFavorite;

      return matchesSearch && matchesDifficulty && matchesBookmark && matchesFavorite;
    }).toList();

    _currentIndex = 0;
    _isFlipped = false;
    notifyListeners();
  }

  void _updateCardInList(FlashcardDto updated) {
    final allIdx = _allFlashcards.indexWhere((c) => c.id == updated.id);
    if (allIdx != -1) {
      _allFlashcards[allIdx] = updated;
    }
    final filtIdx = _filteredFlashcards.indexWhere((c) => c.id == updated.id);
    if (filtIdx != -1) {
      _filteredFlashcards[filtIdx] = updated;
    }
    notifyListeners();
  }
}
