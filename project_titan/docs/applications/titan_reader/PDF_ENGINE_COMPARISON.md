# TITAN Reader — PDF Engine Technical Comparison & License Audit

## Executive Summary

To achieve Adobe Acrobat Reader-class capabilities across Android and Windows without sacrificing performance, open-source integrity, or offline privacy, TITAN Reader must evaluate engine options across rendering, editing, annotations, forms, signatures, OCR, and document manipulation.

This document audits all candidate engines, their licensing, platform viability, and technical trade-offs.

---

## 1. Candidate PDF Engines Overview

| Engine / Library | Core Tech | Primary Strength | Primary Weakness | License | Commercial Viability |
| ---------------- | --------- | ---------------- | ---------------- | ------- | -------------------- |
| **`pdfrx` (2.4.7)** | Flutter + C++ PDFium FFI | High-performance rendering, text search & selection | View-only; zero PDF mutation/creation | MIT | ✅ 100% Free / Permissive |
| **`syncfusion_flutter_pdf`** | Pure Dart AST parser/generator | Full PDF manipulation, AcroForms, native annotations, digital signatures, redaction | Pure Dart parser is slower for multi-hundred MB files than C++ | Syncfusion Community License / Commercial | ⚠️ Free for <$1M rev / <5 devs; Paid commercial otherwise |
| **`pdf` (David Bourguignon)** | Pure Dart writer | Lightweight PDF creation, vector graphics, widgets | Cannot parse or mutate existing arbitrary PDF files | Apache-2.0 / BSD | ✅ 100% Free / Permissive |
| **`pdfium_bindings` (Direct PDFium FFI)** | Direct C++ Google PDFium FFI | Full access to `FPDF_EDIT`, `FPDF_ANNOT`, `FPDF_FORMFILL`, `FPDF_PPO` | Requires maintaining native cross-compilation toolchains (NDK / MSVC) | BSD-3-Clause | ✅ 100% Free / Permissive |
| **`MuPDF` (Artifex)** | C/C++ engine | Fast, complete rendering and annotation support | Strict viral AGPL-3.0 license | AGPL-3.0 / Commercial | ❌ AGPL incompatible with proprietary/commercial apps |
| **`PSPDFKit` / `Nutrient`** | Commercial C++ / Multi-platform | Complete enterprise feature set | Extremely expensive commercial subscription ($10k+/yr) | Proprietary Commercial | ❌ Incompatible with open-source/free-first |
| **Android Native (`PdfRenderer`/`PdfDocument`)** | Android OS Java/C++ | Zero package bloat on Android | Primitive rendering; no text extraction; write requires re-drawing from scratch | AOSP (Apache-2.0) | ✅ Android only |
| **Windows Native (`Windows.Data.Pdf`)** | WinRT C++ | Zero package bloat on Windows | Bitmap rendering only; no text extraction; no editing | Microsoft EULA | ✅ Windows only |

---

## 2. Detailed Technical Matrix

