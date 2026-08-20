import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/pdf_form_field.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_document_ast.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_fdf_serializer.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_form_builder.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_form_parser.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_primitive.dart';

void main() {
  group('Phase 6C: AcroForm AST Parser, Builder & FDF Round-Trip Tests', () {
    test('Parse complete AcroForm field hierarchy from AST', () {
      final ast = _createFormAst();
      final formDoc = PdfFormParser.parseDocumentForm(ast);

      expect(formDoc.hasAcroForm, isTrue);
      expect(formDoc.fields.length, 5);

      // 1. Text Field
      final textField = formDoc.findField('Form.FullName');
      expect(textField, isA<PdfTextFormField>());
      final tf = textField as PdfTextFormField;
      expect(tf.name, 'FullName');
      expect(tf.fullyQualifiedName, 'Form.FullName');
      expect(tf.text, 'Sachin Kumar');
      expect(tf.defaultText, 'Default Name');
      expect(tf.pageIndex, 0);

      // 2. Checkbox Field
      final checkboxField = formDoc.findField('Form.Agree');
      expect(checkboxField, isA<PdfCheckboxFormField>());
      final cb = checkboxField as PdfCheckboxFormField;
      expect(cb.isChecked, isTrue);
      expect(cb.onValue, 'Yes');

      // 3. Radio Button Field
      final radioField = formDoc.findField('Form.Category');
      expect(radioField, isA<PdfRadioButtonFormField>());
      final rf = radioField as PdfRadioButtonFormField;
      expect(rf.selectedValue, 'General');

      // 4. Dropdown Field
      final dropField = formDoc.findField('Form.State');
      expect(dropField, isA<PdfDropdownFormField>());
      final df = dropField as PdfDropdownFormField;
      expect(df.options, ['DL', 'UP', 'MH']);
      expect(df.selectedValue, 'DL');

      // 5. List Box Field
      final listField = formDoc.findField('Form.Subjects');
      expect(listField, isA<PdfListBoxFormField>());
      final lf = listField as PdfListBoxFormField;
      expect(lf.selectedValues, ['Polity', 'History']);
    });

    test('Update field values via PdfFormBuilder and re-parse', () {
      final ast = _createFormAst();
      final formDoc = PdfFormParser.parseDocumentForm(ast);

      final textField = formDoc.findField('Form.FullName')!;
      final checkboxField = formDoc.findField('Form.Agree')!;

      PdfFormBuilder.updateFieldValue(ast, textField, 'New Applicant');
      PdfFormBuilder.updateFieldValue(ast, checkboxField, false);

      final reloaded = PdfFormParser.parseDocumentForm(ast);
      final updatedTf = reloaded.findField('Form.FullName') as PdfTextFormField;
      final updatedCb = reloaded.findField('Form.Agree') as PdfCheckboxFormField;

      expect(updatedTf.text, 'New Applicant');
      expect(updatedCb.isChecked, isFalse);
    });

    test('Reset form restoring default values', () {
      final ast = _createFormAst();
      final formDoc = PdfFormParser.parseDocumentForm(ast);

      // Mutate
      final tf = formDoc.findField('Form.FullName')!;
      PdfFormBuilder.updateFieldValue(ast, tf, 'Modified');

      // Reset
      PdfFormBuilder.resetForm(ast, formDoc.fields);

      final reloaded = PdfFormParser.parseDocumentForm(ast);
      final resetTf = reloaded.findField('Form.FullName') as PdfTextFormField;
      expect(resetTf.text, 'Default Name');
    });

    test('Flatten form burns values and strips AcroForm/widgets', () {
      final ast = _createFormAst();
      final formDoc = PdfFormParser.parseDocumentForm(ast);

      expect(ast.catalog.containsKey('AcroForm'), isTrue);

      PdfFormBuilder.flattenForm(ast, formDoc.fields);

      expect(ast.catalog.containsKey('AcroForm'), isFalse);
      final pageDict = ast.getPageDict(0);
      final annots = pageDict.getArray('Annots');
      expect(annots == null || annots.isEmpty, isTrue);
    });

    test('FDF & JSON export and import round-trip', () {
      final ast = _createFormAst();
      final formDoc = PdfFormParser.parseDocumentForm(ast);

      // FDF
      final fdfBytes = PdfFdfSerializer.exportToFdf(formDoc);
      expect(fdfBytes.isNotEmpty, isTrue);

      final importedFdf = PdfFdfSerializer.importFromFdf(fdfBytes);
      expect(importedFdf['Form.FullName'], 'Sachin Kumar');
      expect(importedFdf['Form.Agree'], 'Yes');

      // JSON
      final jsonStr = PdfFdfSerializer.exportToJson(formDoc);
      expect(jsonStr, contains('TITAN_ACROFORM_JSON'));

      final importedJson = PdfFdfSerializer.importFromJson(jsonStr);
      expect(importedJson['Form.FullName'], 'Sachin Kumar');
      expect(importedJson['Form.Agree'], isTrue);
    });
  });
}

