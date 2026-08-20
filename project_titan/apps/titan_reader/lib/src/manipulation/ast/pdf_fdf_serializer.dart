import 'dart:convert';
import 'dart:typed_data';
import '../../domain/entities/pdf_form_field.dart';

/// Serializes and deserializes Form Data Format (FDF) and structured JSON for AcroForms.
class PdfFdfSerializer {
  /// Exports form values as ISO 32000-1 compliant FDF format bytes.
  static Uint8List exportToFdf(PdfFormDocument document, {String? pdfFilePath}) {
    final buffer = StringBuffer();
    buffer.write('%FDF-1.2\n');
    buffer.write('%âãÏÓ\n');
    buffer.write('1 0 obj\n');
    buffer.write('<<\n/FDF <<\n/Fields [\n');

    for (final field in document.fields) {
      if (field.isNoExport || field.fullyQualifiedName.isEmpty) continue;

      final name = _escapePdfString(field.fullyQualifiedName);
      if (field is PdfCheckboxFormField) {
        final val = field.isChecked ? field.onValue : 'Off';
        buffer.write('<< /T ($name) /V /$val >>\n');
      } else if (field is PdfRadioButtonFormField) {
        final val = field.selectedValue.isEmpty ? 'Off' : field.selectedValue;
        buffer.write('<< /T ($name) /V /$val >>\n');
      } else if (field is PdfListBoxFormField) {
        if (field.selectedValues.isEmpty) {
          buffer.write('<< /T ($name) /V () >>\n');
        } else if (field.selectedValues.length == 1) {
          final val = _escapePdfString(field.selectedValues.first);
          buffer.write('<< /T ($name) /V ($val) >>\n');
        } else {
          final arr = field.selectedValues
              .map((v) => '(${_escapePdfString(v)})')
              .join(' ');
          buffer.write('<< /T ($name) /V [$arr] >>\n');
        }
      } else {
        final val = _escapePdfString(field.exportValueString);
        buffer.write('<< /T ($name) /V ($val) >>\n');
      }
    }

    buffer.write(']\n');
    if (pdfFilePath != null && pdfFilePath.isNotEmpty) {
      buffer.write('/F (${_escapePdfString(pdfFilePath)})\n');
    }
    buffer.write('>>\n>>\nendobj\n');
    buffer.write('trailer\n<<\n/Root 1 0 R\n>>\n');
    buffer.write('%%EOF\n');

    return Uint8List.fromList(utf8.encode(buffer.toString()));
  }

  /// Parses an FDF byte stream into a map of Field Name -> Field Value.
  static Map<String, String> importFromFdf(Uint8List fdfBytes) {
    final text = utf8.decode(fdfBytes, allowMalformed: true);
    final result = <String, String>{};

    final fieldRegex = RegExp(
        r'<<\s*/T\s*\(([^)]*)\)\s*/V\s*(?:\(([^)]*)\)|/([^\s/>]+))\s*>>');
    final matches = fieldRegex.allMatches(text);

    for (final match in matches) {
      final name = match.group(1) ?? '';
      final stringVal = match.group(2);
      final nameVal = match.group(3);
      final val = stringVal ?? nameVal ?? '';
      if (name.isNotEmpty) {
        result[name] = _unescapePdfString(val);
      }
    }

    return result;
  }

  /// Exports form values as structured JSON string.
  static String exportToJson(PdfFormDocument document) {
    final valuesMap = <String, dynamic>{};
    for (final field in document.fields) {
      if (field.isNoExport || field.fullyQualifiedName.isEmpty) continue;
      if (field is PdfCheckboxFormField) {
        valuesMap[field.fullyQualifiedName] = field.isChecked;
      } else if (field is PdfListBoxFormField) {
        valuesMap[field.fullyQualifiedName] = field.selectedValues;
      } else {
        valuesMap[field.fullyQualifiedName] = field.exportValueString;
      }
    }

    final root = {
      'format': 'TITAN_ACROFORM_JSON',
      'version': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'fieldCount': document.fieldCount,
      'values': valuesMap,
    };

    return const JsonEncoder.withIndent('  ').convert(root);
  }

  /// Parses JSON string into a map of Field Name -> Dynamic Field Value.
  static Map<String, dynamic> importFromJson(String jsonString) {
    final decoded = json.decode(jsonString);
    if (decoded is Map<String, dynamic>) {
      if (decoded.containsKey('values') && decoded['values'] is Map) {
        return Map<String, dynamic>.from(decoded['values'] as Map);
      }
      return decoded;
    }
    return const {};
  }

  static String _escapePdfString(String text) {
    return text
        .replaceAll(r'\', r'\\')
        .replaceAll('(', r'\(')
        .replaceAll(')', r'\)');
  }

  static String _unescapePdfString(String text) {
    return text
        .replaceAll(r'\(', '(')
        .replaceAll(r'\)', ')')
        .replaceAll(r'\\', r'\');
  }
}
