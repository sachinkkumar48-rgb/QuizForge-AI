# TITAN Reader — Phase 6 Implementation Roadmap

## 1. Executive Phasing Strategy

Phase 6 elevates TITAN Reader from a reading and study tool into a **professional personal PDF powerhouse** matching Adobe Acrobat Reader's core utility.

To ensure architectural cleanliness, stability, and zero risk of regression to existing Phase 1–5 features or QuizForge AI, Phase 6 is divided into 7 focused, sequential sub-phases.

```
Phase 6A (Page Ops & Manipulation)
   ↓
Phase 6B (PDF-Native Annotations & Export)
   ↓
Phase 6C (Interactive AcroForms)
   ↓
Phase 6D (On-Device OCR & Text Layers)
   ↓
Phase 6E (Signatures & Verification)
   ↓
Phase 6F (True Redaction & Security)
   ↓
Phase 6G (Printing, Attachments & Accessibility)
```

---

## 2. Detailed Sub-Phase Specifications

### Phase 6A — PDF Document Manipulation & Page Operations (P0: Essential)
* **Goal**: Enable full document structure editing without external tools.
* **Capabilities**:
  * **Merge PDFs**: Combine multiple PDF files in user-defined sequence.
  * **Split PDFs**: Split by page ranges, single pages, or bookmarks.
  * **Extract Pages**: Save selected pages as an independent PDF.
  * **Delete Pages**: Remove selected pages with integrity validation.
  * **Reorder Pages**: Drag-and-drop page grid reordering.
  * **Rotate Pages**: 90°/180°/270° permanent page rotation in the PDF dictionary.
  * **Insert Pages**: Insert blank pages or pages from another PDF at specific indices.
  * **Duplicate Pages**: Duplicate pages within the same document.
  * **Page Labels**: Support Roman numerals (i, ii, iii) vs Arabic numbers (1, 2, 3) conforming to PDF `/PageLabels`.
* **Deliverables**: `PdfDocumentManipulationService`, Page Manager Grid UI dialog, unit & integration test suite.

### Phase 6B — PDF-Native Annotations & Import / Export (P0: Essential)
* **Goal**: Bi-directional interoperability between TITAN Reader-managed annotations and standard PDF-native annotation streams (`/Annots`).
* **Capabilities**:
  * **Read PDF-Native Annotations**: Inspect existing highlights, underlines, strikeouts, free-text boxes, ink drawings, and sticky notes created in Adobe Acrobat or Apple Preview.
  * **Export to PDF-Native**: Export Reader-managed annotations into true ISO 32000 PDF annotation dictionaries (`/Highlight`, `/Underline`, `/StrikeOut`, `/Ink`, `/FreeText`, `/Text`).
  * **Import PDF-Native**: Ingest external PDF annotations into Reader-managed storage for continued study and AI features.
  * **Flatten Annotations**: Burn annotations directly into the page content stream (`/Contents`) for universal read-only distribution.
* **Deliverables**: `PdfNativeAnnotationService`, Import/Export dialog, flattened PDF export pipeline.

### Phase 6C — Interactive Forms (AcroForms) (P1: High Value)
* **Goal**: Full PDF form filling and submission workflow.
* **Capabilities**:
  * **Form Field Detection**: Identify `/AcroForm` fields and interactive widgets across pages.
  * **Field Types**: Text input (`/Tx`), Checkboxes (`/Btn`), Radio buttons (`/Btn`), Dropdowns (`/Ch`), List boxes (`/Ch`).
  * **Interactive Form Layer**: Render dynamic Flutter form inputs aligned over PDF widget rectangles.
  * **Form Data Persistence**: Save form values to PDF file dictionary or export/import FDF/XFDF data.
  * **Form Reset & Flattening**: Clear form fields or flatten form values permanently into document text.
* **Deliverables**: `PdfFormService`, `PdfFormWidgetLayer`, field validation engine.

### Phase 6D — On-Device OCR & Searchable Text Layers (P1: High Value)
* **Goal**: Convert scanned, image-only PDFs into fully searchable, selectable, and AI-queryable documents.
* **Capabilities**:
  * **Scanned Document Detection**: Heuristic detection of image-only pages lacking text streams.
  * **Page & Document OCR**: Optical character recognition on single pages or batch document processing.
  * **Language Support**: English + Hindi (Devanagari script) support.
  * **Invisible Searchable Text Layer**: Inject invisible text glyphs behind scanned images with exact geometric bounding boxes.
  * **Platform Engines**:
    * **Android**: Google ML Kit Text Recognition (on-device, offline, hardware-accelerated).
    * **Windows**: Offline Tesseract 5 / ONNX-based OCR runtime (e.g. PP-OCRv4 ONNX).
