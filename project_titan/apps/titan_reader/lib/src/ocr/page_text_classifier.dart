import '../domain/entities/ocr/page_text_classification.dart';
import '../manipulation/ast/pdf_document_ast.dart';
import '../manipulation/ast/pdf_primitive.dart';

/// Service classifying whether a PDF page contains native text or requires OCR.
class PageTextClassifier {
  const PageTextClassifier();

  /// Classifies a page given its extracted native character count and raster image count.
  PageTextClassification classifyPageMetrics({
    required int pageNumber,
    required int characterCount,
    required int rasterImageCount,
  }) {
    if (characterCount == 0 && rasterImageCount > 0) {
      return PageTextClassification.imageOnly(
        pageNumber: pageNumber,
        rasterImageCount: rasterImageCount,
        reason:
            'Page contains $rasterImageCount raster image(s) and zero selectable characters.',
      );
    }

    if (characterCount > 0 && rasterImageCount == 0) {
      return PageTextClassification.nativeText(
        pageNumber: pageNumber,
        characterCount: characterCount,
      );
    }

    if (characterCount > 0 && rasterImageCount > 0) {
      return PageTextClassification.mixed(
        pageNumber: pageNumber,
        characterCount: characterCount,
        rasterImageCount: rasterImageCount,
      );
    }

    return PageTextClassification(
      pageNumber: pageNumber,
      category: PageTextCategory.unknown,
      nativeCharacterCount: characterCount,
      rasterImageCount: rasterImageCount,
      isOcrRecommended: false,
      diagnosticReason: 'Empty page or undetectable content.',
    );
  }

  /// Inspects a [PdfDocumentAst] page dictionary to count embedded raster images (/XObject /Image).
  int countPageRasterImages(PdfDocumentAst ast, int pageNumber) {
    if (pageNumber < 1 || pageNumber > ast.pageCount) return 0;
    final pageRef = ast.pageRefs[pageNumber - 1];
    final pageObj = ast.objects[pageRef.objectNumber];
    if (pageObj is! PdfDict) return 0;

    final resourcesObj = _resolve(ast, pageObj['Resources']);
    if (resourcesObj is! PdfDict) return 0;

    final xobjectObj = _resolve(ast, resourcesObj['XObject']);
    if (xobjectObj is! PdfDict) return 0;

    var imageCount = 0;
    for (final key in xobjectObj.entries.keys) {
      final item = _resolve(ast, xobjectObj[key]);
      if (item is PdfStream) {
        final subtype = _resolve(ast, item.dict['Subtype']);
        if (subtype is PdfName && subtype.name == 'Image') {
          imageCount++;
        }
      }
    }
    return imageCount;
  }

  PdfObject? _resolve(PdfDocumentAst ast, PdfObject? obj) {
    if (obj is PdfRef) {
      return ast.objects[obj.objectNumber];
    }
    return obj;
  }
}
