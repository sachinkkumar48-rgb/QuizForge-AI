import '../../domain/entities/pdf_geometry.dart';
import '../../domain/entities/pdf_form_field.dart';
import 'pdf_document_ast.dart';
import 'pdf_primitive.dart';

/// Parses ISO 32000-1 `/AcroForm` and `/Widget` dictionaries from [PdfDocumentAst].
class PdfFormParser {
  /// Extracts the complete [PdfFormDocument] from [ast].
  static PdfFormDocument parseDocumentForm(PdfDocumentAst ast) {
    final acroFormObj = ast.catalog['AcroForm'];
    if (acroFormObj == null) {
      // Also scan pages for standalone widgets if any
      final standaloneFields = _parseStandalonePageWidgets(ast);
      return PdfFormDocument(
        hasAcroForm: standaloneFields.isNotEmpty,
        needAppearances: false,
        sigFlags: 0,
        fields: standaloneFields,
      );
    }

    PdfDict? acroFormDict;
    if (acroFormObj is PdfRef) {
      final resolved = ast.objects[acroFormObj.objectNumber];
      if (resolved is PdfDict) acroFormDict = resolved;
    } else if (acroFormObj is PdfDict) {
      acroFormDict = acroFormObj;
    }

    if (acroFormDict == null) {
      return const PdfFormDocument.empty();
    }

    final needAppearancesObj = acroFormDict['NeedAppearances'];
    final needAppearances =
        needAppearancesObj is PdfBoolean ? needAppearancesObj.value : false;
    final sigFlags = acroFormDict.getInt('SigFlags') ?? 0;
    final fieldsArray = acroFormDict.getArray('Fields');

    final fields = <PdfFormField>[];
    final defaultDA = acroFormDict.getString('DA')?.asString();
    final defaultQ = acroFormDict.getInt('Q');

    // Build page reference map (pageObjNum -> 0-based pageIndex)
    final pageRefMap = <int, int>{};
    for (var i = 0; i < ast.pageCount; i++) {
      pageRefMap[ast.pageRefs[i].objectNumber] = i;
    }

    if (fieldsArray != null) {
      for (final fieldRef in fieldsArray.items) {
        _parseFieldTree(
          ast: ast,
          fieldObj: fieldRef,
          pageRefMap: pageRefMap,
          parentName: '',
          inheritedFT: null,
          inheritedFf: 0,
          inheritedDA: defaultDA,
          inheritedQ: defaultQ,
          collectedFields: fields,
        );
      }
    }

    // If no fields found in /Fields array, fallback to page widgets
    if (fields.isEmpty) {
      fields.addAll(_parseStandalonePageWidgets(ast));
    }

    return PdfFormDocument(
      hasAcroForm: true,
      needAppearances: needAppearances,
      sigFlags: sigFlags,
      fields: fields,
    );
  }

