import 'dart:convert';
import 'dart:typed_data';
import '../../domain/entities/pdf_form_field.dart';
import 'pdf_document_ast.dart';
import 'pdf_primitive.dart';

/// Mutates, updates, resets, and flattens AcroForm fields in [PdfDocumentAst].
class PdfFormBuilder {
  /// Ensures the Document Catalog has an `/AcroForm` dictionary and returns it.
  static PdfDict ensureAcroForm(PdfDocumentAst ast) {
    final acroFormObj = ast.catalog['AcroForm'];
    if (acroFormObj == null) {
      final newObjNum = ast.nextAvailableObjectNumber();
      final newAcroForm = PdfDict({
        'Fields': PdfArray(const []),
        'NeedAppearances': const PdfBoolean(true),
      });
      ast.objects[newObjNum] = newAcroForm;
      ast.objectGenerations[newObjNum] = 0;
      ast.catalog['AcroForm'] = PdfRef(newObjNum);
      return newAcroForm;
    }

    if (acroFormObj is PdfRef) {
      final resolved = ast.objects[acroFormObj.objectNumber];
      if (resolved is PdfDict) return resolved;
    } else if (acroFormObj is PdfDict) {
      return acroFormObj;
    }

    final newObjNum = ast.nextAvailableObjectNumber();
    final newAcroForm = PdfDict({
      'Fields': PdfArray(const []),
      'NeedAppearances': const PdfBoolean(true),
    });
    ast.objects[newObjNum] = newAcroForm;
    ast.catalog['AcroForm'] = PdfRef(newObjNum);
    return newAcroForm;
  }

  /// Sets `/NeedAppearances true` on the document `/AcroForm` dictionary.
  static void setNeedAppearances(PdfDocumentAst ast, [bool value = true]) {
    final acroForm = ensureAcroForm(ast);
    acroForm['NeedAppearances'] = PdfBoolean(value);
  }

  /// Updates the value of [field] in [ast] and marks `/NeedAppearances true`.
  static bool updateFieldValue(
    PdfDocumentAst ast,
    PdfFormField field,
    dynamic newValue,
  ) {
    PdfDict? targetDict;

    if (field.widgetObjectNumber != null) {
      final resolved = ast.objects[field.widgetObjectNumber!];
      if (resolved is PdfDict) targetDict = resolved;
    }

    targetDict ??= _findFieldDictByName(ast, field.fullyQualifiedName);

    if (targetDict == null) return false;

    if (field is PdfTextFormField) {
      final textVal = newValue?.toString() ?? '';
      targetDict['V'] = PdfString.fromString(textVal);
    } else if (field is PdfCheckboxFormField) {
      final isChecked = newValue == true ||
          newValue == 'Yes' ||
          newValue == field.onValue ||
          newValue == 'true';
      final stateName = isChecked ? field.onValue : 'Off';
      targetDict['V'] = PdfName(stateName);
      targetDict['AS'] = PdfName(stateName);
    } else if (field is PdfRadioButtonFormField) {
      final radioVal = newValue?.toString() ?? 'Off';
      targetDict['V'] = PdfName(radioVal);
      targetDict['AS'] =
          PdfName(radioVal == field.buttonValue ? radioVal : 'Off');

      // Also update parent dictionary if linked
      final parentRef = targetDict['Parent'];
      if (parentRef is PdfRef) {
        final parentDict = ast.objects[parentRef.objectNumber];
        if (parentDict is PdfDict) {
          parentDict['V'] = PdfName(radioVal);
        }
      }
    } else if (field is PdfDropdownFormField) {
      final textVal = newValue?.toString() ?? '';
      targetDict['V'] = PdfString.fromString(textVal);
    } else if (field is PdfListBoxFormField) {
      if (newValue is List) {
        final arr = PdfArray(newValue
            .map((e) => PdfString.fromString(e.toString()))
            .toList());
        targetDict['V'] = arr;
      } else {
        targetDict['V'] = PdfString.fromString(newValue?.toString() ?? '');
      }
    }

    setNeedAppearances(ast, true);
    return true;
  }