| Capability | `pdfrx` | `syncfusion_flutter_pdf` | Direct PDFium FFI | `pdf` (Dart) | MuPDF | Android Native | Windows Native |
| ---------- | ------- | ------------------------ | ----------------- | ------------ | ----- | -------------- | -------------- |
| **Rendering Quality** | High (PDFium) | Moderate (via viewer) | High (PDFium) | N/A (Write only) | High | Basic (Bitmap) | Basic (Bitmap) |
| **Hardware Acceleration** | Yes (Skia/Impeller) | Yes | Yes | N/A | Yes | Yes | Yes |
| **Text Extraction & Selection** | Yes (Glyph-accurate) | Yes (String/Text) | Yes (Glyph-accurate) | No | Yes | No | No |
| **Outline / Bookmark Reading** | Yes | Yes | Yes | No | Yes | No | No |
| **PDF-Native Annotation Read** | Metadata only | Full (All types) | Full (FPDF_ANNOT) | No | Full | No | No |
| **PDF-Native Annotation Write** | No | Full (Highlight, Ink, etc.) | Full (FPDF_ANNOT) | Append only | Full | No | No |
| **Page Operations (Merge/Split/Rotate)**| No | Full (Split, Merge, Rotate, Delete) | Full (FPDF_PPO) | No | Full | No | No |
| **AcroForm Field Inspection & Fill** | No | Full (Text, Check, Radio, Dropdown) | Full (FPDF_FORMFILL) | No | Full | No | No |
| **Cryptographic Digital Signatures** | No | Full (PAdES, X.509, PKCS#7) | Requires OpenSSL binding | No | Full | No | No |
| **True Content Redaction** | No | Full (Removes underlying stream) | Requires manual stream surgery | No | Full | No | No |
| **OCR Text Layer Generation** | No | Supported via external OCR input | Supported via external OCR input | Supported | Built-in (Tesseract) | ML Kit (external) | Windows OCR (external) |
| **Printing Integration** | Via OS raster | Via OS raster | Via OS raster | Direct native pipeline | Native | PrintHelper | WinRT Print |
| **Android Support** | ✅ Excellent | ✅ Excellent | ✅ Full (Requires NDK binaries) | ✅ Full | ✅ Full | ✅ Native | ❌ N/A |
| **Windows Support** | ✅ Excellent | ✅ Excellent | ✅ Full (Requires DLL binaries) | ✅ Full | ✅ Full | ❌ N/A | ✅ Native |
| **Package Overhead** | ~15MB (PDFium DLL/so) | ~1MB (Pure Dart) | ~15MB (PDFium DLL/so) | <500KB | ~25MB | 0MB | 0MB |

---

## 3. License Audit & Legal Assessment

### A. MIT License (`pdfrx`)
* **Redistribution**: Permitted without restrictions.
* **Commercial Use**: Permitted without royalty.
* **Source Disclosure**: Not required.
* **Assessment**: Ideal for the core rendering view.

### B. Syncfusion Community License / Commercial (`syncfusion_flutter_pdf`)
* **Community License Grant**: Free for companies and individuals with less than \$1M USD in gross annual revenue and fewer than 5 developers.
* **Commercial License**: Paid commercial license required for enterprises exceeding the thresholds.
* **Redistribution**: Royalty-free runtime redistribution of binary applications.
* **Source Disclosure**: Not required.
* **Assessment**: High-value option for rapid implementation of complex manipulation, forms, and signatures, but creates commercial licensing obligations for large enterprise deployments.

### C. BSD-3-Clause (PDFium / `pdfium_bindings`)
* **Redistribution**: Permitted with copyright notice retention.
* **Commercial Use**: 100% free and open.
* **Source Disclosure**: Not required.
* **Assessment**: Maximum long-term commercial freedom and zero license friction.

### D. AGPL-3.0 (`MuPDF`)
* **Strict Copyleft Risk**: Any network or distributed application incorporating AGPL code must make its entire source code available under AGPL-3.0.
* **Assessment**: **REJECTED**. Unacceptable for TITAN’s commercial and modular open-source goals.

---

## 4. Multi-Engine Strategy Decision

### Selected Option: **Option D — Multi-Engine Modular Architecture**

1. **Rendering & Interactive View**: Retain **`pdfrx`** (PDFium). It already provides proven 60/120fps smooth scrolling, glyph-level text selection, debounced search, outline traversal, and custom canvas overlay rendering across Windows and Android.
2. **Document Manipulation & Native PDF Serialization**: Pure Dart / PDFium modular manipulation services (`PdfDocumentService`, `PdfNativeAnnotationService`, `PdfFormService`).
3. **On-Device OCR**: Modular on-device OCR engine (`Google ML Kit` on Android, `Tesseract / Windows.Media.Ocr` on Windows).
4. **Digital Signatures**: Standard cryptographic PKCS#7 / PAdES signing engine using pure Dart cryptography (`pointycastle` / `crypto`).