  static void _parseFieldTree({
    required PdfDocumentAst ast,
    required PdfObject fieldObj,
    required Map<int, int> pageRefMap,
    required String parentName,
    required String? inheritedFT,
    required int inheritedFf,
    required String? inheritedDA,
    required int? inheritedQ,
    required List<PdfFormField> collectedFields,
  }) {
    PdfDict? dict;
    int? objNum;

    if (fieldObj is PdfRef) {
      objNum = fieldObj.objectNumber;
      final resolved = ast.objects[objNum];
      if (resolved is PdfDict) dict = resolved;
    } else if (fieldObj is PdfDict) {
      dict = fieldObj;
    }

    if (dict == null) return;

    final partialName = dict.getString('T')?.asString() ?? '';
    final fullyQualifiedName = parentName.isEmpty
        ? partialName
        : partialName.isEmpty
            ? parentName
            : '$parentName.$partialName';

    final fieldType = dict.getName('FT') ?? inheritedFT;
    final flags = dict.getInt('Ff') ?? inheritedFf;
    final da = dict.getString('DA')?.asString() ?? inheritedDA;
    final q = dict.getInt('Q') ?? inheritedQ;
    final alternateName = dict.getString('TU')?.asString();
    final mappingName = dict.getString('TM')?.asString();

    final kids = dict.getArray('Kids');

    // Check if kids are child fields (have /T or /Kids) vs widget annotations
    if (kids != null && kids.isNotEmpty) {
      var isNonTerminal = false;
      for (final kid in kids.items) {
        final kidDict = _resolveDict(ast, kid);
        if (kidDict != null &&
            (kidDict.containsKey('T') ||
                kidDict.containsKey('Kids') ||
                kidDict.containsKey('FT'))) {
          isNonTerminal = true;
          break;
        }
      }

      if (isNonTerminal) {
        // Recurse into child fields
        for (final kid in kids.items) {
          _parseFieldTree(
            ast: ast,
            fieldObj: kid,
            pageRefMap: pageRefMap,
            parentName: fullyQualifiedName,
            inheritedFT: fieldType,
            inheritedFf: flags,
            inheritedDA: da,
            inheritedQ: q,
            collectedFields: collectedFields,
          );
        }
        return;
      }
    }

    // Terminal field — could have 1 widget merged into this dict, or multiple kids widgets
    if (kids != null && kids.isNotEmpty) {
      // Multiple widget representations (e.g. radio buttons on different pages or multiple instances)
      final radioFlag = (flags & (1 << 15)) != 0;
      final isBtn = fieldType == 'Btn';

      if (isBtn && radioFlag) {
        // Parse radio button options
        final selectedVal = _extractStringOrName(dict['V']) ?? 'Off';
        final defaultVal = _extractStringOrName(dict['DV']) ?? 'Off';
        final options = <String>[];

        for (var i = 0; i < kids.length; i++) {
          final kidObj = kids[i];
          final kidDict = _resolveDict(ast, kidObj);
          final kidNum = kidObj is PdfRef ? kidObj.objectNumber : null;
          if (kidDict == null) continue;

          final pageIndex = _findPageIndex(ast, kidDict, pageRefMap);
          final bounds = _parseRect(kidDict.getArray('Rect'));

          // Extract option button export value from /AP /N subdictionary keys or /AS
          final buttonValue = _extractRadioButtonExportValue(kidDict, i);
          if (!options.contains(buttonValue) && buttonValue != 'Off') {
            options.add(buttonValue);
          }

          collectedFields.add(PdfRadioButtonFormField(
            id: 'radio_${objNum ?? collectedFields.length}_$i',
            name: partialName,
            fullyQualifiedName: fullyQualifiedName,
            groupName: fullyQualifiedName,
            alternateName: alternateName,
            mappingName: mappingName,
            pageIndex: pageIndex,
            bounds: bounds,
            flags: flags,
            defaultAppearance: da,
            alignment: q,
            widgetObjectNumber: kidNum,
            selectedValue: selectedVal,
            defaultValue: defaultVal,
            options: options,
            buttonValue: buttonValue,
          ));
        }
        return;
      } else {
        // Other multiple-widget terminal field
        for (var i = 0; i < kids.length; i++) {
          final kidObj = kids[i];
          final kidDict = _resolveDict(ast, kidObj);
          final kidNum = kidObj is PdfRef ? kidObj.objectNumber : null;
          if (kidDict == null) continue;

          final mergedEntries = Map<String, PdfObject>.from(dict.entries)
            ..addAll(kidDict.entries);
          final mergedDict = PdfDict(mergedEntries);
          final field = _parseSingleFieldDict(
            ast: ast,
            dict: mergedDict,
            objNum: kidNum ?? objNum,
            fullyQualifiedName: fullyQualifiedName,
            partialName: partialName,
            fieldType: fieldType,
            flags: flags,
            da: da,
            q: q,
            alternateName: alternateName,
            mappingName: mappingName,
            pageRefMap: pageRefMap,
          );
          if (field != null) collectedFields.add(field);
        }
        return;
      }
    }

    // Single widget merged into field dictionary
    final field = _parseSingleFieldDict(
      ast: ast,
      dict: dict,
      objNum: objNum,
      fullyQualifiedName: fullyQualifiedName,
      partialName: partialName,
      fieldType: fieldType,
      flags: flags,
      da: da,
      q: q,
      alternateName: alternateName,
      mappingName: mappingName,
      pageRefMap: pageRefMap,
    );
    if (field != null) collectedFields.add(field);
  }

