import 'package:meta/meta.dart';
import 'pdf_geometry.dart';

/// Supported types of AcroForm fields (ISO 32000-1 §12.7.4).
enum PdfFormFieldType {
  text,
  checkbox,
  radioButton,
  dropdown,
  listBox,
  pushButton,
  signature,
}

/// Base class representing an AcroForm field in a PDF document.
@immutable
abstract class PdfFormField {
  final String id;
  final String name;
  final String fullyQualifiedName;
  final String? alternateName; // /TU (tooltips/accessibility)
  final String? mappingName; // /TM
  final int pageIndex;
  final PdfBoundingBox bounds;
  final int flags; // /Ff
  final String? defaultAppearance; // /DA
  final int? alignment; // /Q (0: left, 1: center, 2: right)
  final int? widgetObjectNumber;

  const PdfFormField({
    required this.id,
    required this.name,
    required this.fullyQualifiedName,
    this.alternateName,
    this.mappingName,
    required this.pageIndex,
    required this.bounds,
    this.flags = 0,
    this.defaultAppearance,
    this.alignment,
    this.widgetObjectNumber,
  });

  PdfFormFieldType get fieldType;

  /// Whether the field is marked Read-Only (bit 1 of /Ff).
  bool get isReadOnly => (flags & 1) != 0;

  /// Whether the field is marked Required (bit 2 of /Ff).
  bool get isRequired => (flags & 2) != 0;

  /// Whether the field is excluded from export (bit 3 of /Ff).
  bool get isNoExport => (flags & 4) != 0;

  /// Formatted string value of the field for export and FDF serialization.
  String get exportValueString;

  /// Whether this field currently holds a non-empty / valid value.
  bool get hasValue;

  Map<String, dynamic> toJson();

  PdfFormField copyWith();
}

/// Represents a Text input field (`/FT /Tx`).
@immutable
class PdfTextFormField extends PdfFormField {
  final String text;
  final String defaultText;
  final int? maxLength; // /MaxLen

  const PdfTextFormField({
    required super.id,
    required super.name,
    required super.fullyQualifiedName,
    super.alternateName,
    super.mappingName,
    required super.pageIndex,
    required super.bounds,
    super.flags = 0,
    super.defaultAppearance,
    super.alignment,
    super.widgetObjectNumber,
    this.text = '',
    this.defaultText = '',
    this.maxLength,
  });

  @override
  PdfFormFieldType get fieldType => PdfFormFieldType.text;

  /// Bit 13: Multiline text field.
  bool get isMultiline => (flags & (1 << 12)) != 0;

  /// Bit 14: Password field.
  bool get isPassword => (flags & (1 << 13)) != 0;

  /// Bit 21: File select field.
  bool get isFileSelect => (flags & (1 << 20)) != 0;

  /// Bit 23: Do not spell check.
  bool get doNotSpellCheck => (flags & (1 << 22)) != 0;

  /// Bit 24: Do not scroll.
  bool get doNotScroll => (flags & (1 << 23)) != 0;

  /// Bit 25: Comb field (equal spacing per character).
  bool get isComb => (flags & (1 << 24)) != 0;

  @override
  String get exportValueString => text;

  @override
  bool get hasValue => text.isNotEmpty;