* **Deliverables**: `PdfOcrService`, `OcrEngine` adapter interface, progress modal dialog, batch OCR worker.

### Phase 6E — Signatures & Verification (P1: High Value)
* **Goal**: Legal document signing and cryptographic integrity verification.
* **Capabilities**:
  * **Visual Signatures**:
    * Draw signature with finger/stylus/mouse (smooth Bézier curves).
    * Type signature with stylized script fonts.
    * Import signature image (PNG/JPG) with background transparency cleanup.
    * Save user signatures to secure local storage (`titan.reader.signatures`).
    * Place, resize, and position visual signature stamps on any page.
  * **Cryptographic Digital Signatures**:
    * Standard X.509 certificate-based signing (PAdES / PKCS#7 detached signature).
    * Signature verification: validate certificate chain, document hash integrity, and modification timestamp.
    * Visual signature appearance linked to cryptographic `/ByteRange` signature field.
* **Deliverables**: `PdfSignatureService`, Signature Drawing Dialog, Certificate Manager, signature verification badge.

### Phase 6F — True Content Redaction & Document Security (P2: Advanced)
* **Goal**: Enterprise-grade privacy protection and sensitive data sanitization.
* **Capabilities**:
  * **True Content Redaction**:
    * Physically remove underlying vector paths, text characters, and raster pixels within the redaction bounding box from the `/Contents` stream.
    * Sanitize document metadata (XMP and Info dictionary) to prevent data leakage.
    * Redact text by search query or pattern (e.g. Aadhaar numbers, PAN cards, phone numbers, emails).
  * **Password Protection & Encryption**:
    * Standard PDF encryption (AES-128 and AES-256).
    * User password (open document) and Owner/Permissions password (restrict printing, copying, editing).
* **Deliverables**: `PdfRedactionService`, `PdfSecurityService`, Redaction toolbar action, Security Settings dialog.

### Phase 6G — Advanced Printing, Attachments & Accessibility (P2: Advanced)
* **Goal**: Seamless desktop/mobile integration and full accessibility compliance.
* **Capabilities**:
  * **Native OS Printing**:
    * Android: Android `PrintManager` integration with page range, orientation, and copies selection.
    * Windows: Direct Windows print dialog integration with paper size, duplex, and raster scaling.
  * **Embedded File Attachments**:
    * View, extract, add, and delete files embedded inside the PDF `/EmbeddedFiles` name tree.
  * **Accessibility & Screen Reader Compliance**:
    * Semantic text extraction adhering to PDF reading order.
    * Tagged PDF (/StructTreeRoot) navigation where present.
    * High contrast reading modes and keyboard-driven page navigation.
* **Deliverables**: `PdfPrintService`, `PdfAttachmentService`, Attachment sidebar panel.

---

## 3. Dependency & Risk Analysis

| Sub-Phase | Primary Dependencies | Technical Risks | Mitigation Strategy |
| --------- | -------------------- | --------------- | ------------------- |
| **6A: Page Ops** | `pdfrx`, PDF AST manipulator | File corruption on save | Save to temporary file first; atomic rename after integrity verification |
| **6B: Native Annots** | PDF annotation serializer | Incompatible annotation types across readers | Strict adherence to ISO 32000-1 standard annotation schemas |
| **6C: AcroForms** | Form widget coordinate mapping | Coordinate mismatches across DPI/zoom | Normalized coordinate mapping matching Phase 2 annotation pipeline |
| **6D: OCR** | ML Kit (Android), Tesseract/ONNX (Windows) | Large asset size on Windows; high memory on batch | Lazy on-demand model download/loading; isolate worker threads |
| **6E: Signatures** | Cryptographic X.509 PKCS#7 engine | Signature invalidation by subsequent edits | Place signature as final step; enforce incremental update rules |
| **6F: Redaction** | Stream parser & object stripper | Incomplete text glyph removal | Parse character glyph coordinates directly and strip overlapping stream operators |
| **6G: Printing** | Platform printing channels | Platform-specific print spooler crashes | Pure raster fallback rendering through PDFium |