  static PdfFormField? _parseSingleFieldDict({
    required PdfDocumentAst ast,
    required PdfDict dict,
    required int? objNum,
    required String fullyQualifiedName,
    required String partialName,
    required String? fieldType,
    required int flags,
    required String? da,
    required int? q,
    required String? alternateName,
    required String? mappingName,
    required Map<int, int> pageRefMap,
  }) {
    final pageIndex = _findPageIndex(ast, dict, pageRefMap);
    final bounds = _parseRect(dict.getArray('Rect'));
    final id = 'field_${objNum ?? fullyQualifiedName}_$pageIndex';

    if (fieldType == 'Tx') {
      final value = _extractStringOrName(dict['V']) ?? '';
      final defaultValue = _extractStringOrName(dict['DV']) ?? '';
      final maxLen = dict.getInt('MaxLen');

      return PdfTextFormField(
        id: id,
        name: partialName,
        fullyQualifiedName: fullyQualifiedName,
        alternateName: alternateName,
        mappingName: mappingName,
        pageIndex: pageIndex,
        bounds: bounds,
        flags: flags,
        defaultAppearance: da,
        alignment: q,
        widgetObjectNumber: objNum,
        text: value,
        defaultText: defaultValue,
        maxLength: maxLen,
      );
    } else if (fieldType == 'Btn') {
      final pushBtnFlag = (flags & (1 << 16)) != 0;
      final radioFlag = (flags & (1 << 15)) != 0;

      if (pushBtnFlag) {
        return PdfPushButtonFormField(
          id: id,
          name: partialName,
          fullyQualifiedName: fullyQualifiedName,
          alternateName: alternateName,
          mappingName: mappingName,
          pageIndex: pageIndex,
          bounds: bounds,
          flags: flags,
          defaultAppearance: da,
          alignment: q,
          widgetObjectNumber: objNum,
          label: dict.getString('CA')?.asString() ?? partialName,
        );
      } else if (radioFlag) {
        final value = _extractStringOrName(dict['V']) ?? 'Off';
        final defaultValue = _extractStringOrName(dict['DV']) ?? 'Off';
        final buttonValue = _extractRadioButtonExportValue(dict, 0);

        return PdfRadioButtonFormField(
          id: id,
          name: partialName,
          fullyQualifiedName: fullyQualifiedName,
          groupName: fullyQualifiedName,
          alternateName: alternateName,
          mappingName: mappingName,
          pageIndex: pageIndex,
          bounds: bounds,
          flags: flags,
          defaultAppearance: da,
          alignment: q,
          widgetObjectNumber: objNum,
          selectedValue: value,
          defaultValue: defaultValue,
          options: [buttonValue],
          buttonValue: buttonValue,
        );
      } else {
        // Checkbox
        final valObj = dict['V'];
        final dvObj = dict['DV'];
        var isChecked = false;
        var onVal = 'Yes';

        if (valObj is PdfName) {
          isChecked = valObj.name != 'Off';
          if (isChecked) onVal = valObj.name;
        } else if (valObj is PdfBoolean) {
          isChecked = valObj.value;
        } else if (valObj is PdfString) {
          isChecked = valObj.asString() != 'Off';
        }

        final defaultChecked = dvObj is PdfName
            ? dvObj.name != 'Off'
            : (dvObj is PdfBoolean ? dvObj.value : false);

        return PdfCheckboxFormField(
          id: id,
          name: partialName,
          fullyQualifiedName: fullyQualifiedName,
          alternateName: alternateName,
          mappingName: mappingName,
          pageIndex: pageIndex,
          bounds: bounds,
          flags: flags,
          defaultAppearance: da,
          alignment: q,
          widgetObjectNumber: objNum,
          isChecked: isChecked,
          defaultChecked: defaultChecked,
          onValue: onVal,
        );
      }
    } else if (fieldType == 'Ch') {
      final comboFlag = (flags & (1 << 17)) != 0;
      final optArray = dict.getArray('Opt');
      final options = <String>[];
      final displayOptions = <String>[];

      if (optArray != null) {
        for (final optItem in optArray.items) {
          if (optItem is PdfString) {
            options.add(optItem.asString());
          } else if (optItem is PdfArray && optItem.length >= 2) {
            final exportVal = optItem[0] is PdfString
                ? (optItem[0] as PdfString).asString()
                : optItem[0].toString();
            final dispVal = optItem[1] is PdfString
                ? (optItem[1] as PdfString).asString()
                : optItem[1].toString();
            options.add(exportVal);
            displayOptions.add(dispVal);
          }
        }
      }

      if (comboFlag) {
        final val = _extractStringOrName(dict['V']) ?? '';
        final dVal = _extractStringOrName(dict['DV']) ?? '';
        return PdfDropdownFormField(
          id: id,
          name: partialName,
          fullyQualifiedName: fullyQualifiedName,
          alternateName: alternateName,
          mappingName: mappingName,
          pageIndex: pageIndex,
          bounds: bounds,
          flags: flags,
          defaultAppearance: da,
          alignment: q,
          widgetObjectNumber: objNum,
          selectedValue: val,
          defaultValue: dVal,
          options: options,
          displayOptions:
              displayOptions.isNotEmpty ? displayOptions : null,
        );
      } else {
        // List box
        final valObj = dict['V'];
        final selectedList = <String>[];
        if (valObj is PdfString) {
          selectedList.add(valObj.asString());
        } else if (valObj is PdfArray) {
          for (final item in valObj.items) {
            if (item is PdfString) selectedList.add(item.asString());
          }
        }

        return PdfListBoxFormField(
          id: id,
          name: partialName,
          fullyQualifiedName: fullyQualifiedName,
          alternateName: alternateName,
          mappingName: mappingName,
          pageIndex: pageIndex,
          bounds: bounds,
          flags: flags,
          defaultAppearance: da,
          alignment: q,
          widgetObjectNumber: objNum,
          selectedValues: selectedList,
          options: options,
        );
      }
    } else if (fieldType == 'Sig') {
      final hasV = dict.containsKey('V');
      return PdfSignatureFormField(
        id: id,
        name: partialName,
        fullyQualifiedName: fullyQualifiedName,
        alternateName: alternateName,
        mappingName: mappingName,
        pageIndex: pageIndex,
        bounds: bounds,
        flags: flags,
        defaultAppearance: da,
        alignment: q,
        widgetObjectNumber: objNum,
        isSigned: hasV,
      );
    }

    return null;
  }

