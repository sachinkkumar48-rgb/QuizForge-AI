import 'dart:convert';
import 'dart:typed_data';
import 'package:meta/meta.dart';

/// Base class for all PDF primitives and data objects (ISO 32000-1 §7.3).
@immutable
abstract class PdfObject {
  const PdfObject();

  /// Writes ASCII/binary byte representation of this object to the sink.
  void writeTo(BytesBuilder builder);

  /// Helper to convert object to string representation for debugging.
  @override
  String toString() {
    final builder = BytesBuilder(copy: false);
    writeTo(builder);
    return utf8.decode(builder.toBytes(), allowMalformed: true);
  }
}

/// Null object (`null`).
class PdfNull extends PdfObject {
  const PdfNull();

  @override
  void writeTo(BytesBuilder builder) {
    builder.add(const [0x6E, 0x75, 0x6C, 0x6C]); // 'null'
  }

  @override
  bool operator ==(Object other) => other is PdfNull;

  @override
  int get hashCode => 0;
}

/// Boolean object (`true` or `false`).
class PdfBoolean extends PdfObject {
  final bool value;
  const PdfBoolean(this.value);

  @override
  void writeTo(BytesBuilder builder) {
    if (value) {
      builder.add(const [0x74, 0x72, 0x75, 0x65]); // 'true'
    } else {
      builder.add(const [0x66, 0x61, 0x6C, 0x73, 0x65]); // 'false'
    }
  }

  @override
  bool operator ==(Object other) => other is PdfBoolean && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// Numeric object (integer or real).
class PdfNumber extends PdfObject {
  final num value;
  const PdfNumber(this.value);

  int get asInt => value.toInt();
  double get asDouble => value.toDouble();

  @override
  void writeTo(BytesBuilder builder) {
    if (value is int || value == value.toInt()) {
      builder.add(utf8.encode(value.toInt().toString()));
    } else {
      builder.add(utf8.encode(value.toString()));
    }
  }

  @override
  bool operator ==(Object other) => other is PdfNumber && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// Name object (`/Name`).
class PdfName extends PdfObject {
  /// Name without leading slash (e.g. "Type", "Pages", "Rotate").
  final String name;

  const PdfName(this.name);

  @override
  void writeTo(BytesBuilder builder) {
    builder.addByte(0x2F); // '/'
    final bytes = utf8.encode(name);
    for (final b in bytes) {
      // Escape whitespace, delimiters, or non-printable chars using #XX
      if (b < 33 ||
          b > 126 ||
          b == 0x23 ||
          b == 0x2F ||
          b == 0x28 ||
          b == 0x29 ||
          b == 0x3C ||
          b == 0x3E ||
          b == 0x5B ||
          b == 0x5D ||
          b == 0x7B ||
          b == 0x7D ||
          b == 0x25) {
        builder.addByte(0x23); // '#'
        final hex = b.toRadixString(16).padLeft(2, '0').toUpperCase();
        builder.add(utf8.encode(hex));
      } else {
        builder.addByte(b);
      }
    }
  }

  @override
  bool operator ==(Object other) => other is PdfName && other.name == name;

  @override
  int get hashCode => name.hashCode;
}

/// String object (Literal `(...)` or Hexadecimal `<...>`).
class PdfString extends PdfObject {
  final List<int> bytes;
  final bool isHex;

  const PdfString(this.bytes, {this.isHex = false});

  PdfString.fromString(String text, {bool isHex = false})
      : this(utf8.encode(text), isHex: isHex);

  String asString() => utf8.decode(bytes, allowMalformed: true);

