import 'package:flutter/material.dart';
import '../../domain/entities/pdf_form_field.dart';

/// Overlay widget that renders native interactive Flutter controls over
/// AcroForm field rectangles for a specific PDF page.
class PdfFormOverlayLayer extends StatelessWidget {
  final int pageIndex;
  final Size pageSize; // PDF User units (e.g. 612 x 792)
  final Size viewportSize; // Rendered screen pixel size
  final List<PdfFormField> fields;
  final void Function(PdfFormField field, dynamic newValue)? onFieldValueChanged;
  final bool readOnly;

  const PdfFormOverlayLayer({
    super.key,
    required this.pageIndex,
    required this.pageSize,
    required this.viewportSize,
    required this.fields,
    this.onFieldValueChanged,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final pageFields =
        fields.where((f) => f.pageIndex == pageIndex).toList(growable: false);
    if (pageFields.isEmpty || pageSize.width <= 0 || pageSize.height <= 0) {
      return const SizedBox.shrink();
    }

    final scaleX = viewportSize.width / pageSize.width;
    final scaleY = viewportSize.height / pageSize.height;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (final field in pageFields)
          _buildPositionedField(context, field, scaleX, scaleY),
      ],
    );
  }

  Widget _buildPositionedField(
    BuildContext context,
    PdfFormField field,
    double scaleX,
    double scaleY,
  ) {
    final b = field.bounds.normalized();
    final leftPx = b.left * scaleX;
    final topPx = (pageSize.height - b.top) * scaleY;
    final widthPx = b.width * scaleX;
    final heightPx = b.height * scaleY;

    final isFieldReadOnly = readOnly || field.isReadOnly;

    Widget childWidget;
    if (field is PdfTextFormField) {
      childWidget = _PdfTextWidget(
        field: field,
        isReadOnly: isFieldReadOnly,
        onChanged: (val) => onFieldValueChanged?.call(field, val),
      );
    } else if (field is PdfCheckboxFormField) {
      childWidget = _PdfCheckboxWidget(
        field: field,
        isReadOnly: isFieldReadOnly,
        onChanged: (val) => onFieldValueChanged?.call(field, val),
      );
    } else if (field is PdfRadioButtonFormField) {
      childWidget = _PdfRadioWidget(
        field: field,
        isReadOnly: isFieldReadOnly,
        onChanged: (val) => onFieldValueChanged?.call(field, val),
      );
    } else if (field is PdfDropdownFormField) {
      childWidget = _PdfDropdownWidget(
        field: field,
        isReadOnly: isFieldReadOnly,
        onChanged: (val) => onFieldValueChanged?.call(field, val),
      );
    } else if (field is PdfListBoxFormField) {
      childWidget = _PdfListBoxWidget(
        field: field,
        isReadOnly: isFieldReadOnly,
        onChanged: (val) => onFieldValueChanged?.call(field, val),
      );
    } else {
      childWidget = Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue.withValues(alpha: 0.5)),
          color: Colors.blue.withValues(alpha: 0.1),
        ),
      );
    }

    return Positioned(
      left: leftPx,
      top: topPx,
      width: widthPx.clamp(12.0, double.infinity),
      height: heightPx.clamp(12.0, double.infinity),
      child: Tooltip(
        message: field.alternateName ?? field.fullyQualifiedName,
        child: childWidget,
      ),
    );
  }
}

class _PdfTextWidget extends StatefulWidget {
  final PdfTextFormField field;
  final bool isReadOnly;
  final ValueChanged<String> onChanged;

  const _PdfTextWidget({
    required this.field,
    required this.isReadOnly,
    required this.onChanged,
  });

  @override
  State<_PdfTextWidget> createState() => _PdfTextWidgetState();
}