  static List<PdfFormField> _parseStandalonePageWidgets(PdfDocumentAst ast) {
    final fields = <PdfFormField>[];
    final pageRefMap = <int, int>{};
    for (var i = 0; i < ast.pageCount; i++) {
      pageRefMap[ast.pageRefs[i].objectNumber] = i;
    }

    for (var pageIdx = 0; pageIdx < ast.pageCount; pageIdx++) {
      final pageDict = ast.getPageDict(pageIdx);
      final annots = pageDict.getArray('Annots');
      if (annots == null) continue;

      for (var annotIdx = 0; annotIdx < annots.length; annotIdx++) {
        final item = annots[annotIdx];
        final annotDict = _resolveDict(ast, item);
        final objNum = item is PdfRef ? item.objectNumber : null;
        if (annotDict == null) continue;

        if (annotDict.getName('Subtype') == 'Widget') {
          final ft = annotDict.getName('FT');
          final t = annotDict.getString('T')?.asString() ??
              'widget_${pageIdx}_$annotIdx';
          final ff = annotDict.getInt('Ff') ?? 0;
          final field = _parseSingleFieldDict(
            ast: ast,
            dict: annotDict,
            objNum: objNum,
            fullyQualifiedName: t,
            partialName: t,
            fieldType: ft ?? 'Tx',
            flags: ff,
            da: annotDict.getString('DA')?.asString(),
            q: annotDict.getInt('Q'),
            alternateName: annotDict.getString('TU')?.asString(),
            mappingName: annotDict.getString('TM')?.asString(),
            pageRefMap: pageRefMap,
          );
          if (field != null) fields.add(field);
        }
      }
    }

    return fields;
  }

  static PdfDict? _resolveDict(PdfDocumentAst ast, PdfObject? obj) {
    if (obj is PdfRef) {
      final resolved = ast.objects[obj.objectNumber];
      return resolved is PdfDict ? resolved : null;
    }
    return obj is PdfDict ? obj : null;
  }

  static int _findPageIndex(
    PdfDocumentAst ast,
    PdfDict dict,
    Map<int, int> pageRefMap,
  ) {
    final pRef = dict['P'];
    if (pRef is PdfRef && pageRefMap.containsKey(pRef.objectNumber)) {
      return pageRefMap[pRef.objectNumber]!;
    }
    return 0;
  }

  static PdfBoundingBox _parseRect(PdfArray? rectArray) {
    if (rectArray == null || rectArray.length < 4) {
      return const PdfBoundingBox(left: 0, bottom: 0, right: 100, top: 20);
    }
    final llx = _toDouble(rectArray[0]);
    final lly = _toDouble(rectArray[1]);
    final urx = _toDouble(rectArray[2]);
    final ury = _toDouble(rectArray[3]);
    return PdfBoundingBox(left: llx, bottom: lly, right: urx, top: ury);
  }

  static double _toDouble(PdfObject obj) {
    if (obj is PdfNumber) return obj.asDouble;
    return 0.0;
  }

  static String? _extractStringOrName(PdfObject? obj) {
    if (obj is PdfString) return obj.asString();
    if (obj is PdfName) return obj.name;
    if (obj is PdfBoolean) return obj.value ? 'Yes' : 'Off';
    return null;
  }

  static String _extractRadioButtonExportValue(PdfDict widgetDict, int index) {
    final ap = widgetDict.getDict('AP');
    if (ap != null) {
      final n = ap.getDict('N');
      if (n != null) {
        for (final key in n.entries.keys) {
          if (key != 'Off') return key;
        }
      }
    }
    final asVal = widgetDict.getName('AS');
    if (asVal != null && asVal != 'Off') return asVal;
    return 'Option_${index + 1}';
  }
}
