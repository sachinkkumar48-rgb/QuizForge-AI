import 'dart:convert';
import 'dart:typed_data';
import 'pdf_primitive.dart';

/// Lexer/Tokenizer for parsing PDF byte streams according to ISO 32000-1 §7.2.
class PdfTokenizer {
  final Uint8List buffer;
  int pos = 0;

  PdfTokenizer(this.buffer, [this.pos = 0]);

  int get length => buffer.length;
  bool get isEOF => pos >= buffer.length;

  /// Skips all whitespace and PDF comments (% ... \n).
  void skipWhitespaceAndComments() {
    while (pos < length) {
      final b = buffer[pos];
      if (b == 0x00 ||
          b == 0x09 ||
          b == 0x0A ||
          b == 0x0C ||
          b == 0x0D ||
          b == 0x20) {
        pos++;
      } else if (b == 0x25) {
        // Comment '%' -> skip to end of line
        pos++;
        while (pos < length && buffer[pos] != 0x0A && buffer[pos] != 0x0D) {
          pos++;
        }
      } else {
        break;
      }
    }
  }

  /// Peeks at the next non-whitespace character without consuming it.
  int? peekByte() {
    skipWhitespaceAndComments();
    if (pos >= length) return null;
    return buffer[pos];
  }

  /// Reads the next basic token or object from the stream.
  Object? nextToken() {
    skipWhitespaceAndComments();
    if (pos >= length) return null;

    final b = buffer[pos];

    // Delimiters
    if (b == 0x2F) {
      // '/' -> Name
      return _readName();
    } else if (b == 0x28) {
      // '(' -> Literal String
      return _readLiteralString();
    } else if (b == 0x3C) {
      // '<' -> either '<<' or Hex String '<...>'
      if (pos + 1 < length && buffer[pos + 1] == 0x3C) {
        pos += 2;
        return '<<';
      }
      return _readHexString();
    } else if (b == 0x3E) {
      // '>' -> '>>'
      if (pos + 1 < length && buffer[pos + 1] == 0x3E) {
        pos += 2;
        return '>>';
      }
      pos++;
      return '>';
    } else if (b == 0x5B) {
      // '['
      pos++;
      return '[';
    } else if (b == 0x5D) {
      // ']'
      pos++;
      return ']';
    }

    // Word / Number / Keyword
    return _readWordOrNumber();
  }

  PdfName _readName() {
    pos++; // skip '/'
    final start = pos;
    final sb = StringBuffer();

    while (pos < length) {
      final b = buffer[pos];
      if (_isDelimiter(b) || _isWhitespace(b)) break;

      if (b == 0x23 && pos + 2 < length) {
        // Hex escape #XX
        final hex = utf8.decode([buffer[pos + 1], buffer[pos + 2]]);
        final charCode = int.tryParse(hex, radix: 16);
        if (charCode != null) {
          sb.writeCharCode(charCode);
          pos += 3;
          continue;
        }
      }
      sb.writeCharCode(b);
      pos++;
    }

    return PdfName(sb.isNotEmpty
        ? sb.toString()
        : utf8.decode(buffer.sublist(start, pos)));
  }

  PdfString _readLiteralString() {
    pos++; // skip '('
    final bytes = <int>[];
    var depth = 1;

    while (pos < length && depth > 0) {
      final b = buffer[pos];
      if (b == 0x5C) {
        // '\' Escape
        pos++;
        if (pos >= length) break;
        final esc = buffer[pos];
        if (esc == 0x6E) {
          bytes.add(0x0A); // \n
        } else if (esc == 0x72) {
          bytes.add(0x0D); // \r
        } else if (esc == 0x74) {
          bytes.add(0x09); // \t
        } else if (esc == 0x62) {
          bytes.add(0x08); // \b
        } else if (esc == 0x66) {
          bytes.add(0x0C); // \f
        } else if (esc == 0x28) {
          bytes.add(0x28); // \(
        } else if (esc == 0x29) {
          bytes.add(0x29); // \)
        } else if (esc == 0x5C) {
          bytes.add(0x5C); // \\
        } else if (esc >= 0x30 && esc <= 0x37) {
          // Octal escape \ddd
          var octal = esc - 0x30;
          if (pos + 1 < length &&
              buffer[pos + 1] >= 0x30 &&
              buffer[pos + 1] <= 0x37) {
            pos++;
            octal = (octal << 3) + (buffer[pos] - 0x30);
            if (pos + 1 < length &&
                buffer[pos + 1] >= 0x30 &&
                buffer[pos + 1] <= 0x37) {
              pos++;
              octal = (octal << 3) + (buffer[pos] - 0x30);
            }
          }
          bytes.add(octal & 0xFF);
        } else if (esc == 0x0A || esc == 0x0D) {
          // Line continuation
          if (esc == 0x0D && pos + 1 < length && buffer[pos + 1] == 0x0A) {
            pos++;
          }
        } else {
          bytes.add(esc);
        }
        pos++;
      } else if (b == 0x28) {
        depth++;
        bytes.add(b);
        pos++;
      } else if (b == 0x29) {
        depth--;
        if (depth > 0) bytes.add(b);
        pos++;
      } else {
        bytes.add(b);
        pos++;
      }
    }

    return PdfString(bytes);
  }

  PdfString _readHexString() {
    pos++; // skip '<'
    final hexChars = <int>[];
    while (pos < length) {
      final b = buffer[pos];
      if (b == 0x3E) {
        pos++; // skip '>'
        break;
      }
      if (!_isWhitespace(b)) {
        hexChars.add(b);
      }
      pos++;
    }

    final bytes = <int>[];
    for (var i = 0; i < hexChars.length; i += 2) {
      final h1 = String.fromCharCode(hexChars[i]);
      final h2 = (i + 1 < hexChars.length)
          ? String.fromCharCode(hexChars[i + 1])
          : '0';
      final val = int.tryParse('$h1$h2', radix: 16) ?? 0;
      bytes.add(val);
    }

    return PdfString(bytes, isHex: true);
  }

  Object _readWordOrNumber() {
    final start = pos;
    while (pos < length) {
      final b = buffer[pos];
      if (_isDelimiter(b) || _isWhitespace(b)) break;
      pos++;
    }

    final str = utf8.decode(buffer.sublist(start, pos), allowMalformed: true);
    if (str == 'true') return const PdfBoolean(true);
    if (str == 'false') return const PdfBoolean(false);
    if (str == 'null') return const PdfNull();

    final intVal = int.tryParse(str);
    if (intVal != null) return PdfNumber(intVal);

    final doubleVal = double.tryParse(str);
    if (doubleVal != null) return PdfNumber(doubleVal);

    return str; // string keyword (e.g. 'obj', 'endobj', 'R', 'stream', etc.)
  }

  static bool _isWhitespace(int b) =>
      b == 0x00 ||
      b == 0x09 ||
      b == 0x0A ||
      b == 0x0C ||
      b == 0x0D ||
      b == 0x20;

  static bool _isDelimiter(int b) =>
      b == 0x28 ||
      b == 0x29 ||
      b == 0x3C ||
      b == 0x3E ||
      b == 0x5B ||
      b == 0x5D ||
      b == 0x7B ||
      b == 0x7D ||
      b == 0x2F ||
      b == 0x25;
}
