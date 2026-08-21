import 'package:flutter/material.dart';

import '../../domain/entities/normalized_page_rect.dart';
import '../../domain/entities/pdf_visual_signature.dart';
import '../../services/signature_service.dart';

/// Interactive Canvas-based signature drawing pad with smooth strokes, undo, and clear.
class SignatureDrawingPad extends StatefulWidget {
  final ValueChanged<List<List<PdfSignaturePoint>>> onStrokesChanged;
  final int colorArgb;
  final double strokeWidth;

  const SignatureDrawingPad({
    super.key,
    required this.onStrokesChanged,
    this.colorArgb = 0xFF000000,
    this.strokeWidth = 2.5,
  });

  @override
  State<SignatureDrawingPad> createState() => SignatureDrawingPadState();
}

class SignatureDrawingPadState extends State<SignatureDrawingPad> {
  final List<List<Offset>> _strokes = [];
  List<Offset>? _currentStroke;

  void undo() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _strokes.removeLast();
      });
      _notify();
    }
  }

  void clear() {
    setState(() {
      _strokes.clear();
      _currentStroke = null;
    });
    _notify();
  }

  void _notify() {
    widget.onStrokesChanged(getNormalizedStrokes());
  }

  List<List<PdfSignaturePoint>> getNormalizedStrokes() {
    final renderBox = context.findRenderObject() as RenderBox?;
    final size =
        renderBox?.hasSize == true ? renderBox!.size : const Size(300, 150);
    final w = size.width > 0 ? size.width : 300.0;
    final h = size.height > 0 ? size.height : 150.0;

    return _strokes.map((stroke) {
      return stroke.map((p) {
        return PdfSignaturePoint(
          (p.dx / w).clamp(0.0, 1.0),
          (p.dy / h).clamp(0.0, 1.0),
        );
      }).toList();
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GestureDetector(
          onPanStart: (details) {
            final local = details.localPosition;
            setState(() {
              _currentStroke = [local];
              _strokes.add(_currentStroke!);
            });
            _notify();
          },
          onPanUpdate: (details) {
            final local = details.localPosition;
            setState(() {
              _currentStroke?.add(local);
            });
            _notify();
          },
          onPanEnd: (_) {
            _currentStroke = null;
            _notify();
          },
          child: CustomPaint(
            painter: _SignatureStrokesPainter(
              strokes: _strokes,
              color: Color(widget.colorArgb),
              strokeWidth: widget.strokeWidth,
            ),
            child: _strokes.isEmpty
                ? Center(
                    child: Text(
                      'Sign here with finger or mouse',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _SignatureStrokesPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final Color color;
  final double strokeWidth;

  _SignatureStrokesPainter({
    required this.strokes,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {
        canvas.drawCircle(
            stroke.first, strokeWidth / 2, paint..style = PaintingStyle.fill);
        paint.style = PaintingStyle.stroke;
        continue;
      }
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (var i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignatureStrokesPainter oldDelegate) => true;
}

/// Dialog allowing user to create a new visual signature via Draw, Type, or Image.
class SignatureCreationDialog extends StatefulWidget {
  final String? initialName;
  final void Function(PdfVisualSignature signature)? onSave;

  const SignatureCreationDialog({
    super.key,
    this.initialName,
    this.onSave,
  });

  @override
  State<SignatureCreationDialog> createState() =>
      _SignatureCreationDialogState();
}

class _SignatureCreationDialogState extends State<SignatureCreationDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _nameController;
  late TextEditingController _typedController;
  late TextEditingController _imageController;

  final GlobalKey<SignatureDrawingPadState> _padKey = GlobalKey();
  List<List<PdfSignaturePoint>> _drawnStrokes = [];
  int _colorArgb = 0xFF000000;
  final String _selectedFontStyle = 'cursive';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _nameController =
        TextEditingController(text: widget.initialName ?? 'Signature 1');
    _typedController = TextEditingController(text: 'John Doe');
    _imageController = TextEditingController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _typedController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  PdfVisualSignature? _buildSignature() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return null;
    final now = DateTime.now();
    final id = 'sig_${now.microsecondsSinceEpoch}';

    switch (_tabController.index) {
      case 0:
        if (_drawnStrokes.isEmpty || !_drawnStrokes.any((s) => s.isNotEmpty)) {
          return null;
        }
        return PdfVisualSignature.drawn(
          id: id,
          name: name,
          strokes: _drawnStrokes,
          colorArgb: _colorArgb,
          createdAt: now,
          updatedAt: now,
        );
      case 1:
        if (_typedController.text.trim().isEmpty) return null;
        return PdfVisualSignature.typed(
          id: id,
          name: name,
          text: _typedController.text.trim(),
          fontStyle: _selectedFontStyle,
          colorArgb: _colorArgb,
          createdAt: now,
          updatedAt: now,
        );
      case 2:
        if (_imageController.text.trim().isEmpty) return null;
        return PdfVisualSignature.image(
          id: id,
          name: name,
          imageBase64: _imageController.text.trim(),
          createdAt: now,
          updatedAt: now,
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Create Signature',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('signature-name-input'),
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Signature Label',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.draw), text: 'Draw'),
                  Tab(icon: Icon(Icons.text_fields), text: 'Type'),
                  Tab(icon: Icon(Icons.image), text: 'Upload'),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // DRAW TAB
                    Column(
                      children: [
                        Expanded(
                          child: SignatureDrawingPad(
                            key: _padKey,
                            colorArgb: _colorArgb,
                            onStrokesChanged: (strokes) {
                              setState(() => _drawnStrokes = strokes);
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                _ColorChoice(
                                  color: const Color(0xFF000000),
                                  isSelected: _colorArgb == 0xFF000000,
                                  onTap: () =>
                                      setState(() => _colorArgb = 0xFF000000),
                                ),
                                const SizedBox(width: 8),
                                _ColorChoice(
                                  color: const Color(0xFF002266),
                                  isSelected: _colorArgb == 0xFF002266,
                                  onTap: () =>
                                      setState(() => _colorArgb = 0xFF002266),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                TextButton.icon(
                                  key: const Key('signature-undo-button'),
                                  icon: const Icon(Icons.undo, size: 18),
                                  label: const Text('Undo'),
                                  onPressed: () => _padKey.currentState?.undo(),
                                ),
                                TextButton.icon(
                                  key: const Key('signature-clear-button'),
                                  icon: const Icon(Icons.clear, size: 18),
                                  label: const Text('Clear'),
                                  onPressed: () =>
                                      _padKey.currentState?.clear(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    // TYPE TAB
                    Column(
                      children: [
                        TextField(
                          key: const Key('signature-typed-input'),
                          controller: _typedController,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Enter Full Name',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: theme.colorScheme.outlineVariant),
                            ),
                            child: Center(
                              child: Text(
                                _typedController.text.isEmpty
                                    ? 'Preview'
                                    : _typedController.text,
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 32,
                                  color: Color(_colorArgb),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // UPLOAD TAB
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          key: const Key('signature-image-input'),
                          controller: _imageController,
                          decoration: const InputDecoration(
                            labelText: 'Paste Image Base64 Data',
                            border: OutlineInputBorder(),
                            helperText:
                                'PNG or JPG signature with transparent background',
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    key: const Key('save-signature-button'),
                    icon: const Icon(Icons.check),
                    label: const Text('Save Signature'),
                    onPressed: () {
                      final sig = _buildSignature();
                      if (sig != null) {
                        widget.onSave?.call(sig);
                        Navigator.of(context).pop(sig);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Please provide signature content')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorChoice extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorChoice({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.amber : Colors.transparent,
            width: 2.5,
          ),
        ),
      ),
    );
  }
}

/// Dialog displaying the library of saved visual signatures and allowing selection or creation.
class SignatureLibraryDialog extends StatefulWidget {
  final SignatureService service;
  final ValueChanged<PdfVisualSignature>? onSignatureSelected;

  const SignatureLibraryDialog({
    super.key,
    required this.service,
    this.onSignatureSelected,
  });

  @override
  State<SignatureLibraryDialog> createState() => _SignatureLibraryDialogState();
}

class _SignatureLibraryDialogState extends State<SignatureLibraryDialog> {
  List<PdfVisualSignature> _signatures = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await widget.service.ensureLoaded();
    if (!mounted) return;
    setState(() {
      _signatures = List.from(list);
      _loading = false;
    });
  }

  Future<void> _delete(String id) async {
    await widget.service.deleteSignature(id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 520),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Signature Library',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _signatures.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.history_edu,
                                    size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                const Text('No signatures saved yet'),
                                const SizedBox(height: 8),
                                const Text(
                                  'Create a reusable signature to stamp on PDF pages',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: _signatures.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final sig = _signatures[index];
                              return ListTile(
                                key: Key('signature-item-${sig.id}'),
                                leading: Icon(
                                  sig.type == PdfSignatureType.drawn
                                      ? Icons.draw
                                      : sig.type == PdfSignatureType.typed
                                          ? Icons.text_fields
                                          : Icons.image,
                                  color: theme.colorScheme.primary,
                                ),
                                title: Text(sig.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                  sig.type == PdfSignatureType.typed
                                      ? 'Typed: "${sig.typedText}"'
                                      : 'Created on ${sig.createdAt.toLocal().toString().split('.').first}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.red),
                                      tooltip: 'Delete signature',
                                      onPressed: () => _delete(sig.id),
                                    ),
                                    FilledButton.tonal(
                                      child: const Text('Place'),
                                      onPressed: () {
                                        widget.onSignatureSelected?.call(sig);
                                        Navigator.of(context).pop(sig);
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const Key('create-new-signature-button'),
                icon: const Icon(Icons.add),
                label: const Text('Create New Signature'),
                onPressed: () async {
                  final newSig = await showDialog<PdfVisualSignature>(
                    context: context,
                    builder: (context) => SignatureCreationDialog(
                      onSave: (s) async {
                        await widget.service.saveSignature(s);
                      },
                    ),
                  );
                  if (newSig != null) {
                    await _load();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Interactive draggable & resizable signature stamp placement overlay over the PDF viewport.
class SignaturePlacementOverlay extends StatefulWidget {
  final PdfVisualSignature signature;
  final ValueChanged<NormalizedPageRect> onConfirm;
  final VoidCallback onCancel;

  const SignaturePlacementOverlay({
    super.key,
    required this.signature,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<SignaturePlacementOverlay> createState() =>
      _SignaturePlacementOverlayState();
}

class _SignaturePlacementOverlayState extends State<SignaturePlacementOverlay> {
  // Normalized coordinates in the viewport (0.0 to 1.0)
  double _left = 0.3;
  double _top = 0.4;
  double _width = 0.35;
  double _height = 0.15;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenW = constraints.maxWidth;
        final screenH = constraints.maxHeight;

        final pixelLeft = _left * screenW;
        final pixelTop = _top * screenH;
        final pixelWidth = (_width * screenW).clamp(80.0, screenW);
        final pixelHeight = (_height * screenH).clamp(40.0, screenH);

        return Stack(
          children: [
            // Darkened scrim background
            Positioned.fill(
              child: GestureDetector(
                onTap: widget.onCancel,
                child: Container(color: Colors.black.withValues(alpha: 0.15)),
              ),
            ),
            // Draggable & resizable signature box
            Positioned(
              left: pixelLeft,
              top: pixelTop,
              width: pixelWidth,
              height: pixelHeight,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _left = (_left + details.delta.dx / screenW)
                        .clamp(0.0, 1.0 - _width);
                    _top = (_top + details.delta.dy / screenH)
                        .clamp(0.0, 1.0 - _height);
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    border:
                        Border.all(color: theme.colorScheme.primary, width: 2),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Signature visual preview
                      Center(
                        child: widget.signature.type == PdfSignatureType.drawn
                            ? CustomPaint(
                                size: Size(pixelWidth, pixelHeight),
                                painter: _NormalizedSignaturePainter(
                                  strokes: widget.signature.strokes,
                                  color: Color(widget.signature.colorArgb),
                                ),
                              )
                            : widget.signature.type == PdfSignatureType.typed
                                ? Text(
                                    widget.signature.typedText,
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22,
                                      color: Color(widget.signature.colorArgb),
                                    ),
                                  )
                                : const Icon(Icons.image, size: 36),
                      ),
                      // Resize handle in bottom right
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            setState(() {
                              _width = (_width + details.delta.dx / screenW)
                                  .clamp(0.1, 0.9);
                              _height = (_height + details.delta.dy / screenH)
                                  .clamp(0.05, 0.5);
                            });
                          },
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: const BorderRadius.only(
                                bottomRight: Radius.circular(6),
                              ),
                            ),
                            child: const Icon(Icons.aspect_ratio,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Floating bottom confirmation control bar
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Place "${widget.signature.name}"',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 16),
                      TextButton(
                        onPressed: widget.onCancel,
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        key: const Key('confirm-signature-placement-button'),
                        icon: const Icon(Icons.check),
                        label: const Text('Apply Stamp'),
                        onPressed: () {
                          final rect = NormalizedPageRect(
                            left: _left,
                            top: _top,
                            right: _left + _width,
                            bottom: _top + _height,
                          );
                          widget.onConfirm(rect);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NormalizedSignaturePainter extends CustomPainter {
  final List<List<PdfSignaturePoint>> strokes;
  final Color color;

  _NormalizedSignaturePainter({
    required this.strokes,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      final path = Path()
        ..moveTo(stroke.first.x * size.width, stroke.first.y * size.height);
      for (var i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].x * size.width, stroke[i].y * size.height);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _NormalizedSignaturePainter oldDelegate) => true;
}
