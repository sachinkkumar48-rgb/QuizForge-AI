import 'package:meta/meta.dart';
import 'package:titan_content/titan_content.dart';

/// Execution status for the Digital Library state.
enum LibraryStateStatus {
  initial,
  loading,
  success,
  error,
}

/// Immutable state container for the Digital Library UI.
@immutable
class LibraryState {
  final LibraryStateStatus status;
  final List<LibraryDocument> documents;
  final List<LibraryFolder> folders;
  final List<LibraryDocument> continueReadingDocuments;
  final List<LibraryDocument> favoriteDocuments;
  final String searchQuery;
  final String selectedCategory;
  final String? errorMessage;

  LibraryState({
    required this.status,
    List<LibraryDocument>? documents,
    List<LibraryFolder>? folders,
    List<LibraryDocument>? continueReadingDocuments,
    List<LibraryDocument>? favoriteDocuments,
    this.searchQuery = '',
    this.selectedCategory = 'All',
    this.errorMessage,
  })  : documents = List<LibraryDocument>.unmodifiable(documents ?? const []),
        folders = List<LibraryFolder>.unmodifiable(folders ?? const []),
        continueReadingDocuments = List<LibraryDocument>.unmodifiable(
            continueReadingDocuments ?? const []),
        favoriteDocuments =
            List<LibraryDocument>.unmodifiable(favoriteDocuments ?? const []);

  const LibraryState.initial()
      : status = LibraryStateStatus.initial,
        documents = const [],
        folders = const [],
        continueReadingDocuments = const [],
        favoriteDocuments = const [],
        searchQuery = '',
        selectedCategory = 'All',
        errorMessage = null;

  const LibraryState.loading()
      : status = LibraryStateStatus.loading,
        documents = const [],
        folders = const [],
        continueReadingDocuments = const [],
        favoriteDocuments = const [],
        searchQuery = '',
        selectedCategory = 'All',
        errorMessage = null;

  LibraryState copyWith({
    LibraryStateStatus? status,
    List<LibraryDocument>? documents,
    List<LibraryFolder>? folders,
    List<LibraryDocument>? continueReadingDocuments,
    List<LibraryDocument>? favoriteDocuments,
    String? searchQuery,
    String? selectedCategory,
    String? errorMessage,
  }) {
    return LibraryState(
      status: status ?? this.status,
      documents: documents ?? this.documents,
      folders: folders ?? this.folders,
      continueReadingDocuments:
          continueReadingDocuments ?? this.continueReadingDocuments,
      favoriteDocuments: favoriteDocuments ?? this.favoriteDocuments,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isInitial => status == LibraryStateStatus.initial;
  bool get isLoading => status == LibraryStateStatus.loading;
  bool get isSuccess => status == LibraryStateStatus.success;
  bool get isError => status == LibraryStateStatus.error;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LibraryState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          searchQuery == other.searchQuery &&
          selectedCategory == other.selectedCategory &&
          errorMessage == other.errorMessage &&
          _listEquals(documents, other.documents) &&
          _listEquals(folders, other.folders) &&
          _listEquals(
              continueReadingDocuments, other.continueReadingDocuments) &&
          _listEquals(favoriteDocuments, other.favoriteDocuments);

  @override
  int get hashCode => Object.hash(
        status,
        searchQuery,
        selectedCategory,
        errorMessage,
        Object.hashAll(documents),
        Object.hashAll(folders),
        Object.hashAll(continueReadingDocuments),
        Object.hashAll(favoriteDocuments),
      );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
