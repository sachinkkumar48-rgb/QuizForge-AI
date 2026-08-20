import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../../domain/entities/pdf_native_annotation.dart';
import '../../domain/pdf_manipulation_errors.dart';
import '../ast/pdf_annotation_builder.dart';
import '../ast/pdf_annotation_parser.dart';
import '../ast/pdf_document_ast.dart';
import '../ast/pdf_parser.dart';
import '../ast/pdf_primitive.dart';
import '../ast/pdf_writer.dart';
import 'pdf_native_annotation_engine.dart';

/// Pure Dart implementation of [PdfNativeAnnotationEngine] using [PdfDocumentAst].
class DefaultPdfNativeAnnotationEngine implements PdfNativeAnnotationEngine {
  const DefaultPdfNativeAnnotationEngine();

  List<PdfNativeAnnotation> loadAnnotationsSync(
    String pdfPath, {
    int? pageIndex,
  }) {
    final file = File(pdfPath);
    if (!file.existsSync()) {
      throw PdfInvalidDocumentException('File does not exist: $pdfPath',
          filePath: pdfPath);
    }

    final bytes = file.readAsBytesSync();
    final ast = PdfParser(bytes).parse();

    if (pageIndex != null) {
      return PdfAnnotationParser.parsePageAnnotations(ast, pageIndex);
    }

    final all = <PdfNativeAnnotation>[];
    for (var i = 0; i < ast.pageCount; i++) {
      all.addAll(PdfAnnotationParser.parsePageAnnotations(ast, i));
    }
    return all;
  }

  @override
  Future<List<PdfNativeAnnotation>> loadAnnotations(
    String pdfPath, {
    int? pageIndex,
  }) async {
    return loadAnnotationsSync(pdfPath, pageIndex: pageIndex);
  }

  void addAnnotationSync(
    String sourcePath,
    PdfNativeAnnotation annotation, {
    String? outputPath,
  }) {
    final existing = loadAnnotationsSync(sourcePath);
    final updated = List<PdfNativeAnnotation>.from(existing)..add(annotation);
    saveAllAnnotationsSync(sourcePath, updated, outputPath: outputPath);
  }

  @override
  Future<void> addAnnotation(
    String sourcePath,
    PdfNativeAnnotation annotation, {
    String? outputPath,
  }) async {
    addAnnotationSync(sourcePath, annotation, outputPath: outputPath);
  }

  void updateAnnotationSync(
    String sourcePath,
    PdfNativeAnnotation annotation, {
    String? outputPath,
  }) {
    final existing = loadAnnotationsSync(sourcePath);
    final updated =
        existing.map((a) => a.id == annotation.id ? annotation : a).toList();
    saveAllAnnotationsSync(sourcePath, updated, outputPath: outputPath);
  }

  @override
  Future<void> updateAnnotation(
    String sourcePath,
    PdfNativeAnnotation annotation, {
    String? outputPath,
  }) async {
    updateAnnotationSync(sourcePath, annotation, outputPath: outputPath);
  }

  void deleteAnnotationSync(
    String sourcePath,
    String annotationId, {
    String? outputPath,
  }) {
    final existing = loadAnnotationsSync(sourcePath);
    final updated = existing.where((a) => a.id != annotationId).toList();
    saveAllAnnotationsSync(sourcePath, updated, outputPath: outputPath);
  }

  @override
  Future<void> deleteAnnotation(
    String sourcePath,
    String annotationId, {
    String? outputPath,
  }) async {
    deleteAnnotationSync(sourcePath, annotationId, outputPath: outputPath);
  }

