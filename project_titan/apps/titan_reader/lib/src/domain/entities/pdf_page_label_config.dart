import 'package:meta/meta.dart';

/// Supported numbering styles for PDF page labels (ISO 32000-1 /PageLabels).
enum PdfPageLabelStyle {
  /// Standard Arabic numbers (1, 2, 3...)
  arabic,

  /// Lowercase Roman numerals (i, ii, iii...)
  romanLower,

  /// Uppercase Roman numerals (I, II, III...)
  romanUpper,

  /// Lowercase alphabetical letters (a, b, c...)
  alphaLower,

  /// Uppercase alphabetical letters (A, B, C...)
  alphaUpper,

  /// No number (prefix only, e.g. "Cover")
  none,
}

/// Extension mapping [PdfPageLabelStyle] to ISO 32000 PDF name codes.
extension PdfPageLabelStyleExtension on PdfPageLabelStyle {
  /// PDF Name code used in `/S` entry of PageLabel dictionary.
  String? get pdfStyleCode {
    switch (this) {
      case PdfPageLabelStyle.arabic:
        return 'D';
      case PdfPageLabelStyle.romanLower:
        return 'r';
      case PdfPageLabelStyle.romanUpper:
        return 'R';
      case PdfPageLabelStyle.alphaLower:
        return 'a';
      case PdfPageLabelStyle.alphaUpper:
        return 'A';
      case PdfPageLabelStyle.none:
        return null;
    }
  }

  /// Parses from PDF style code string.
  static PdfPageLabelStyle fromCode(String? code) {
    switch (code) {
      case 'D':
        return PdfPageLabelStyle.arabic;
      case 'r':
        return PdfPageLabelStyle.romanLower;
      case 'R':
        return PdfPageLabelStyle.romanUpper;
      case 'a':
        return PdfPageLabelStyle.alphaLower;
      case 'A':
        return PdfPageLabelStyle.alphaUpper;
      default:
        return PdfPageLabelStyle.none;
    }
  }
}

/// Defines a page label configuration segment starting at a specific page.
@immutable
class PdfPageLabelRange {
  /// 1-based page index where this numbering style starts (inclusive).
  final int startPage;

  /// Numbering style to use.
  final PdfPageLabelStyle style;

  /// Optional prefix string (e.g. "Preface-", "Chapter 1-").
  final String prefix;

  /// Starting sequence number for this style (defaults to 1).
  final int startNumber;

  const PdfPageLabelRange({
    required this.startPage,
    this.style = PdfPageLabelStyle.arabic,
    this.prefix = '',
    this.startNumber = 1,
  })  : assert(startPage >= 1, 'startPage must be >= 1'),
        assert(startNumber >= 1, 'startNumber must be >= 1');

  /// Formats the display label for an offset from startPage.
  String formatLabelForIndex(int pageNumber) {
    if (pageNumber < startPage) return '$pageNumber';
    final offset = pageNumber - startPage;
    final numVal = startNumber + offset;

    final numStr = _formatNumber(numVal, style);
    if (prefix.isEmpty) return numStr;
    return '$prefix$numStr';
  }

  static String _formatNumber(int value, PdfPageLabelStyle style) {
    switch (style) {
      case PdfPageLabelStyle.arabic:
        return '$value';
      case PdfPageLabelStyle.romanLower:
        return _toRoman(value).toLowerCase();
      case PdfPageLabelStyle.romanUpper:
        return _toRoman(value);
      case PdfPageLabelStyle.alphaLower:
        return _toAlpha(value).toLowerCase();
      case PdfPageLabelStyle.alphaUpper:
        return _toAlpha(value);
      case PdfPageLabelStyle.none:
        return '';
    }
  }

  static String _toRoman(int number) {
    if (number <= 0) return '$number';
    const values = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1];
    const symbols = [
      'M',
      'CM',
      'D',
      'CD',
      'C',
      'XC',
      'L',
      'XL',
      'X',
      'IX',
      'V',
      'IV',
      'I'
    ];
    final sb = StringBuffer();
    var n = number;
    for (var i = 0; i < values.length; i++) {
      while (n >= values[i]) {
        sb.write(symbols[i]);
        n -= values[i];
      }
    }
    return sb.toString();
  }

  static String _toAlpha(int number) {
    if (number <= 0) return '';
    var n = number - 1;
    final sb = StringBuffer();
    while (n >= 0) {
      sb.write(String.fromCharCode(65 + (n % 26)));
      n = (n ~/ 26) - 1;
    }
    return sb.toString().split('').reversed.join('');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfPageLabelRange &&
          runtimeType == other.runtimeType &&
          startPage == other.startPage &&
          style == other.style &&
          prefix == other.prefix &&
          startNumber == other.startNumber;

  @override
  int get hashCode => Object.hash(startPage, style, prefix, startNumber);

  @override
  String toString() =>
      'PdfPageLabelRange(start: $startPage, style: ${style.name}, prefix: "$prefix", startNum: $startNumber)';
}
