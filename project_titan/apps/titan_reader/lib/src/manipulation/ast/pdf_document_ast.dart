import 'pdf_primitive.dart';
import '../../domain/entities/pdf_page_label_config.dart';
import '../../domain/pdf_manipulation_errors.dart';

/// In-memory representation of a mutable PDF Document Object Graph (ISO 32000-1 §7.7).
class PdfDocumentAst {
  String header;
  final Map<int, PdfObject> objects;
  final Map<int, int> objectGenerations;
  final PdfDict trailer;
  final PdfDict catalog;

  late PdfDict _pagesRoot;
  late int _pagesRootObjNum;
  final List<PdfRef> _pageRefs = [];

  PdfDocumentAst({
    required this.header,
    required this.objects,
    required this.objectGenerations,
    required this.trailer,
    required this.catalog,
  }) {
    _resolvePagesTree();
  }

  /// Total number of pages in the document.
  int get pageCount => _pageRefs.length;

  /// Ordered list of page object references.
  List<PdfRef> get pageRefs => List.unmodifiable(_pageRefs);

  /// Resolves the `/Pages` root and flattens all `/Page` leaves into [_pageRefs].
  void _resolvePagesTree() {
    _pageRefs.clear();
    final pagesRef = catalog['Pages'];
    if (pagesRef is PdfRef) {
      _pagesRootObjNum = pagesRef.objectNumber;
      final obj = objects[_pagesRootObjNum];
      if (obj is PdfDict) {
        _pagesRoot = obj;
      } else {
        throw const PdfInvalidDocumentException(
            'Pages root object is not a dictionary.',
            filePath: '');
      }
    } else if (pagesRef is PdfDict) {
      _pagesRoot = pagesRef;
      _pagesRootObjNum = _findObjNumFor(pagesRef) ?? 2;
    } else {
      throw const PdfInvalidDocumentException('Catalog missing /Pages entry.',
          filePath: '');
    }

    _collectPages(_pagesRoot);
  }

  void _collectPages(
    PdfDict node, {
    PdfObject? inheritedMediaBox,
    PdfObject? inheritedCropBox,
    PdfObject? inheritedResources,
    PdfObject? inheritedRotate,
  }) {
    final curMediaBox = node['MediaBox'] ?? inheritedMediaBox;
    final curCropBox = node['CropBox'] ?? inheritedCropBox;
    final curResources = node['Resources'] ?? inheritedResources;
    final curRotate = node['Rotate'] ?? inheritedRotate;

    final type = node.getName('Type');
    if (type == 'Page') {
      if (!node.containsKey('MediaBox') && curMediaBox != null) {
        node['MediaBox'] = curMediaBox;
      }
      if (!node.containsKey('CropBox') && curCropBox != null) {
        node['CropBox'] = curCropBox;
      }
      if (!node.containsKey('Resources') && curResources != null) {
        node['Resources'] = curResources;
      }
      if (!node.containsKey('Rotate') && curRotate != null) {
        node['Rotate'] = curRotate;
      }

      final objNum = _findObjNumFor(node);
      if (objNum != null) {
        _pageRefs.add(PdfRef(objNum));
      }
      return;
    }

    final kids = node.getArray('Kids');
    if (kids == null) return;

    for (var i = 0; i < kids.length; i++) {
      final kid = kids[i];
      if (kid is PdfRef) {
        final childObj = objects[kid.objectNumber];
        if (childObj is PdfDict) {
          final childType = childObj.getName('Type');
          if (childType == 'Page') {
            if (!childObj.containsKey('MediaBox') && curMediaBox != null) {
              childObj['MediaBox'] = curMediaBox;
            }
            if (!childObj.containsKey('CropBox') && curCropBox != null) {
              childObj['CropBox'] = curCropBox;
            }
            if (!childObj.containsKey('Resources') && curResources != null) {
              childObj['Resources'] = curResources;
            }
            if (!childObj.containsKey('Rotate') && curRotate != null) {
              childObj['Rotate'] = curRotate;
            }
            _pageRefs.add(kid);
          } else if (childType == 'Pages') {
            _collectPages(
              childObj,
              inheritedMediaBox: curMediaBox,
              inheritedCropBox: curCropBox,
              inheritedResources: curResources,
              inheritedRotate: curRotate,
            );
          } else {
            // Default to page if has /MediaBox or /Contents
            if (childObj.containsKey('MediaBox') ||
                childObj.containsKey('Contents') ||
                curMediaBox != null) {
              if (!childObj.containsKey('MediaBox') && curMediaBox != null) {
                childObj['MediaBox'] = curMediaBox;
              }
              if (!childObj.containsKey('CropBox') && curCropBox != null) {
                childObj['CropBox'] = curCropBox;
              }
              if (!childObj.containsKey('Resources') && curResources != null) {
                childObj['Resources'] = curResources;
              }
              if (!childObj.containsKey('Rotate') && curRotate != null) {
                childObj['Rotate'] = curRotate;
              }
              _pageRefs.add(kid);
            }
          }
        }
      } else if (kid is PdfDict) {
        _collectPages(
          kid,
          inheritedMediaBox: curMediaBox,
          inheritedCropBox: curCropBox,
          inheritedResources: curResources,
          inheritedRotate: curRotate,
        );
      }
    }
  }

