import 'dart:convert';
import 'dart:typed_data';
import 'pdf_primitive.dart';
import 'pdf_tokenizer.dart';
import 'pdf_document_ast.dart';
import '../../domain/pdf_manipulation_errors.dart';

/// Complete pure Dart parser for ISO 32000-1 PDF document structures and indirect object graphs.
class PdfParser {
  final Uint8List bytes;

  PdfParser(this.bytes);

  /// Parses the entire PDF byte stream into an in-memory [PdfDocumentAst].
  PdfDocumentAst parse() {
    if (bytes.length < 10) {
      throw const PdfInvalidDocumentException(
          'PDF file is too small to be valid.',
          filePath: '');
    }

    // 1. Verify Header
    final headerString =
        utf8.decode(bytes.take(10).toList(), allowMalformed: true);
    if (!headerString.startsWith('%PDF-')) {
      throw const PdfInvalidDocumentException('Missing %PDF- header.',
          filePath: '');
    }
    final header = _extractHeader();

    // 2. Parse Objects Map
    final objects = <int, PdfObject>{};
    final objectGenerations = <int, int>{};

    // Scan for all "X Y obj" headers in the document
    _scanAndParseAllObjects(objects, objectGenerations);

    if (objects.isEmpty) {
      throw const PdfInvalidDocumentException(
          'No valid PDF objects found in document.',
          filePath: '');
    }

    // 3. Locate Trailer & Catalog
    final trailer = _findOrSynthesizeTrailer(objects);

    // 4. Resolve Catalog and Pages Tree
    final rootRef = trailer['Root'];
    PdfDict? catalog;
    if (rootRef is PdfRef) {
      final obj = objects[rootRef.objectNumber];
      if (obj is PdfDict) {
        catalog = obj;
      }
    } else if (rootRef is PdfDict) {
      catalog = rootRef;
    }

    if (catalog == null) {
      // Find dictionary with /Type /Catalog
      for (final obj in objects.values) {
        if (obj is PdfDict && obj.getName('Type') == 'Catalog') {
          catalog = obj;
          break;
        }
      }
    }

    if (catalog == null) {
      throw const PdfInvalidDocumentException(
          'Failed to locate PDF /Root /Catalog dictionary.',
          filePath: '');
    }

    return PdfDocumentAst(
      header: header,
      objects: objects,
      objectGenerations: objectGenerations,
      trailer: trailer,
      catalog: catalog,
    );
  }

  String _extractHeader() {
    var end = 0;
    while (end < bytes.length && bytes[end] != 0x0A && bytes[end] != 0x0D) {
      end++;
    }
    return utf8.decode(bytes.sublist(0, end));
  }

  void _scanAndParseAllObjects(
      Map<int, PdfObject> objects, Map<int, int> objectGenerations) {
    var pos = 0;
    final len = bytes.length;

    while (pos < len - 6) {
      // Search for "obj" keyword
      if (bytes[pos] == 0x6F &&
          bytes[pos + 1] == 0x62 &&
          bytes[pos + 2] == 0x6A) {
        // Verify whitespace before "obj" and after "obj"
        final beforeObj = pos > 0 ? bytes[pos - 1] : 0;
        final afterObj = pos + 3 < len ? bytes[pos + 3] : 0;

        if (_isWhitespace(beforeObj) &&
            (_isWhitespace(afterObj) ||
                afterObj == 0x25 ||
                afterObj == 0x3C ||
                afterObj == 0x5B)) {
          // Look backwards for object number and generation number
          final objHeader = _tryReadObjHeader(pos);
          if (objHeader != null) {
            final objNum = objHeader.key;
            final genNum = objHeader.value;

            final tokenizer = PdfTokenizer(bytes, pos + 3);
            final obj = _parseObject(tokenizer);

            if (obj != null) {
              objects[objNum] = obj;
              objectGenerations[objNum] = genNum;
            }
          }
        }
      }
      pos++;
    }
  }

  MapEntry<int, int>? _tryReadObjHeader(int objKeywordPos) {
    var p = objKeywordPos - 1;
    while (p >= 0 && _isWhitespace(bytes[p])) {
      p--;
    }
    if (p < 0) return null;

    // Read generation number (digits)
    final genEnd = p + 1;
    while (p >= 0 && bytes[p] >= 0x30 && bytes[p] <= 0x39) {
      p--;
    }
    final genStart = p + 1;
    if (genStart >= genEnd) return null;
    final genStr = utf8.decode(bytes.sublist(genStart, genEnd));
    final genNum = int.tryParse(genStr);
    if (genNum == null) return null;

    // Skip whitespace before gen number
    while (p >= 0 && _isWhitespace(bytes[p])) {
      p--;
    }
    if (p < 0) return null;

    // Read object number (digits)
    final objEnd = p + 1;
    while (p >= 0 && bytes[p] >= 0x30 && bytes[p] <= 0x39) {
      p--;
    }
    final objStart = p + 1;
    if (objStart >= objEnd) return null;
    final objStr = utf8.decode(bytes.sublist(objStart, objEnd));
    final objNum = int.tryParse(objStr);
    if (objNum == null) return null;

    return MapEntry(objNum, genNum);
  }

