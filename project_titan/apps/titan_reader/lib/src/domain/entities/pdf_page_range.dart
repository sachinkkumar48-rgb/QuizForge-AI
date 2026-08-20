import 'package:meta/meta.dart';
import '../pdf_manipulation_errors.dart';

/// Represents a single page or range of pages (e.g. "1", "1-5", "6-10", "1, 3, 5-8").
@immutable
class PdfPageRange {
  /// 1-based start page number (inclusive).
  final int startPage;

  /// 1-based end page number (inclusive).
  final int endPage;

  const PdfPageRange(this.startPage, this.endPage)
      : assert(startPage >= 1, 'startPage must be >= 1'),
        assert(endPage >= startPage, 'endPage must be >= startPage');

  /// Creates a single-page range.
  const PdfPageRange.single(int page) : this(page, page);

  /// Number of pages in this range.
  int get count => endPage - startPage + 1;

  /// Whether this range contains [pageNumber] (1-based).
  bool contains(int pageNumber) =>
      pageNumber >= startPage && pageNumber <= endPage;

  /// Returns all 1-based page numbers in this range.
  List<int> toPageList() =>
      List<int>.generate(count, (index) => startPage + index);

  /// Formats the range as standard string (e.g., "3" or "3-7").
  @override
  String toString() =>
      startPage == endPage ? '$startPage' : '$startPage-$endPage';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfPageRange &&
          runtimeType == other.runtimeType &&
          startPage == other.startPage &&
          endPage == other.endPage;

  @override
  int get hashCode => Object.hash(startPage, endPage);

  /// Parses a comma-separated range string (e.g. "1, 3-5, 8") into a list of [PdfPageRange]s.
  static List<PdfPageRange> parseMultiple(String input, {int? maxPages}) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      throw const PdfPageRangeParseException(
          'Page range string cannot be empty.');
    }

    final segments = trimmed.split(',');
    final result = <PdfPageRange>[];

    for (final rawSegment in segments) {
      final seg = rawSegment.trim();
      if (seg.isEmpty) continue;

      if (seg.contains('-')) {
        final parts = seg.split('-');
        if (parts.length != 2) {
          throw PdfPageRangeParseException('Invalid range format: "$seg"');
        }
        final start = int.tryParse(parts[0].trim());
        final end = int.tryParse(parts[1].trim());
        if (start == null || end == null) {
          throw PdfPageRangeParseException('Non-numeric page range: "$seg"');
        }
        if (start < 1) {
          throw PdfPageRangeParseException('Start page must be >= 1: $start');
        }
        if (end < start) {
          throw PdfPageRangeParseException(
              'End page ($end) must be >= start page ($start)');
        }
        if (maxPages != null && end > maxPages) {
          throw PdfPageRangeOutOfBoundsException(
            'Requested page $end exceeds document total ($maxPages).',
            requestedPage: end,
            maxPages: maxPages,
          );
        }
        result.add(PdfPageRange(start, end));
      } else {
        final single = int.tryParse(seg);
        if (single == null) {
          throw PdfPageRangeParseException('Non-numeric page number: "$seg"');
        }
        if (single < 1) {
          throw PdfPageRangeParseException('Page number must be >= 1: $single');
        }
        if (maxPages != null && single > maxPages) {
          throw PdfPageRangeOutOfBoundsException(
            'Requested page $single exceeds document total ($maxPages).',
            requestedPage: single,
            maxPages: maxPages,
          );
        }
        result.add(PdfPageRange.single(single));
      }
    }

    if (result.isEmpty) {
      throw const PdfPageRangeParseException('No valid page ranges found.');
    }

    return result;
  }

  /// Converts a list of [PdfPageRange]s into a deduplicated, sorted list of 1-based page indices.
  static List<int> expandToPageNumbers(List<PdfPageRange> ranges,
      {bool deduplicate = true}) {
    final pages = <int>[];
    for (final range in ranges) {
      pages.addAll(range.toPageList());
    }
    if (deduplicate) {
      return pages.toSet().toList()..sort();
    }
    return pages;
  }
}
