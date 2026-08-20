import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/pdf_geometry.dart';
import 'package:titan_reader/src/domain/entities/pdf_form_field.dart';

void main() {
  group('Phase 6C: AcroForm Domain Entities Tests', () {
    const defaultBox =
        PdfBoundingBox(left: 50, bottom: 650, right: 250, top: 670);

    test('PdfTextFormField properties, flags, and copyWith', () {
      const field = PdfTextFormField(
        id: 'txt_01',
        name: 'ApplicantName',
        fullyQualifiedName: 'Form.ApplicantName',
        pageIndex: 0,
        bounds: defaultBox,
        flags: 1 | (1 << 12), // Read-only + Multiline
        text: 'Dr. B.R. Ambedkar',
        defaultText: 'Enter name',
        maxLength: 100,
      );

      expect(field.fieldType, PdfFormFieldType.text);
      expect(field.isReadOnly, isTrue);
      expect(field.isMultiline, isTrue);
      expect(field.isPassword, isFalse);
      expect(field.isRequired, isFalse);
      expect(field.hasValue, isTrue);
      expect(field.exportValueString, 'Dr. B.R. Ambedkar');
      expect(field.maxLength, 100);

      final updated = field.copyWith(
        text: 'Updated Name',
        flags: 2, // Required
      );

      expect(updated.text, 'Updated Name');
      expect(updated.isReadOnly, isFalse);
      expect(updated.isRequired, isTrue);
      expect(updated.fullyQualifiedName, 'Form.ApplicantName');
    });

    test('PdfCheckboxFormField properties and states', () {
      const checkbox = PdfCheckboxFormField(
        id: 'chk_01',
        name: 'AgreeTerms',
        fullyQualifiedName: 'Form.AgreeTerms',
        pageIndex: 0,
        bounds: defaultBox,
        isChecked: true,
        defaultChecked: false,
        onValue: 'Yes',
      );

      expect(checkbox.fieldType, PdfFormFieldType.checkbox);
      expect(checkbox.isChecked, isTrue);
      expect(checkbox.hasValue, isTrue);
      expect(checkbox.exportValueString, 'Yes');

      final unchecked = checkbox.copyWith(isChecked: false);
      expect(unchecked.isChecked, isFalse);
      expect(unchecked.hasValue, isFalse);
      expect(unchecked.exportValueString, 'Off');
    });

    test('PdfRadioButtonFormField group selection logic', () {
      const radio1 = PdfRadioButtonFormField(
        id: 'rad_01',
        name: 'Gender',
        fullyQualifiedName: 'Form.Gender',
        groupName: 'Form.Gender',
        pageIndex: 0,
        bounds: defaultBox,
        buttonValue: 'Male',
        selectedValue: 'Male',
        options: ['Male', 'Female', 'Other'],
      );

      const radio2 = PdfRadioButtonFormField(
        id: 'rad_02',
        name: 'Gender',
        fullyQualifiedName: 'Form.Gender',
        groupName: 'Form.Gender',
        pageIndex: 0,
        bounds: defaultBox,
        buttonValue: 'Female',
        selectedValue: 'Male',
        options: ['Male', 'Female', 'Other'],
      );

      expect(radio1.isSelected, isTrue);
      expect(radio2.isSelected, isFalse);
      expect(radio1.exportValueString, 'Male');
      expect(radio2.exportValueString, 'Male');
    });

    test('PdfDropdownFormField options and display mapping', () {
      const dropdown = PdfDropdownFormField(
        id: 'drop_01',
        name: 'State',
        fullyQualifiedName: 'Form.State',
        pageIndex: 0,
        bounds: defaultBox,
        options: ['DL', 'MH', 'KA'],
        displayOptions: ['Delhi', 'Maharashtra', 'Karnataka'],
        selectedValue: 'DL',
      );

      expect(dropdown.fieldType, PdfFormFieldType.dropdown);
      expect(dropdown.selectedValue, 'DL');
      expect(dropdown.hasValue, isTrue);
      expect(dropdown.exportValueString, 'DL');
      expect(dropdown.displayOptions?.length, 3);
    });

    test('PdfListBoxFormField multi-selection logic', () {
      const listBox = PdfListBoxFormField(
        id: 'list_01',
        name: 'Subjects',
        fullyQualifiedName: 'Form.Subjects',
        pageIndex: 0,
        bounds: defaultBox,
        flags: 1 << 21, // Multi-select
        options: ['Polity', 'History', 'Geography', 'Economy'],
        selectedValues: ['Polity', 'Economy'],
      );

      expect(listBox.fieldType, PdfFormFieldType.listBox);
      expect(listBox.isMultiSelect, isTrue);
      expect(listBox.selectedValues.length, 2);
      expect(listBox.exportValueString, 'Polity, Economy');
      expect(listBox.hasValue, isTrue);
    });

    test('PdfFormDocument queries and serialization', () {
      const f1 = PdfTextFormField(
        id: 'f1',
        name: 'Name',
        fullyQualifiedName: 'Form.Name',
        pageIndex: 0,
        bounds: defaultBox,
        text: 'Sachin',
      );

      const f2 = PdfCheckboxFormField(
        id: 'f2',
        name: 'Agree',
        fullyQualifiedName: 'Form.Agree',
        pageIndex: 1,
        bounds: defaultBox,
        isChecked: true,
      );

      const doc = PdfFormDocument(
        hasAcroForm: true,
        needAppearances: true,
        fields: [f1, f2],
      );

      expect(doc.fieldCount, 2);
      expect(doc.fieldsOnPage(0).length, 1);
      expect(doc.fieldsOnPage(1).length, 1);
      expect(doc.findField('Form.Name'), f1);
      expect(doc.findField('Form.Agree'), f2);

      final exportMap = doc.exportValues();
      expect(exportMap['Form.Name'], 'Sachin');
      expect(exportMap['Form.Agree'], 'Yes');

      final json = doc.toJson();
      expect(json['hasAcroForm'], isTrue);
      expect(json['fields'], isA<List<dynamic>>());
    });

    test('PdfFormValidationResult validation checks', () {
      const err = PdfFormFieldValidationError(
        fieldId: 'f1',
        fullyQualifiedName: 'Form.Name',
        message: 'Field is required',
      );

      final res = PdfFormValidationResult.fromErrors(const [err]);
      expect(res.isValid, isFalse);
      expect(res.errors.length, 1);
      expect(res.errors.first.toString(), contains('Form.Name: Field is required'));

      const validRes = PdfFormValidationResult.valid();
      expect(validRes.isValid, isTrue);
      expect(validRes.errors, isEmpty);
    });
  });
}