  /// Resets all form fields in [ast] to their default values (`/DV`) or empty state.
  static void resetForm(PdfDocumentAst ast, List<PdfFormField> fields) {
    for (final field in fields) {
      if (field is PdfTextFormField) {
        updateFieldValue(ast, field, field.defaultText);
      } else if (field is PdfCheckboxFormField) {
        updateFieldValue(ast, field, field.defaultChecked);
      } else if (field is PdfRadioButtonFormField) {
        updateFieldValue(ast, field, field.defaultValue);
      } else if (field is PdfDropdownFormField) {
        updateFieldValue(ast, field, field.defaultValue);
      } else if (field is PdfListBoxFormField) {
        updateFieldValue(ast, field, field.defaultValues);
      }
    }
    setNeedAppearances(ast, true);
  }

  /// Flattens all interactive form fields into page content streams and removes `/AcroForm`.
  static void flattenForm(PdfDocumentAst ast, List<PdfFormField> fields) {
    // 1. Group fields by pageIndex
    final pageFieldsMap = <int, List<PdfFormField>>{};
    for (final field in fields) {
      if (field.pageIndex >= 0 && field.pageIndex < ast.pageCount) {
        pageFieldsMap.putIfAbsent(field.pageIndex, () => []).add(field);
      }
    }

    // 2. Burn visual text/boxes into page /Contents
    for (final entry in pageFieldsMap.entries) {
      final pageIndex = entry.key;
      final pageFields = entry.value;
      _burnFieldsIntoPage(ast, pageIndex, pageFields);
    }

    // 3. Remove /Widget annotations from all page /Annots arrays
    for (var i = 0; i < ast.pageCount; i++) {
      final pageDict = ast.getPageDict(i);
      final annots = pageDict.getArray('Annots');
      if (annots != null) {
        final filtered = <PdfObject>[];
        for (final item in annots.items) {
          PdfDict? annotDict;
          if (item is PdfRef) {
            final res = ast.objects[item.objectNumber];
            if (res is PdfDict) annotDict = res;
          } else if (item is PdfDict) {
            annotDict = item;
          }
          if (annotDict?.getName('Subtype') != 'Widget') {
            filtered.add(item);
          }
        }
        pageDict['Annots'] = PdfArray(filtered);
      }
    }

    // 4. Remove /AcroForm from Catalog
    ast.catalog.remove('AcroForm');
  }