  void saveAllAnnotationsSync(
    String sourcePath,
    List<PdfNativeAnnotation> annotations, {
    String? outputPath,
  }) {
    final file = File(sourcePath);
    if (!file.existsSync()) {
      throw PdfInvalidDocumentException('File does not exist: $sourcePath',
          filePath: sourcePath);
    }

    final bytes = file.readAsBytesSync();
    final ast = PdfParser(bytes).parse();
    final targetPath = outputPath ?? sourcePath;

    // Group annotations by pageIndex
    final annotationsByPage = <int, List<PdfNativeAnnotation>>{};
    for (final annot in annotations) {
      annotationsByPage.putIfAbsent(annot.pageIndex, () => []).add(annot);
    }

    for (var pageIdx = 0; pageIdx < ast.pageCount; pageIdx++) {
      final pageDict = ast.getPageDict(pageIdx);
      final pageRef = ast.pageRefs[pageIdx];
      final pageAnnots = annotationsByPage[pageIdx] ?? const [];

      if (pageAnnots.isEmpty) {
        pageDict.remove('Annots');
        continue;
      }

      final newAnnotsArray = PdfArray();

      for (final annot in pageAnnots) {
        // 1. Allocate ExtGState object for opacity / blend mode
        final gsObjNum = ast.nextAvailableObjectNumber();
        final gsDict = PdfAnnotationBuilder.buildExtGStateDict(annot.opacity);
        ast.objects[gsObjNum] = gsDict;
        ast.objectGenerations[gsObjNum] = 0;

        // 2. Allocate Form XObject Appearance Stream object
        final apObjNum = ast.nextAvailableObjectNumber();
        final apStream =
            PdfAnnotationBuilder.buildAppearanceStream(annot, gsObjNum);
        ast.objects[apObjNum] = apStream;
        ast.objectGenerations[apObjNum] = 0;

        // 3. Allocate Annotation Dictionary object
        final annotObjNum = ast.nextAvailableObjectNumber();
        final annotDict = PdfAnnotationBuilder.buildAnnotationDict(
          annot,
          pageRef: pageRef,
          appearanceStreamRef: PdfRef(apObjNum),
        );
        ast.objects[annotObjNum] = annotDict;
        ast.objectGenerations[annotObjNum] = 0;

        newAnnotsArray.add(PdfRef(annotObjNum));
      }

      pageDict['Annots'] = newAnnotsArray;
    }

    final writer = PdfWriter(ast);
    writer.writeAtomicSync(targetPath);
  }

  @override
  Future<void> saveAllAnnotations(
    String sourcePath,
    List<PdfNativeAnnotation> annotations, {
    String? outputPath,
  }) async {
    saveAllAnnotationsSync(sourcePath, annotations, outputPath: outputPath);
  }

  @override
  Future<void> exportWithNativeAnnotations(
    String sourcePath,
    List<PdfNativeAnnotation> annotations,
    String outputPath,
  ) async {
    saveAllAnnotationsSync(sourcePath, annotations, outputPath: outputPath);
  }