  int? _findObjNumFor(PdfObject target) {
    for (final entry in objects.entries) {
      if (identical(entry.value, target) || entry.value == target) {
        return entry.key;
      }
    }
    return null;
  }

  /// Returns the next available unique object number.
  int nextAvailableObjectNumber() {
    var maxNum = 0;
    for (final num in objects.keys) {
      if (num > maxNum) maxNum = num;
    }
    return maxNum + 1;
  }

  /// Gets the [PdfDict] for page at [zeroBasedIndex].
  PdfDict getPageDict(int zeroBasedIndex) {
    if (zeroBasedIndex < 0 || zeroBasedIndex >= _pageRefs.length) {
      throw PdfPageRangeOutOfBoundsException(
        'Page index $zeroBasedIndex is out of bounds (total $pageCount).',
        requestedPage: zeroBasedIndex + 1,
        maxPages: pageCount,
      );
    }
    final ref = _pageRefs[zeroBasedIndex];
    final obj = objects[ref.objectNumber];
    if (obj is! PdfDict) {
      throw PdfInvalidDocumentException(
          'Object ${ref.objectNumber} is not a valid Page dictionary.',
          filePath: '');
    }
    return obj;
  }

  /// Rotates the page at [zeroBasedIndex] by [degrees] (0, 90, 180, 270).
  void rotatePage(int zeroBasedIndex, int degrees, {bool relative = true}) {
    final page = getPageDict(zeroBasedIndex);
    final currentRotation = page.getInt('Rotate') ?? 0;
    final finalRotation = relative
        ? ((currentRotation + degrees) % 360 + 360) % 360
        : ((degrees % 360 + 360) % 360);

    page['Rotate'] = PdfNumber(finalRotation);
  }

  /// Reorders pages according to [newZeroBasedOrder].
  void reorderPages(List<int> newZeroBasedOrder) {
    if (newZeroBasedOrder.length != _pageRefs.length) {
      throw const PdfManipulationException(
          'Reorder list length must match existing page count.');
    }

    final newRefs = <PdfRef>[];
    final seen = <int>{};

    for (final idx in newZeroBasedOrder) {
      if (idx < 0 || idx >= _pageRefs.length) {
        throw PdfPageRangeOutOfBoundsException(
            'Reorder index $idx is out of range.',
            requestedPage: idx + 1,
            maxPages: pageCount);
      }
      if (!seen.add(idx)) {
        throw PdfManipulationException(
            'Duplicate page index $idx in reorder sequence.');
      }
      newRefs.add(_pageRefs[idx]);
    }

    _pageRefs.clear();
    _pageRefs.addAll(newRefs);
    _syncPagesRootKids();
  }

