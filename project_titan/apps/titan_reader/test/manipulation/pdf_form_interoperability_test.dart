import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/pdf_geometry.dart';
import 'package:titan_reader/src/domain/entities/pdf_form_field.dart';
import 'package:titan_reader/src/widgets/forms/pdf_form_overlay_layer.dart';

void main() {
  group('Phase 6C: PdfFormOverlayLayer & Interoperability Widget Tests', () {
    testWidgets('Renders text, checkbox, radio, dropdown in interactive overlay',
        (tester) async {
      const tf = PdfTextFormField(
        id: 'tf_1',
        name: 'ApplicantName',
        fullyQualifiedName: 'Form.ApplicantName',
        pageIndex: 0,
        bounds: PdfBoundingBox(left: 50, bottom: 700, right: 250, top: 725),
        text: 'Maulana Azad',
      );

      const cb = PdfCheckboxFormField(
        id: 'cb_1',
        name: 'Agree',
        fullyQualifiedName: 'Form.Agree',
        pageIndex: 0,
        bounds: PdfBoundingBox(left: 50, bottom: 650, right: 70, top: 670),
        isChecked: true,
      );

      const rad = PdfRadioButtonFormField(
        id: 'rad_1',
        name: 'Tier',
        fullyQualifiedName: 'Form.Tier',
        groupName: 'Form.Tier',
        pageIndex: 0,
        bounds: PdfBoundingBox(left: 50, bottom: 600, right: 70, top: 620),
        buttonValue: 'Prelims',
        selectedValue: 'Prelims',
      );

      const drop = PdfDropdownFormField(
        id: 'drop_1',
        name: 'Medium',
        fullyQualifiedName: 'Form.Medium',
        pageIndex: 0,
        bounds: PdfBoundingBox(left: 50, bottom: 550, right: 200, top: 575),
        options: ['English', 'Hindi', 'Regional'],
        selectedValue: 'English',
      );

      var changedFieldId = '';
      dynamic changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 1000,
              child: PdfFormOverlayLayer(
                pageIndex: 0,
                pageSize: const Size(612, 792),
                viewportSize: const Size(800, 1000),
                fields: const [tf, cb, rad, drop],
                onFieldValueChanged: (field, val) {
                  changedFieldId = field.id;
                  changedValue = val;
                },
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Maulana Azad'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.text('English'), findsOneWidget);

      // Tap checkbox
      await tester.tap(find.byIcon(Icons.check));
      await tester.pump();
      expect(changedFieldId, 'cb_1');
      expect(changedValue, isFalse);

      // Enter text in TextField
      await tester.enterText(find.byType(TextField), 'Dr. Rajendra Prasad');
      await tester.pump();
      expect(changedFieldId, 'tf_1');
      expect(changedValue, 'Dr. Rajendra Prasad');
    });

    testWidgets('Empty fields on other pages render empty SizedBox',
        (tester) async {
      const tf = PdfTextFormField(
        id: 'tf_1',
        name: 'ApplicantName',
        fullyQualifiedName: 'Form.ApplicantName',
        pageIndex: 1, // Page 1
        bounds: PdfBoundingBox(left: 50, bottom: 700, right: 250, top: 725),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PdfFormOverlayLayer(
              pageIndex: 0, // Page 0 requested
              pageSize: Size(612, 792),
              viewportSize: Size(800, 1000),
              fields: [tf],
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsNothing);
    });
  });
}