  @override
  Future<void> flattenAnnotations(
    String sourcePath, {
    List<String>? annotationIds,
    String? outputPath,
  }) async {
    final file = File(sourcePath);
    if (!await file.exists()) {
      throw PdfInvalidDocumentException('File does not exist: $sourcePath',
          filePath: sourcePath);
    }

    final bytes = await file.readAsBytes();
    final ast = PdfParser(bytes).parse();
    final targetPath = outputPath ?? sourcePath;

    final targetIdSet = annotationIds?.toSet();

    for (var pageIdx = 0; pageIdx < ast.pageCount; pageIdx++) {
      final pageDict = ast.getPageDict(pageIdx);
      final annots = PdfAnnotationParser.parsePageAnnotations(ast, pageIdx);
      if (annots.isEmpty) continue;

      final remainingAnnots = <PdfNativeAnnotation>[];
      final flattenedOps = StringBuffer();

      for (final annot in annots) {
        if (targetIdSet != null && !targetIdSet.contains(annot.id)) {
          remainingAnnots.add(annot);
          continue;
        }

        // Flatten graphics into page content
        final box = annot.boundingBox.normalized();
        final width = box.width > 0 ? box.width : 1.0;
        final height = box.height > 0 ? box.height : 1.0;
        final r = annot.color.r.toStringAsFixed(3);
        final g = annot.color.g.toStringAsFixed(3);
        final b = annot.color.b.toStringAsFixed(3);

        flattenedOps.writeln('q');
        if (annot is PdfNativeHighlightAnnotation) {
          flattenedOps.writeln('$r $g $b rg');
          flattenedOps.writeln(
              '${box.left.toStringAsFixed(2)} ${box.bottom.toStringAsFixed(2)} ${width.toStringAsFixed(2)} ${height.toStringAsFixed(2)} re f');
        } else if (annot is PdfNativeUnderlineAnnotation) {
          final y = box.bottom + (height * 0.15);
          flattenedOps.writeln('$r $g $b RG 1.5 w');
          flattenedOps.writeln(
              '${box.left.toStringAsFixed(2)} ${y.toStringAsFixed(2)} m ${box.right.toStringAsFixed(2)} ${y.toStringAsFixed(2)} l S');
        } else if (annot is PdfNativeStrikeOutAnnotation) {
          final y = box.bottom + (height * 0.5);
          flattenedOps.writeln('$r $g $b RG 1.5 w');
          flattenedOps.writeln(
              '${box.left.toStringAsFixed(2)} ${y.toStringAsFixed(2)} m ${box.right.toStringAsFixed(2)} ${y.toStringAsFixed(2)} l S');
        } else if (annot is PdfNativeInkAnnotation) {
          flattenedOps.writeln(
              '$r $g $b RG ${annot.strokeWidth.toStringAsFixed(1)} w 1 J 1 j');
          for (final stroke in annot.inkList) {
            if (stroke.isEmpty) continue;
            flattenedOps.writeln(
                '${stroke.first.x.toStringAsFixed(2)} ${stroke.first.y.toStringAsFixed(2)} m');
            for (var i = 1; i < stroke.length; i++) {
              flattenedOps.writeln(
                  '${stroke[i].x.toStringAsFixed(2)} ${stroke[i].y.toStringAsFixed(2)} l');
            }
            flattenedOps.writeln('S');
          }
        } else {
          // Unsupported for flattening -> preserve as live annotation
          remainingAnnots.add(annot);
        }
        flattenedOps.writeln('Q');
      }

      if (flattenedOps.isNotEmpty) {
        _appendGraphicsToPageContents(ast, pageDict, flattenedOps.toString());
      }

      // Update remaining live annotations
      if (remainingAnnots.isEmpty) {
        pageDict.remove('Annots');
      } else {
        final annotsArray = PdfArray();
        for (final rem in remainingAnnots) {
          final gsObjNum = ast.nextAvailableObjectNumber();
          ast.objects[gsObjNum] =
              PdfAnnotationBuilder.buildExtGStateDict(rem.opacity);
          ast.objectGenerations[gsObjNum] = 0;

          final apObjNum = ast.nextAvailableObjectNumber();
          ast.objects[apObjNum] =
              PdfAnnotationBuilder.buildAppearanceStream(rem, gsObjNum);
          ast.objectGenerations[apObjNum] = 0;

          final annotObjNum = ast.nextAvailableObjectNumber();
          ast.objects[annotObjNum] = PdfAnnotationBuilder.buildAnnotationDict(
            rem,
            pageRef: ast.pageRefs[pageIdx],
            appearanceStreamRef: PdfRef(apObjNum),
          );
          ast.objectGenerations[annotObjNum] = 0;

          annotsArray.add(PdfRef(annotObjNum));
        }
        pageDict['Annots'] = annotsArray;
      }
    }

    final writer = PdfWriter(ast);
    await writer.writeAtomic(targetPath);
  }

  void _appendGraphicsToPageContents(
    PdfDocumentAst ast,
    PdfDict pageDict,
    String graphicsOps,
  ) {
    final contentsRef = pageDict['Contents'];
    final newBytes = utf8.encode('\n$graphicsOps\n');

    if (contentsRef is PdfRef) {
      final oldStream = ast.objects[contentsRef.objectNumber];
      if (oldStream is PdfStream) {
        final combined = Uint8List(oldStream.data.length + newBytes.length);
        combined.setRange(0, oldStream.data.length, oldStream.data);
        combined.setRange(oldStream.data.length, combined.length, newBytes);
        ast.objects[contentsRef.objectNumber] =
            PdfStream(dict: oldStream.dict, data: combined);
        return;
      }
    }

    // Create a new contents stream if none exists or if array
    final newStreamNum = ast.nextAvailableObjectNumber();
    final newStream = PdfStream(
      dict: PdfDict({'Length': PdfNumber(newBytes.length)}),
      data: Uint8List.fromList(newBytes),
    );
    ast.objects[newStreamNum] = newStream;
    ast.objectGenerations[newStreamNum] = 0;

    if (contentsRef is PdfArray) {
      contentsRef.add(PdfRef(newStreamNum));
    } else if (contentsRef is PdfRef) {
      pageDict['Contents'] = PdfArray([contentsRef, PdfRef(newStreamNum)]);
    } else {
      pageDict['Contents'] = PdfRef(newStreamNum);
    }
  }
}