  /// Deletes the specified [zeroBasedIndices] from the document.
  void deletePages(List<int> zeroBasedIndices) {
    final toDelete = zeroBasedIndices.toSet();
    if (toDelete.isEmpty) return;

    if (toDelete.length >= _pageRefs.length) {
      throw const PdfEmptyDocumentResultException(
          'Cannot delete all pages in document; result would be empty.');
    }

    final remainingRefs = <PdfRef>[];
    for (var i = 0; i < _pageRefs.length; i++) {
      if (!toDelete.contains(i)) {
        remainingRefs.add(_pageRefs[i]);
      }
    }

    _pageRefs.clear();
    _pageRefs.addAll(remainingRefs);
    _syncPagesRootKids();
  }

  /// Inserts a new blank page at [zeroBasedTargetIndex].
  void insertBlankPage(int zeroBasedTargetIndex,
      {double width = 595.0, double height = 842.0}) {
    final clampedIndex = zeroBasedTargetIndex.clamp(0, _pageRefs.length);
    final newPageNum = nextAvailableObjectNumber();

    final blankPageDict = PdfDict({
      'Type': const PdfName('Page'),
      'Parent': PdfRef(_pagesRootObjNum),
      'MediaBox': PdfArray([
        const PdfNumber(0),
        const PdfNumber(0),
        PdfNumber(width),
        PdfNumber(height)
      ]),
      'Resources': PdfDict(),
    });

    objects[newPageNum] = blankPageDict;
    objectGenerations[newPageNum] = 0;

    final ref = PdfRef(newPageNum);
    _pageRefs.insert(clampedIndex, ref);
    _syncPagesRootKids();
  }

  /// Inserts pages from [sourceAst] at [zeroBasedTargetIndex].
  void insertPagesFrom(PdfDocumentAst sourceAst, List<int> sourceZeroBasedPages,
      int zeroBasedTargetIndex) {
    final clampedIndex = zeroBasedTargetIndex.clamp(0, _pageRefs.length);

    // Compute ID offset to remap all source objects without collision
    final idOffset = nextAvailableObjectNumber();
    final remappedSourceRefs = <PdfRef>[];

    // 1. Copy all objects with shifted IDs and updated references
    for (final entry in sourceAst.objects.entries) {
      final oldId = entry.key;
      final newId = oldId + idOffset;
      final remappedObj = _deepRemapReferences(
          entry.value, idOffset, _pagesRootObjNum, sourceAst._pagesRootObjNum);
      objects[newId] = remappedObj;
      objectGenerations[newId] = 0;
    }

    // 2. Collect inserted page refs
    for (final srcIdx in sourceZeroBasedPages) {
      if (srcIdx >= 0 && srcIdx < sourceAst.pageCount) {
        final oldRef = sourceAst._pageRefs[srcIdx];
        final newRef = PdfRef(oldRef.objectNumber + idOffset);

        // Update Parent pointer to point to this document's /Pages root
        final pageDict = objects[newRef.objectNumber];
        if (pageDict is PdfDict) {
          pageDict['Parent'] = PdfRef(_pagesRootObjNum);
        }

        remappedSourceRefs.add(newRef);
      }
    }

    _pageRefs.insertAll(clampedIndex, remappedSourceRefs);
    _syncPagesRootKids();
  }