class _PdfTextWidgetState extends State<_PdfTextWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.field.text);
  }

  @override
  void didUpdateWidget(covariant _PdfTextWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.field.text != widget.field.text &&
        _controller.text != widget.field.text) {
      _controller.text = widget.field.text;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isReadOnly
            ? Colors.grey.withValues(alpha: 0.1)
            : Colors.blue.withValues(alpha: 0.08),
        border: Border.all(
          color: widget.field.isRequired
              ? Colors.orange.withValues(alpha: 0.8)
              : Colors.blue.withValues(alpha: 0.4),
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(2.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: TextField(
        controller: _controller,
        readOnly: widget.isReadOnly,
        obscureText: widget.field.isPassword,
        maxLines: widget.field.isMultiline ? null : 1,
        maxLength: widget.field.maxLength,
        style: const TextStyle(fontSize: 12.0, color: Colors.black87),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 2.0),
          border: InputBorder.none,
          counterText: '',
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}

class _PdfCheckboxWidget extends StatelessWidget {
  final PdfCheckboxFormField field;
  final bool isReadOnly;
  final ValueChanged<bool> onChanged;

  const _PdfCheckboxWidget({
    required this.field,
    required this.isReadOnly,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isReadOnly ? null : () => onChanged(!field.isChecked),
      child: Container(
        decoration: BoxDecoration(
          color: isReadOnly
              ? Colors.grey.withValues(alpha: 0.1)
              : Colors.blue.withValues(alpha: 0.08),
          border: Border.all(
            color: Colors.blue.withValues(alpha: 0.5),
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(2.0),
        ),
        child: Center(
          child: field.isChecked
              ? const Icon(Icons.check, size: 16.0, color: Colors.blueAccent)
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _PdfRadioWidget extends StatelessWidget {
  final PdfRadioButtonFormField field;
  final bool isReadOnly;
  final ValueChanged<String> onChanged;

  const _PdfRadioWidget({
    required this.field,
    required this.isReadOnly,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isReadOnly ? null : () => onChanged(field.buttonValue),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isReadOnly
              ? Colors.grey.withValues(alpha: 0.1)
              : Colors.blue.withValues(alpha: 0.08),
          border: Border.all(
            color: Colors.blue.withValues(alpha: 0.6),
            width: 1.0,
          ),
        ),
        child: Center(
          child: field.isSelected
              ? Container(
                  width: 8.0,
                  height: 8.0,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blueAccent,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _PdfDropdownWidget extends StatelessWidget {
  final PdfDropdownFormField field;
  final bool isReadOnly;
  final ValueChanged<String> onChanged;

  const _PdfDropdownWidget({
    required this.field,
    required this.isReadOnly,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveValue = field.options.contains(field.selectedValue)
        ? field.selectedValue
        : (field.options.isNotEmpty ? field.options.first : null);

    return Container(
      decoration: BoxDecoration(
        color: isReadOnly
            ? Colors.grey.withValues(alpha: 0.1)
            : Colors.blue.withValues(alpha: 0.08),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.5),
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(2.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: effectiveValue,
          isDense: true,
          isExpanded: true,
          style: const TextStyle(fontSize: 12.0, color: Colors.black87),
          items: field.options.map((opt) {
            return DropdownMenuItem<String>(
              value: opt,
              child: Text(opt, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: isReadOnly ? null : (val) => val != null ? onChanged(val) : null,
        ),
      ),
    );
  }
}

class _PdfListBoxWidget extends StatelessWidget {
  final PdfListBoxFormField field;
  final bool isReadOnly;
  final ValueChanged<List<String>> onChanged;

  const _PdfListBoxWidget({
    required this.field,
    required this.isReadOnly,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isReadOnly
            ? Colors.grey.withValues(alpha: 0.1)
            : Colors.blue.withValues(alpha: 0.08),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.5),
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(2.0),
      ),
      child: ListView.builder(
        itemCount: field.options.length,
        itemBuilder: (ctx, i) {
          final opt = field.options[i];
          final isSelected = field.selectedValues.contains(opt);
          return InkWell(
            onTap: isReadOnly
                ? null
                : () {
                    if (field.isMultiSelect) {
                      final updated = List<String>.from(field.selectedValues);
                      if (isSelected) {
                        updated.remove(opt);
                      } else {
                        updated.add(opt);
                      }
                      onChanged(updated);
                    } else {
                      onChanged([opt]);
                    }
                  },
            child: Container(
              color: isSelected ? Colors.blue.withValues(alpha: 0.25) : null,
              padding:
                  const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
              child: Text(
                opt,
                style: TextStyle(
                  fontSize: 11.0,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