  static void _burnFieldsIntoPage(
    PdfDocumentAst ast,
    int pageIndex,
    List<PdfFormField> fields,
  ) {
    final streamBuilder = StringBuffer();

    for (final field in fields) {
      if (!field.hasValue) continue;

      final b = field.bounds;
      if (field is PdfTextFormField && field.text.isNotEmpty) {
        final escaped = _escapePdfText(field.text);
        const fontSize = 11.0;
        final x = b.left + 2.0;
        final y = b.bottom + (b.height - fontSize) / 2.0 + 2.0;

        streamBuilder.write('q\n');
        streamBuilder.write('BT\n');
        streamBuilder.write('/Helv $fontSize Tf\n');
        streamBuilder.write('0 0 0 rg\n');
        streamBuilder.write('1 0 0 1 $x $y Tm\n');
        streamBuilder.write('($escaped) Tj\n');
        streamBuilder.write('ET\n');
        streamBuilder.write('Q\n');
      } else if (field is PdfCheckboxFormField && field.isChecked) {
        // Draw a checkmark mark inside bounds
        final cx = b.left + b.width / 2;
        final cy = b.bottom + b.height / 2;
        final size = (b.width < b.height ? b.width : b.height) * 0.6;

        streamBuilder.write('q\n');
        streamBuilder.write('1.5 w\n');
        streamBuilder.write('0 0 0 RG\n');
        streamBuilder.write('${cx - size * 0.4} $cy m\n');
        streamBuilder.write('${cx - size * 0.1} ${cy - size * 0.3} l\n');
        streamBuilder.write('${cx + size * 0.4} ${cy + size * 0.3} l\n');
        streamBuilder.write('S\n');
        streamBuilder.write('Q\n');
      } else if (field is PdfRadioButtonFormField && field.isSelected) {
        // Draw a filled dot inside circle
        final cx = b.left + b.width / 2;
        final cy = b.bottom + b.height / 2;
        final radius = (b.width < b.height ? b.width : b.height) * 0.25;

        streamBuilder.write('q\n');
        streamBuilder.write('0 0 0 rg\n');
        streamBuilder.write(
            '${cx - radius} $cy m\n'
            '${cx - radius} ${cy + radius * 0.55} ${cx - radius * 0.55} ${cy + radius} $cx ${cy + radius} c\n'
            '${cx + radius * 0.55} ${cy + radius} ${cx + radius} ${cy + radius * 0.55} ${cx + radius} $cy c\n'
            '${cx + radius} ${cy - radius * 0.55} ${cx + radius * 0.55} ${cy - radius} $cx ${cy - radius} c\n'
            '${cx - radius * 0.55} ${cy - radius} ${cx - radius} ${cy - radius * 0.55} ${cx - radius} $cy c\n'
            'f\n');
        streamBuilder.write('Q\n');
      } else if (field is PdfDropdownFormField &&
          field.selectedValue.isNotEmpty) {
        final escaped = _escapePdfText(field.selectedValue);
        const fontSize = 11.0;
        final x = b.left + 2.0;
        final y = b.bottom + (b.height - fontSize) / 2.0 + 2.0;

        streamBuilder.write('q\n');
        streamBuilder.write('BT\n');
        streamBuilder.write('/Helv $fontSize Tf\n');
        streamBuilder.write('0 0 0 rg\n');
        streamBuilder.write('1 0 0 1 $x $y Tm\n');
        streamBuilder.write('($escaped) Tj\n');
        streamBuilder.write('ET\n');
        streamBuilder.write('Q\n');
      }
    }

    final newContentBytes = utf8.encode(streamBuilder.toString());
    if (newContentBytes.isEmpty) return;

    final newStreamObjNum = ast.nextAvailableObjectNumber();
    final newStreamDict = PdfDict({
      'Length': PdfNumber(newContentBytes.length),
    });
    ast.objects[newStreamObjNum] =
        PdfStream(dict: newStreamDict, data: Uint8List.fromList(newContentBytes));
    ast.objectGenerations[newStreamObjNum] = 0;

    final pageDict = ast.getPageDict(pageIndex);
    final contentsObj = pageDict['Contents'];

    if (contentsObj is PdfArray) {
      contentsObj.add(PdfRef(newStreamObjNum));
    } else if (contentsObj is PdfRef) {
      pageDict['Contents'] = PdfArray([contentsObj, PdfRef(newStreamObjNum)]);
    } else {
      pageDict['Contents'] = PdfRef(newStreamObjNum);
    }
  }

  static PdfDict? _findFieldDictByName(PdfDocumentAst ast, String fqName) {
    final acroForm = ast.catalog['AcroForm'];
    if (acroForm == null) return null;

    PdfDict? acroDict;
    if (acroForm is PdfRef) {
      final res = ast.objects[acroForm.objectNumber];
      if (res is PdfDict) acroDict = res;
    } else if (acroForm is PdfDict) {
      acroDict = acroForm;
    }
    if (acroDict == null) return null;

    final fields = acroDict.getArray('Fields');
    if (fields == null) return null;

    for (final fRef in fields.items) {
      final match = _findInFieldTree(ast, fRef, '', fqName);
      if (match != null) return match;
    }
    return null;
  }

  static PdfDict? _findInFieldTree(
    PdfDocumentAst ast,
    PdfObject fieldObj,
    String parentName,
    String targetFqName,
  ) {
    PdfDict? dict;
    if (fieldObj is PdfRef) {
      final res = ast.objects[fieldObj.objectNumber];
      if (res is PdfDict) dict = res;
    } else if (fieldObj is PdfDict) {
      dict = fieldObj;
    }
    if (dict == null) return null;

    final t = dict.getString('T')?.asString() ?? '';
    final currentFqName = parentName.isEmpty
        ? t
        : t.isEmpty
            ? parentName
            : '$parentName.$t';

    if (currentFqName == targetFqName) return dict;

    final kids = dict.getArray('Kids');
    if (kids != null) {
      for (final kid in kids.items) {
        final match = _findInFieldTree(ast, kid, currentFqName, targetFqName);
        if (match != null) return match;
      }
    }

    return null;
  }

  static String _escapePdfText(String text) {
    return text
        .replaceAll(r'\', r'\\')
        .replaceAll('(', r'\(')
        .replaceAll(')', r'\)');
  }
}