  /// Configures the `/PageLabels` dictionary in `/Catalog`.
  void setPageLabels(List<PdfPageLabelRange> labelRanges) {
    if (labelRanges.isEmpty) {
      catalog.remove('PageLabels');
      return;
    }

    final numsArray = PdfArray();
    for (final range in labelRanges) {
      // PDF /PageLabels uses 0-based page offset in /Nums array
      final zeroIndex = range.startPage - 1;
      final labelDict = PdfDict();

      final styleCode = range.style.pdfStyleCode;
      if (styleCode != null) {
        labelDict['S'] = PdfName(styleCode);
      }
      if (range.prefix.isNotEmpty) {
        labelDict['P'] = PdfString.fromString(range.prefix);
      }
      if (range.startNumber > 1) {
        labelDict['St'] = PdfNumber(range.startNumber);
      }

      numsArray.add(PdfNumber(zeroIndex));
      numsArray.add(labelDict);
    }

    catalog['PageLabels'] = PdfDict({
      'Nums': numsArray,
    });
  }

  /// Clones a subset of pages into a new self-contained [PdfDocumentAst].
  PdfDocumentAst extractSubDocument(List<int> zeroBasedIndices) {
    if (zeroBasedIndices.isEmpty) {
      throw const PdfEmptyPageSelectionException(
          'Must select at least one page to extract.');
    }

    final newObjects = <int, PdfObject>{};
    final newGenerations = <int, int>{};

    // New Catalog = 1, New Pages = 2
    final newCatalog = PdfDict(const {
      'Type': PdfName('Catalog'),
      'Pages': PdfRef(2),
    });
    final newPages = PdfDict({
      'Type': const PdfName('Pages'),
      'Kids': PdfArray(),
      'Count': PdfNumber(zeroBasedIndices.length),
    });

    newObjects[1] = newCatalog;
    newGenerations[1] = 0;
    newObjects[2] = newPages;
    newGenerations[2] = 0;

    final newTrailer = PdfDict(const {
      'Root': PdfRef(1),
    });

    final subDoc = PdfDocumentAst(
      header: header,
      objects: newObjects,
      objectGenerations: newGenerations,
      trailer: newTrailer,
      catalog: newCatalog,
    );

    final idOffset = subDoc.nextAvailableObjectNumber();
    // Insert selected pages into the new subDoc
    subDoc.insertPagesFrom(this, zeroBasedIndices, 0);

    if (trailer.containsKey('Info')) {
      final infoRef = trailer['Info'];
      if (infoRef is PdfRef) {
        subDoc.trailer['Info'] = PdfRef(infoRef.objectNumber + idOffset);
      } else if (infoRef is PdfDict) {
        subDoc.trailer['Info'] = infoRef;
      }
    }

    return subDoc;
  }

  PdfObject _deepRemapReferences(PdfObject obj, int idOffset,
      int targetPagesRootId, int sourcePagesRootId) {
    if (obj is PdfRef) {
      if (obj.objectNumber == sourcePagesRootId) {
        return PdfRef(targetPagesRootId);
      }
      return PdfRef(obj.objectNumber + idOffset, obj.generationNumber);
    } else if (obj is PdfArray) {
      final newArray = PdfArray();
      for (var i = 0; i < obj.length; i++) {
        newArray.add(_deepRemapReferences(
            obj[i], idOffset, targetPagesRootId, sourcePagesRootId));
      }
      return newArray;
    } else if (obj is PdfDict) {
      final newDict = PdfDict();
      for (final entry in obj.entries.entries) {
        if (entry.key == 'Parent' &&
            entry.value is PdfRef &&
            (entry.value as PdfRef).objectNumber == sourcePagesRootId) {
          newDict[entry.key] = PdfRef(targetPagesRootId);
        } else {
          newDict[entry.key] = _deepRemapReferences(
              entry.value, idOffset, targetPagesRootId, sourcePagesRootId);
        }
      }
      return newDict;
    } else if (obj is PdfStream) {
      final newDict = _deepRemapReferences(
          obj.dict, idOffset, targetPagesRootId, sourcePagesRootId) as PdfDict;
      return PdfStream(dict: newDict, data: obj.data);
    }
    return obj;
  }

  void _syncPagesRootKids() {
    final kidsArray = PdfArray(_pageRefs);
    _pagesRoot['Kids'] = kidsArray;
    _pagesRoot['Count'] = PdfNumber(_pageRefs.length);
  }
}