  PdfObject? _parseObject(PdfTokenizer tokenizer) {
    final token = tokenizer.nextToken();
    if (token == null) return null;

    if (token is PdfObject) {
      // Check if it's a number that might form an indirect reference "X Y R"
      if (token is PdfNumber && token.value is int) {
        final savedPos = tokenizer.pos;
        final next1 = tokenizer.nextToken();
        if (next1 is PdfNumber && next1.value is int) {
          final next2 = tokenizer.nextToken();
          if (next2 == 'R') {
            return PdfRef(token.asInt, next1.asInt);
          }
        }
        tokenizer.pos = savedPos;
      }
      return token;
    }

    if (token == '[') {
      final array = PdfArray();
      while (!tokenizer.isEOF) {
        tokenizer.skipWhitespaceAndComments();
        if (tokenizer.peekByte() == 0x5D) {
          // ']'
          tokenizer.nextToken();
          break;
        }
        final item = _parseObject(tokenizer);
        if (item != null) {
          array.add(item);
        } else {
          break;
        }
      }
      return array;
    }

    if (token == '<<') {
      final dict = PdfDict();
      while (!tokenizer.isEOF) {
        tokenizer.skipWhitespaceAndComments();
        if (tokenizer.peekByte() == 0x3E) {
          // '>'
          final closing = tokenizer.nextToken();
          if (closing == '>>') break;
        }
        final keyToken = tokenizer.nextToken();
        if (keyToken == '>>') break;
        if (keyToken is! PdfName) break;

        final value = _parseObject(tokenizer);
        if (value != null) {
          dict[keyToken.name] = value;
        }
      }

      // Check if followed by "stream"
      final savedPos = tokenizer.pos;
      final nextToken = tokenizer.nextToken();
      if (nextToken == 'stream') {
        // Stream data follows
        var streamStart = tokenizer.pos;
        // Skip single \n or \r\n immediately after stream keyword
        if (streamStart < bytes.length && bytes[streamStart] == 0x0D) {
          streamStart++;
        }
        if (streamStart < bytes.length && bytes[streamStart] == 0x0A) {
          streamStart++;
        }

        final lengthVal = dict['Length'];
        int? streamLength;
        if (lengthVal is PdfNumber) {
          streamLength = lengthVal.asInt;
        }

        Uint8List streamData;
        if (streamLength != null &&
            streamStart + streamLength <= bytes.length) {
          streamData = bytes.sublist(streamStart, streamStart + streamLength);
          tokenizer.pos = streamStart + streamLength;
          tokenizer.nextToken(); // consume 'endstream'
        } else {
          // Scan for 'endstream'
          var endstreamPos = streamStart;
          while (endstreamPos < bytes.length - 8) {
            if (bytes[endstreamPos] == 0x65 &&
                bytes[endstreamPos + 1] == 0x6E &&
                bytes[endstreamPos + 2] == 0x64 &&
                bytes[endstreamPos + 3] == 0x73 &&
                bytes[endstreamPos + 4] == 0x74 &&
                bytes[endstreamPos + 5] == 0x72 &&
                bytes[endstreamPos + 6] == 0x65 &&
                bytes[endstreamPos + 7] == 0x61 &&
                bytes[endstreamPos + 8] == 0x6D) {
              break;
            }
            endstreamPos++;
          }
          var actualEnd = endstreamPos;
          if (actualEnd > streamStart && bytes[actualEnd - 1] == 0x0A) {
            actualEnd--;
          }
          if (actualEnd > streamStart && bytes[actualEnd - 1] == 0x0D) {
            actualEnd--;
          }
          streamData = bytes.sublist(streamStart, actualEnd);
          tokenizer.pos = endstreamPos + 9;
        }

        return PdfStream(dict: dict, data: streamData);
      } else {
        tokenizer.pos = savedPos;
      }

      return dict;
    }

    return null;
  }

  PdfDict _findOrSynthesizeTrailer(Map<int, PdfObject> objects) {
    // Scan for trailer keyword from end of file
    var p = bytes.length - 1;
    while (p >= 7) {
      if (bytes[p - 6] == 0x74 &&
          bytes[p - 5] == 0x72 &&
          bytes[p - 4] == 0x61 &&
          bytes[p - 3] == 0x69 &&
          bytes[p - 2] == 0x6C &&
          bytes[p - 1] == 0x65 &&
          bytes[p] == 0x72) {
        final tokenizer = PdfTokenizer(bytes, p + 1);
        final dict = _parseObject(tokenizer);
        if (dict is PdfDict) {
          return dict;
        }
      }
      p--;
    }

    // Synthesize trailer if not found (e.g. from xref stream)
    final synthetic = PdfDict();
    for (final entry in objects.entries) {
      final obj = entry.value;
      if (obj is PdfDict && obj.getName('Type') == 'Catalog') {
        synthetic['Root'] = PdfRef(entry.key);
      } else if (obj is PdfStream && obj.dict.getName('Type') == 'XRef') {
        if (obj.dict.containsKey('Root')) {
          synthetic['Root'] = obj.dict['Root']!;
        }
        if (obj.dict.containsKey('Info')) {
          synthetic['Info'] = obj.dict['Info']!;
        }
      }
    }
    return synthetic;
  }

  static bool _isWhitespace(int b) =>
      b == 0x00 ||
      b == 0x09 ||
      b == 0x0A ||
      b == 0x0C ||
      b == 0x0D ||
      b == 0x20;
}