PdfDocumentAst _createFormAst() {
  final objects = <int, PdfObject>{};
  final gens = <int, int>{};

  // Text field (obj 10)
  final textField = PdfDict({
    'FT': const PdfName('Tx'),
    'T': PdfString.fromString('FullName'),
    'V': PdfString.fromString('Sachin Kumar'),
    'DV': PdfString.fromString('Default Name'),
    'Subtype': const PdfName('Widget'),
    'Rect': PdfArray(const [
      PdfNumber(50),
      PdfNumber(700),
      PdfNumber(250),
      PdfNumber(720),
    ]),
    'P': const PdfRef(3),
  });
  objects[10] = textField;
  gens[10] = 0;

  // Checkbox field (obj 11)
  final checkboxField = PdfDict({
    'FT': const PdfName('Btn'),
    'T': PdfString.fromString('Agree'),
    'V': const PdfName('Yes'),
    'DV': const PdfName('Off'),
    'AS': const PdfName('Yes'),
    'Subtype': const PdfName('Widget'),
    'Rect': PdfArray(const [
      PdfNumber(50),
      PdfNumber(650),
      PdfNumber(70),
      PdfNumber(670),
    ]),
    'P': const PdfRef(3),
  });
  objects[11] = checkboxField;
  gens[11] = 0;

  // Radio button field (obj 12)
  final radioField = PdfDict({
    'FT': const PdfName('Btn'),
    'Ff': const PdfNumber(1 << 15), // Radio flag
    'T': PdfString.fromString('Category'),
    'V': const PdfName('General'),
    'DV': const PdfName('General'),
    'AS': const PdfName('General'),
    'Subtype': const PdfName('Widget'),
    'Rect': PdfArray(const [
      PdfNumber(50),
      PdfNumber(600),
      PdfNumber(70),
      PdfNumber(620),
    ]),
    'P': const PdfRef(3),
  });
  objects[12] = radioField;
  gens[12] = 0;

  // Dropdown field (obj 13)
  final dropdownField = PdfDict({
    'FT': const PdfName('Ch'),
    'Ff': const PdfNumber(1 << 17), // Combo flag
    'T': PdfString.fromString('State'),
    'V': PdfString.fromString('DL'),
    'DV': PdfString.fromString('DL'),
    'Opt': PdfArray([
      PdfString.fromString('DL'),
      PdfString.fromString('UP'),
      PdfString.fromString('MH'),
    ]),
    'Subtype': const PdfName('Widget'),
    'Rect': PdfArray(const [
      PdfNumber(50),
      PdfNumber(550),
      PdfNumber(200),
      PdfNumber(570),
    ]),
    'P': const PdfRef(3),
  });
  objects[13] = dropdownField;
  gens[13] = 0;

  // List box field (obj 14)
  final listBoxField = PdfDict({
    'FT': const PdfName('Ch'),
    'T': PdfString.fromString('Subjects'),
    'V': PdfArray([
      PdfString.fromString('Polity'),
      PdfString.fromString('History'),
    ]),
    'Opt': PdfArray([
      PdfString.fromString('Polity'),
      PdfString.fromString('History'),
      PdfString.fromString('Economy'),
    ]),
    'Subtype': const PdfName('Widget'),
    'Rect': PdfArray(const [
      PdfNumber(50),
      PdfNumber(450),
      PdfNumber(200),
      PdfNumber(530),
    ]),
    'P': const PdfRef(3),
  });
  objects[14] = listBoxField;
  gens[14] = 0;

  // Parent form node (obj 9)
  final parentForm = PdfDict({
    'T': PdfString.fromString('Form'),
    'Kids': PdfArray(const [
      PdfRef(10),
      PdfRef(11),
      PdfRef(12),
      PdfRef(13),
      PdfRef(14),
    ]),
  });
  objects[9] = parentForm;
  gens[9] = 0;

  // AcroForm dictionary (obj 8)
  final acroForm = PdfDict({
    'Fields': PdfArray(const [PdfRef(9)]),
    'NeedAppearances': const PdfBoolean(true),
  });
  objects[8] = acroForm;
  gens[8] = 0;

  // Page (obj 3)
  final page = PdfDict({
    'Type': const PdfName('Page'),
    'Parent': const PdfRef(2),
    'MediaBox': PdfArray(const [
      PdfNumber(0),
      PdfNumber(0),
      PdfNumber(612),
      PdfNumber(792),
    ]),
    'Annots': PdfArray(const [
      PdfRef(10),
      PdfRef(11),
      PdfRef(12),
      PdfRef(13),
      PdfRef(14),
    ]),
  });
  objects[3] = page;
  gens[3] = 0;

  // Pages root (obj 2)
  final pages = PdfDict({
    'Type': const PdfName('Pages'),
    'Kids': PdfArray(const [PdfRef(3)]),
    'Count': const PdfNumber(1),
  });
  objects[2] = pages;
  gens[2] = 0;

  // Catalog (obj 1)
  final catalog = PdfDict(const {
    'Type': PdfName('Catalog'),
    'Pages': PdfRef(2),
    'AcroForm': PdfRef(8),
  });
  objects[1] = catalog;
  gens[1] = 0;

  return PdfDocumentAst(
    header: '%PDF-1.7',
    objects: objects,
    objectGenerations: gens,
    trailer: PdfDict(const {'Root': PdfRef(1)}),
    catalog: catalog,
  );
}