  @override
  void writeTo(BytesBuilder builder) {
    if (isHex) {
      builder.addByte(0x3C); // '<'
      for (final b in bytes) {
        final hex = b.toRadixString(16).padLeft(2, '0').toUpperCase();
        builder.add(utf8.encode(hex));
      }
      builder.addByte(0x3E); // '>'
    } else {
      builder.addByte(0x28); // '('
      for (final b in bytes) {
        if (b == 0x28) {
          builder.add(const [0x5C, 0x28]); // '\('
        } else if (b == 0x29) {
          builder.add(const [0x5C, 0x29]); // '\)'
        } else if (b == 0x5C) {
          builder.add(const [0x5C, 0x5C]); // '\\'
        } else if (b == 0x0A) {
          builder.add(const [0x5C, 0x6E]); // '\n'
        } else if (b == 0x0D) {
          builder.add(const [0x5C, 0x72]); // '\r'
        } else if (b == 0x09) {
          builder.add(const [0x5C, 0x74]); // '\t'
        } else {
          builder.addByte(b);
        }
      }
      builder.addByte(0x29); // ')'
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PdfString) return false;
    if (other.bytes.length != bytes.length) return false;
    for (var i = 0; i < bytes.length; i++) {
      if (other.bytes[i] != bytes[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(bytes);
}

/// Indirect Reference object (`X Y R`).
class PdfRef extends PdfObject {
  final int objectNumber;
  final int generationNumber;

  const PdfRef(this.objectNumber, [this.generationNumber = 0])
      : assert(objectNumber >= 0, 'objectNumber must be >= 0'),
        assert(generationNumber >= 0, 'generationNumber must be >= 0');

  @override
  void writeTo(BytesBuilder builder) {
    builder.add(utf8.encode('$objectNumber $generationNumber R'));
  }

  @override
  bool operator ==(Object other) =>
      other is PdfRef &&
      other.objectNumber == objectNumber &&
      other.generationNumber == generationNumber;

  @override
  int get hashCode => Object.hash(objectNumber, generationNumber);

  @override
  String toString() => '$objectNumber $generationNumber R';
}

/// Array object (`[ ... ]`).
class PdfArray extends PdfObject {
  final List<PdfObject> items;

  PdfArray([List<PdfObject>? items])
      : items = items != null ? List.of(items) : [];

  int get length => items.length;
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  PdfObject operator [](int index) => items[index];
  void operator []=(int index, PdfObject value) => items[index] = value;
  void add(PdfObject item) => items.add(item);
  void addAll(Iterable<PdfObject> newItems) => items.addAll(newItems);
  void insert(int index, PdfObject item) => items.insert(index, item);
  PdfObject removeAt(int index) => items.removeAt(index);
  bool remove(PdfObject item) => items.remove(item);

  @override
  void writeTo(BytesBuilder builder) {
    builder.addByte(0x5B); // '['
    for (var i = 0; i < items.length; i++) {
      if (i > 0) builder.addByte(0x20); // ' '
      items[i].writeTo(builder);
    }
    builder.addByte(0x5D); // ']'
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfArray &&
          other.items.length == items.length &&
          _itemsEqual(other.items);

  bool _itemsEqual(List<PdfObject> otherItems) {
    for (var i = 0; i < items.length; i++) {
      if (items[i] != otherItems[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(items);
}

/// Dictionary object (`<< ... >>`).
class PdfDict extends PdfObject {
  final Map<String, PdfObject> entries;

  PdfDict([Map<String, PdfObject>? entries])
      : entries = entries != null ? Map.of(entries) : {};

  PdfObject? operator [](String key) {
    final cleanKey = key.startsWith('/') ? key.substring(1) : key;
    return entries[cleanKey];
  }

  void operator []=(String key, PdfObject value) {
    final cleanKey = key.startsWith('/') ? key.substring(1) : key;
    entries[cleanKey] = value;
  }

  bool containsKey(String key) {
    final cleanKey = key.startsWith('/') ? key.substring(1) : key;
    return entries.containsKey(cleanKey);
  }

  PdfObject? remove(String key) {
    final cleanKey = key.startsWith('/') ? key.substring(1) : key;
    return entries.remove(cleanKey);
  }

  String? getName(String key) {
    final obj = this[key];
    if (obj is PdfName) return obj.name;
    return null;
  }

  int? getInt(String key) {
    final obj = this[key];
    if (obj is PdfNumber) return obj.asInt;
    return null;
  }

  PdfDict? getDict(String key) {
    final obj = this[key];
    if (obj is PdfDict) return obj;
    return null;
  }

  PdfArray? getArray(String key) {
    final obj = this[key];
    if (obj is PdfArray) return obj;
    return null;
  }

  PdfRef? getRef(String key) {
    final obj = this[key];
    if (obj is PdfRef) return obj;
    return null;
  }

  @override
  void writeTo(BytesBuilder builder) {
    builder.add(const [0x3C, 0x3C]); // '<<'
    var first = true;
    for (final entry in entries.entries) {
      if (!first) {
        builder.addByte(0x20); // ' '
      } else {
        first = false;
      }
      PdfName(entry.key).writeTo(builder);
      builder.addByte(0x20); // ' '
      entry.value.writeTo(builder);
    }
    builder.add(const [0x3E, 0x3E]); // '>>'
  }
}

/// Stream object (`<< ... >>\nstream\n...\nendstream`).
class PdfStream extends PdfObject {
  final PdfDict dict;
  final Uint8List data;

  PdfStream({required this.dict, required this.data}) {
    dict['Length'] = PdfNumber(data.length);
  }

  @override
  void writeTo(BytesBuilder builder) {
    dict['Length'] = PdfNumber(data.length);
    dict.writeTo(builder);
    builder.add(
        const [0x0A, 0x73, 0x74, 0x72, 0x65, 0x61, 0x6D, 0x0A]); // '\nstream\n'
    builder.add(data);
    builder.add(const [
      0x0A,
      0x65,
      0x6E,
      0x64,
      0x73,
      0x74,
      0x72,
      0x65,
      0x61,
      0x6D
    ]); // '\nendstream'
  }
}
