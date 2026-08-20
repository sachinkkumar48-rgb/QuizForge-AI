import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/pdf_form_field.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_document_ast.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_primitive.dart';
import 'package:titan_reader/src/manipulation/ast/pdf_writer.dart';
import 'package:titan_reader/src/manipulation/engine/default_pdf_form_engine.dart';
import 'package:titan_reader/src/manipulation/services/pdf_form_service.dart';

void main() {
  late Directory tempDir;
  late PdfFormService service;
  late DefaultPdfFormEngine engine;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('titan_form_service_test_');
    engine = const DefaultPdfFormEngine();
    service = PdfFormService(engine: engine);
  });

  tearDown(() async {
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('Phase 6C: PdfFormEngine & PdfFormService Tests', () {
    test('loadForm and updateFieldValue with atomic file persistence', () async {
      final doc = _createTestFormPdf();
      final pdfFile = File('${tempDir.path}/form_test.pdf');
      await pdfFile.writeAsBytes(PdfWriter(doc).writeBytes());

      final formDoc = await service.loadForm(pdfFile.path);
      expect(formDoc.hasAcroForm, isTrue);
      expect(formDoc.fieldCount, 2);

      await service.updateFieldValue(
        sourcePath: pdfFile.path,
        fieldIdentifier: 'Form.UserName',
        newValue: 'UPSC Aspirant',
        previousValue: 'Default User',
      );

      final reloaded = await service.loadForm(pdfFile.path);
      final tf = reloaded.findField('Form.UserName') as PdfTextFormField;
      expect(tf.text, 'UPSC Aspirant');

      // Test Undo
      service.undoStack.undo();
      final afterUndo = await service.loadForm(pdfFile.path);
      final tfAfterUndo =
          afterUndo.findField('Form.UserName') as PdfTextFormField;
      expect(tfAfterUndo.text, 'Default User');

      // Test Redo
      service.undoStack.redo();
      final afterRedo = await service.loadForm(pdfFile.path);
      final tfAfterRedo =
          afterRedo.findField('Form.UserName') as PdfTextFormField;
      expect(tfAfterRedo.text, 'UPSC Aspirant');
    });

    test('saveFormValues batch update and validation', () async {
      final doc = _createTestFormPdf();
      final pdfFile = File('${tempDir.path}/batch_form.pdf');
      await pdfFile.writeAsBytes(PdfWriter(doc).writeBytes());

      await service.saveFormValues(
        sourcePath: pdfFile.path,
        values: {
          'Form.UserName': 'Sardar Patel',
          'Form.IsVerified': true,
        },
      );

      final formDoc = await service.loadForm(pdfFile.path);
      final tf = formDoc.findField('Form.UserName') as PdfTextFormField;
      final cb = formDoc.findField('Form.IsVerified') as PdfCheckboxFormField;
      expect(tf.text, 'Sardar Patel');
      expect(cb.isChecked, isTrue);

      // Validation
      final validResult = service.validateForm(formDoc);
      expect(validResult.isValid, isTrue);
    });

    test('resetForm and flattenForm workflows', () async {
      final doc = _createTestFormPdf();
      final pdfFile = File('${tempDir.path}/reset_flatten.pdf');
      await pdfFile.writeAsBytes(PdfWriter(doc).writeBytes());

      // Update
      await service.updateFieldValue(
        sourcePath: pdfFile.path,
        fieldIdentifier: 'Form.UserName',
        newValue: 'Changed Name',
      );

      // Reset
      await service.resetForm(sourcePath: pdfFile.path);
      final afterReset = await service.loadForm(pdfFile.path);
      final tfReset = afterReset.findField('Form.UserName') as PdfTextFormField;
      expect(tfReset.text, 'Default User');

      // Flatten
      final flatPath = service.getFormFlattenedPath(pdfFile.path);
      await service.flattenForm(
          sourcePath: pdfFile.path, customOutputPath: flatPath);
      expect(File(flatPath).existsSync(), isTrue);

      final flatDoc = await service.loadForm(flatPath);
      expect(flatDoc.fields.isEmpty, isTrue);
    });

    test('FDF & JSON export and import service methods', () async {
      final doc = _createTestFormPdf();
      final pdfFile = File('${tempDir.path}/fdf_json_service.pdf');
      await pdfFile.writeAsBytes(PdfWriter(doc).writeBytes());

      final fdfOut = '${tempDir.path}/export.fdf';
      final jsonOut = '${tempDir.path}/export.json';

      // Export
      await service.exportFdf(sourcePath: pdfFile.path, outputPath: fdfOut);
      await service.exportJson(sourcePath: pdfFile.path, outputPath: jsonOut);

      expect(File(fdfOut).existsSync(), isTrue);
      expect(File(jsonOut).existsSync(), isTrue);

      // Import JSON into fresh target
      final targetPdf = File('${tempDir.path}/imported_target.pdf');
      await targetPdf.writeAsBytes(PdfWriter(doc).writeBytes());

      final jsonContent = File(jsonOut).readAsStringSync();
      await service.importJson(
        sourcePath: targetPdf.path,
        jsonString: jsonContent,
      );

      final importedDoc = await service.loadForm(targetPdf.path);
      final tf = importedDoc.findField('Form.UserName') as PdfTextFormField;
      expect(tf.text, 'Default User');
    });
  });
}

PdfDocumentAst _createTestFormPdf() {
  final objects = <int, PdfObject>{};
  final gens = <int, int>{};

  final textField = PdfDict({
    'FT': const PdfName('Tx'),
    'T': PdfString.fromString('UserName'),
    'V': PdfString.fromString('Default User'),
    'DV': PdfString.fromString('Default User'),
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

  final checkboxField = PdfDict({
    'FT': const PdfName('Btn'),
    'T': PdfString.fromString('IsVerified'),
    'V': const PdfName('Off'),
    'DV': const PdfName('Off'),
    'AS': const PdfName('Off'),
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

  final parentForm = PdfDict({
    'T': PdfString.fromString('Form'),
    'Kids': PdfArray(const [PdfRef(10), PdfRef(11)]),
  });
  objects[9] = parentForm;
  gens[9] = 0;

  final acroForm = PdfDict({
    'Fields': PdfArray(const [PdfRef(9)]),
    'NeedAppearances': const PdfBoolean(true),
  });
  objects[8] = acroForm;
  gens[8] = 0;

  final page = PdfDict({
    'Type': const PdfName('Page'),
    'Parent': const PdfRef(2),
    'MediaBox': PdfArray(const [
      PdfNumber(0),
      PdfNumber(0),
      PdfNumber(612),
      PdfNumber(792),
    ]),
    'Annots': PdfArray(const [PdfRef(10), PdfRef(11)]),
  });
  objects[3] = page;
  gens[3] = 0;

  final pages = PdfDict({
    'Type': const PdfName('Pages'),
    'Kids': PdfArray(const [PdfRef(3)]),
    'Count': const PdfNumber(1),
  });
  objects[2] = pages;
  gens[2] = 0;

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