  @override
  PdfTextFormField copyWith({
    String? text,
    String? defaultText,
    int? maxLength,
    String? alternateName,
    String? mappingName,
    PdfBoundingBox? bounds,
    int? flags,
    String? defaultAppearance,
    int? alignment,
    int? widgetObjectNumber,
  }) {
    return PdfTextFormField(
      id: id,
      name: name,
      fullyQualifiedName: fullyQualifiedName,
      alternateName: alternateName ?? this.alternateName,
      mappingName: mappingName ?? this.mappingName,
      pageIndex: pageIndex,
      bounds: bounds ?? this.bounds,
      flags: flags ?? this.flags,
      defaultAppearance: defaultAppearance ?? this.defaultAppearance,
      alignment: alignment ?? this.alignment,
      widgetObjectNumber: widgetObjectNumber ?? this.widgetObjectNumber,
      text: text ?? this.text,
      defaultText: defaultText ?? this.defaultText,
      maxLength: maxLength ?? this.maxLength,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'fullyQualifiedName': fullyQualifiedName,
        'type': 'text',
        'pageIndex': pageIndex,
        'bounds': [bounds.left, bounds.bottom, bounds.right, bounds.top],
        'flags': flags,
        'text': text,
        'defaultText': defaultText,
        if (maxLength != null) 'maxLength': maxLength,
        if (alternateName != null) 'alternateName': alternateName,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfTextFormField &&
          other.id == id &&
          other.fullyQualifiedName == fullyQualifiedName &&
          other.text == text &&
          other.flags == flags &&
          other.bounds == bounds;

  @override
  int get hashCode => Object.hash(id, fullyQualifiedName, text, flags, bounds);
}

/// Represents a Checkbox button field (`/FT /Btn`).
@immutable
class PdfCheckboxFormField extends PdfFormField {
  final bool isChecked;
  final bool defaultChecked;
  final String onValue; // Standard is /Yes or /On or custom name

  const PdfCheckboxFormField({
    required super.id,
    required super.name,
    required super.fullyQualifiedName,
    super.alternateName,
    super.mappingName,
    required super.pageIndex,
    required super.bounds,
    super.flags = 0,
    super.defaultAppearance,
    super.alignment,
    super.widgetObjectNumber,
    this.isChecked = false,
    this.defaultChecked = false,
    this.onValue = 'Yes',
  });

  @override
  PdfFormFieldType get fieldType => PdfFormFieldType.checkbox;

  @override
  String get exportValueString => isChecked ? onValue : 'Off';

  @override
  bool get hasValue => isChecked;

  @override
  PdfCheckboxFormField copyWith({
    bool? isChecked,
    bool? defaultChecked,
    String? onValue,
    String? alternateName,
    String? mappingName,
    PdfBoundingBox? bounds,
    int? flags,
    String? defaultAppearance,
    int? alignment,
    int? widgetObjectNumber,
  }) {
    return PdfCheckboxFormField(
      id: id,
      name: name,
      fullyQualifiedName: fullyQualifiedName,
      alternateName: alternateName ?? this.alternateName,
      mappingName: mappingName ?? this.mappingName,
      pageIndex: pageIndex,
      bounds: bounds ?? this.bounds,
      flags: flags ?? this.flags,
      defaultAppearance: defaultAppearance ?? this.defaultAppearance,
      alignment: alignment ?? this.alignment,
      widgetObjectNumber: widgetObjectNumber ?? this.widgetObjectNumber,
      isChecked: isChecked ?? this.isChecked,
      defaultChecked: defaultChecked ?? this.defaultChecked,
      onValue: onValue ?? this.onValue,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'fullyQualifiedName': fullyQualifiedName,
        'type': 'checkbox',
        'pageIndex': pageIndex,
        'bounds': [bounds.left, bounds.bottom, bounds.right, bounds.top],
        'flags': flags,
        'isChecked': isChecked,
        'defaultChecked': defaultChecked,
        'onValue': onValue,
        if (alternateName != null) 'alternateName': alternateName,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfCheckboxFormField &&
          other.id == id &&
          other.fullyQualifiedName == fullyQualifiedName &&
          other.isChecked == isChecked &&
          other.onValue == onValue &&
          other.bounds == bounds;

  @override
  int get hashCode =>
      Object.hash(id, fullyQualifiedName, isChecked, onValue, bounds);
}

/// Represents a Radio Button field option (`/FT /Btn` with radio flag).
@immutable
class PdfRadioButtonFormField extends PdfFormField {
  final String groupName;
  final String selectedValue;
  final String defaultValue;
  final List<String> options;
  final String buttonValue; // The value this specific radio widget represents

  const PdfRadioButtonFormField({
    required super.id,
    required super.name,
    required super.fullyQualifiedName,
    required this.groupName,
    super.alternateName,
    super.mappingName,
    required super.pageIndex,
    required super.bounds,
    super.flags = 0,
    super.defaultAppearance,
    super.alignment,
    super.widgetObjectNumber,
    this.selectedValue = '',
    this.defaultValue = '',
    this.options = const [],
    required this.buttonValue,
  });

  @override
  PdfFormFieldType get fieldType => PdfFormFieldType.radioButton;

  bool get isSelected => selectedValue == buttonValue && buttonValue.isNotEmpty;

  /// Bit 15: NoToggleToOff (a selected button cannot be deselected by clicking it).
  bool get noToggleToOff => (flags & (1 << 14)) != 0;

  @override
  String get exportValueString => selectedValue;

  @override
  bool get hasValue => selectedValue.isNotEmpty && selectedValue != 'Off';

  @override
  PdfRadioButtonFormField copyWith({
    String? selectedValue,
    String? defaultValue,
    List<String>? options,
    String? buttonValue,
    String? alternateName,
    String? mappingName,
    PdfBoundingBox? bounds,
    int? flags,
    String? defaultAppearance,
    int? alignment,
    int? widgetObjectNumber,
  }) {
    return PdfRadioButtonFormField(
      id: id,
      name: name,
      fullyQualifiedName: fullyQualifiedName,
      groupName: groupName,
      alternateName: alternateName ?? this.alternateName,
      mappingName: mappingName ?? this.mappingName,
      pageIndex: pageIndex,
      bounds: bounds ?? this.bounds,
      flags: flags ?? this.flags,
      defaultAppearance: defaultAppearance ?? this.defaultAppearance,
      alignment: alignment ?? this.alignment,
      widgetObjectNumber: widgetObjectNumber ?? this.widgetObjectNumber,
      selectedValue: selectedValue ?? this.selectedValue,
      defaultValue: defaultValue ?? this.defaultValue,
      options: options ?? this.options,
      buttonValue: buttonValue ?? this.buttonValue,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'fullyQualifiedName': fullyQualifiedName,
        'groupName': groupName,
        'type': 'radioButton',
        'pageIndex': pageIndex,
        'bounds': [bounds.left, bounds.bottom, bounds.right, bounds.top],
        'flags': flags,
        'selectedValue': selectedValue,
        'buttonValue': buttonValue,
        'options': options,
        if (alternateName != null) 'alternateName': alternateName,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfRadioButtonFormField &&
          other.id == id &&
          other.fullyQualifiedName == fullyQualifiedName &&
          other.selectedValue == selectedValue &&
          other.buttonValue == buttonValue &&
          other.bounds == bounds;

  @override
  int get hashCode => Object.hash(
      id, fullyQualifiedName, selectedValue, buttonValue, bounds);
}

/// Represents a Choice field dropdown / combo box (`/FT /Ch` combo).
@immutable
class PdfDropdownFormField extends PdfFormField {
  final String selectedValue;
  final String defaultValue;
  final List<String> options;
  final List<String>? displayOptions;

  const PdfDropdownFormField({
    required super.id,
    required super.name,
    required super.fullyQualifiedName,
    super.alternateName,
    super.mappingName,
    required super.pageIndex,
    required super.bounds,
    super.flags = 0,
    super.defaultAppearance,
    super.alignment,
    super.widgetObjectNumber,
    this.selectedValue = '',
    this.defaultValue = '',
    this.options = const [],
    this.displayOptions,
  });

  @override
  PdfFormFieldType get fieldType => PdfFormFieldType.dropdown;

  /// Bit 19: Editable combo box.
  bool get isEditable => (flags & (1 << 18)) != 0;

  /// Bit 20: Options sorted alphabetically.
  bool get isSorted => (flags & (1 << 19)) != 0;

  @override
  String get exportValueString => selectedValue;

  @override
  bool get hasValue => selectedValue.isNotEmpty;

  @override
  PdfDropdownFormField copyWith({
    String? selectedValue,
    String? defaultValue,
    List<String>? options,
    List<String>? displayOptions,
    String? alternateName,
    String? mappingName,
    PdfBoundingBox? bounds,
    int? flags,
    String? defaultAppearance,
    int? alignment,
    int? widgetObjectNumber,
  }) {
    return PdfDropdownFormField(
      id: id,
      name: name,
      fullyQualifiedName: fullyQualifiedName,
      alternateName: alternateName ?? this.alternateName,
      mappingName: mappingName ?? this.mappingName,
      pageIndex: pageIndex,
      bounds: bounds ?? this.bounds,
      flags: flags ?? this.flags,
      defaultAppearance: defaultAppearance ?? this.defaultAppearance,
      alignment: alignment ?? this.alignment,
      widgetObjectNumber: widgetObjectNumber ?? this.widgetObjectNumber,
      selectedValue: selectedValue ?? this.selectedValue,
      defaultValue: defaultValue ?? this.defaultValue,
      options: options ?? this.options,
      displayOptions: displayOptions ?? this.displayOptions,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'fullyQualifiedName': fullyQualifiedName,
        'type': 'dropdown',
        'pageIndex': pageIndex,
        'bounds': [bounds.left, bounds.bottom, bounds.right, bounds.top],
        'flags': flags,
        'selectedValue': selectedValue,
        'defaultValue': defaultValue,
        'options': options,
        if (displayOptions != null) 'displayOptions': displayOptions,
        if (alternateName != null) 'alternateName': alternateName,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfDropdownFormField &&
          other.id == id &&
          other.fullyQualifiedName == fullyQualifiedName &&
          other.selectedValue == selectedValue &&
          other.bounds == bounds;

  @override
  int get hashCode =>
      Object.hash(id, fullyQualifiedName, selectedValue, bounds);
}

/// Represents a List Box Choice field (`/FT /Ch` list).
@immutable
class PdfListBoxFormField extends PdfFormField {
  final List<String> selectedValues;
  final List<String> defaultValues;
  final List<String> options;

  const PdfListBoxFormField({
    required super.id,
    required super.name,
    required super.fullyQualifiedName,
    super.alternateName,
    super.mappingName,
    required super.pageIndex,
    required super.bounds,
    super.flags = 0,
    super.defaultAppearance,
    super.alignment,
    super.widgetObjectNumber,
    this.selectedValues = const [],
    this.defaultValues = const [],
    this.options = const [],
  });

  @override
  PdfFormFieldType get fieldType => PdfFormFieldType.listBox;

  /// Bit 22: Multi-select allowed.
  bool get isMultiSelect => (flags & (1 << 21)) != 0;

  @override
  String get exportValueString => selectedValues.join(', ');

  @override
  bool get hasValue => selectedValues.isNotEmpty;

  @override
  PdfListBoxFormField copyWith({
    List<String>? selectedValues,
    List<String>? defaultValues,
    List<String>? options,
    String? alternateName,
    String? mappingName,
    PdfBoundingBox? bounds,
    int? flags,
    String? defaultAppearance,
    int? alignment,
    int? widgetObjectNumber,
  }) {
    return PdfListBoxFormField(
      id: id,
      name: name,
      fullyQualifiedName: fullyQualifiedName,
      alternateName: alternateName ?? this.alternateName,
      mappingName: mappingName ?? this.mappingName,
      pageIndex: pageIndex,
      bounds: bounds ?? this.bounds,
      flags: flags ?? this.flags,
      defaultAppearance: defaultAppearance ?? this.defaultAppearance,
      alignment: alignment ?? this.alignment,
      widgetObjectNumber: widgetObjectNumber ?? this.widgetObjectNumber,
      selectedValues: selectedValues ?? this.selectedValues,
      defaultValues: defaultValues ?? this.defaultValues,
      options: options ?? this.options,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'fullyQualifiedName': fullyQualifiedName,
        'type': 'listBox',
        'pageIndex': pageIndex,
        'bounds': [bounds.left, bounds.bottom, bounds.right, bounds.top],
        'flags': flags,
        'selectedValues': selectedValues,
        'defaultValues': defaultValues,
        'options': options,
        if (alternateName != null) 'alternateName': alternateName,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfListBoxFormField &&
          other.id == id &&
          other.fullyQualifiedName == fullyQualifiedName &&
          other.bounds == bounds;

  @override
  int get hashCode => Object.hash(id, fullyQualifiedName, bounds);
}

/// Represents a Push Button field (`/FT /Btn` with push-button flag).
@immutable
class PdfPushButtonFormField extends PdfFormField {
  final String label;

  const PdfPushButtonFormField({
    required super.id,
    required super.name,
    required super.fullyQualifiedName,
    super.alternateName,
    super.mappingName,
    required super.pageIndex,
    required super.bounds,
    super.flags = 0,
    super.defaultAppearance,
    super.alignment,
    super.widgetObjectNumber,
    this.label = '',
  });

  @override
  PdfFormFieldType get fieldType => PdfFormFieldType.pushButton;

  @override
  String get exportValueString => '';

  @override
  bool get hasValue => false;

  @override
  PdfPushButtonFormField copyWith({
    String? label,
    String? alternateName,
    String? mappingName,
    PdfBoundingBox? bounds,
    int? flags,
    String? defaultAppearance,
    int? alignment,
    int? widgetObjectNumber,
  }) {
    return PdfPushButtonFormField(
      id: id,
      name: name,
      fullyQualifiedName: fullyQualifiedName,
      alternateName: alternateName ?? this.alternateName,
      mappingName: mappingName ?? this.mappingName,
      pageIndex: pageIndex,
      bounds: bounds ?? this.bounds,
      flags: flags ?? this.flags,
      defaultAppearance: defaultAppearance ?? this.defaultAppearance,
      alignment: alignment ?? this.alignment,
      widgetObjectNumber: widgetObjectNumber ?? this.widgetObjectNumber,
      label: label ?? this.label,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'fullyQualifiedName': fullyQualifiedName,
        'type': 'pushButton',
        'pageIndex': pageIndex,
        'bounds': [bounds.left, bounds.bottom, bounds.right, bounds.top],
        'flags': flags,
        'label': label,
        if (alternateName != null) 'alternateName': alternateName,
      };
}

/// Represents a Digital Signature Form Field (`/FT /Sig`).
@immutable
class PdfSignatureFormField extends PdfFormField {
  final bool isSigned;
  final String? signerName;
  final DateTime? signDate;

  const PdfSignatureFormField({
    required super.id,
    required super.name,
    required super.fullyQualifiedName,
    super.alternateName,
    super.mappingName,
    required super.pageIndex,
    required super.bounds,
    super.flags = 0,
    super.defaultAppearance,
    super.alignment,
    super.widgetObjectNumber,
    this.isSigned = false,
    this.signerName,
    this.signDate,
  });

  @override
  PdfFormFieldType get fieldType => PdfFormFieldType.signature;

  @override
  String get exportValueString => isSigned ? (signerName ?? 'Signed') : '';

  @override
  bool get hasValue => isSigned;

  @override
  PdfSignatureFormField copyWith({
    bool? isSigned,
    String? signerName,
    DateTime? signDate,
    String? alternateName,
    String? mappingName,
    PdfBoundingBox? bounds,
    int? flags,
    String? defaultAppearance,
    int? alignment,
    int? widgetObjectNumber,
  }) {
    return PdfSignatureFormField(
      id: id,
      name: name,
      fullyQualifiedName: fullyQualifiedName,
      alternateName: alternateName ?? this.alternateName,
      mappingName: mappingName ?? this.mappingName,
      pageIndex: pageIndex,
      bounds: bounds ?? this.bounds,
      flags: flags ?? this.flags,
      defaultAppearance: defaultAppearance ?? this.defaultAppearance,
      alignment: alignment ?? this.alignment,
      widgetObjectNumber: widgetObjectNumber ?? this.widgetObjectNumber,
      isSigned: isSigned ?? this.isSigned,
      signerName: signerName ?? this.signerName,
      signDate: signDate ?? this.signDate,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'fullyQualifiedName': fullyQualifiedName,
        'type': 'signature',
        'pageIndex': pageIndex,
        'bounds': [bounds.left, bounds.bottom, bounds.right, bounds.top],
        'flags': flags,
        'isSigned': isSigned,
        if (signerName != null) 'signerName': signerName,
        if (signDate != null) 'signDate': signDate!.toIso8601String(),
        if (alternateName != null) 'alternateName': alternateName,
      };
}

/// Document-level AcroForm container model.
@immutable
class PdfFormDocument {
  final bool hasAcroForm;
  final bool needAppearances;
  final int sigFlags;
  final List<PdfFormField> fields;

  const PdfFormDocument({
    this.hasAcroForm = false,
    this.needAppearances = false,
    this.sigFlags = 0,
    this.fields = const [],
  });

  const PdfFormDocument.empty()
      : hasAcroForm = false,
        needAppearances = false,
        sigFlags = 0,
        fields = const [];

  int get fieldCount => fields.length;

  /// Returns all fields located on the given 0-based [pageIndex].
  List<PdfFormField> fieldsOnPage(int pageIndex) =>
      fields.where((f) => f.pageIndex == pageIndex).toList(growable: false);

  /// Finds a field by its [id] or [fullyQualifiedName].
  PdfFormField? findField(String identifier) {
    for (final field in fields) {
      if (field.id == identifier || field.fullyQualifiedName == identifier) {
        return field;
      }
    }
    return null;
  }

  /// Returns a map of field full qualified name to its export string value.
  Map<String, String> exportValues() {
    final map = <String, String>{};
    for (final field in fields) {
      if (!field.isNoExport && field.fullyQualifiedName.isNotEmpty) {
        map[field.fullyQualifiedName] = field.exportValueString;
      }
    }
    return map;
  }

  PdfFormDocument copyWith({
    bool? hasAcroForm,
    bool? needAppearances,
    int? sigFlags,
    List<PdfFormField>? fields,
  }) {
    return PdfFormDocument(
      hasAcroForm: hasAcroForm ?? this.hasAcroForm,
      needAppearances: needAppearances ?? this.needAppearances,
      sigFlags: sigFlags ?? this.sigFlags,
      fields: fields ?? this.fields,
    );
  }

  Map<String, dynamic> toJson() => {
        'hasAcroForm': hasAcroForm,
        'needAppearances': needAppearances,
        'sigFlags': sigFlags,
        'fields': fields.map((f) => f.toJson()).toList(),
      };
}

/// Validation result for a single field.
@immutable
class PdfFormFieldValidationError {
  final String fieldId;
  final String fullyQualifiedName;
  final String message;

  const PdfFormFieldValidationError({
    required this.fieldId,
    required this.fullyQualifiedName,
    required this.message,
  });

  @override
  String toString() => '$fullyQualifiedName: $message';
}

/// Form-wide validation result.
@immutable
class PdfFormValidationResult {
  final bool isValid;
  final List<PdfFormFieldValidationError> errors;

  const PdfFormValidationResult({
    required this.isValid,
    this.errors = const [],
  });

  const PdfFormValidationResult.valid()
      : isValid = true,
        errors = const [];

  factory PdfFormValidationResult.fromErrors(
      List<PdfFormFieldValidationError> errors) {
    return PdfFormValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
}
