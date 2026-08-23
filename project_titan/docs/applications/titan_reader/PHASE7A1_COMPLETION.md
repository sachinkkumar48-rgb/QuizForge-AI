# Phase 7A-1 — Hindi / Devanagari Model Pack Foundation

**Document ID**: `TITAN-READER-7A1-CMP-001`
**Phase**: `Phase 7A-1 — Hindi / Devanagari Model Pack Foundation`
**Baseline Checkpoint**: `8195bf0` (Phase 7A Audit)
**Status**: `FOUNDATION COMPLETE`
**Language Pack Foundation Status**: `FOUNDATION READY`
**Production Hindi Model Status**: `NOT YET INTEGRATED (DEFERRED TO EXTERNAL ACQUISITION)`

---

## 1. Executive Summary & Objective

Phase 7A-1 establishes the architectural and security foundation for modular on-device Indic OCR Language Packs in **TITAN Reader**, with **Hindi / Devanagari** as the initial target.

### Accomplishments:
1. **Domain Contract**: Implemented `IndicLanguagePack` and `IndicPackManifest` domain models adhering to value equality and immutability.
2. **Path & Manifest Security**: Created `IndicLanguagePackManager` with strict sandboxing guards against path traversal (`../`, `..\`), absolute paths, UNC shares, null bytes, and unauthorized executable payloads.
3. **Cryptographic Integrity**: Integrated standalone FIPS 180-4 SHA-256 validation verifying both neural model weights (`model.onnx`) and character dictionary mappings (`dict.txt`).
4. **LRU Memory Management**: Designed an LRU cache eviction policy limiting active recognition models in memory (target budget $\le 65$ MB RAM).
5. **Zero Interface Breakage**: Built seamless conversion to `OcrModelDescriptor`, preserving 100% backward compatibility with `OcrEngine`, `OcrService`, `UnifiedTextContext`, and `PdfSearchableExportService`.
6. **100% Offline-First**: Local filesystem discovery and verification with zero network dependencies.

---

## 2. Phase 7A Baseline Context

* **Feasibility Audit Commit**: `8195bf0` (`docs(reader): audit indic ocr model expansion`)
* **Release Frozen Core Commit**: `00c465e` (Phase 6K)
* **Pre-existing Tests**: `707 / 707 PASS`
* **Analyzer Baseline**: `0 issues`

---

## 3. Architecture & Integration Flow

```
                      OcrService
                          │
                      OcrEngine
                          │
             IndicLanguagePackManager
                          │
        ┌─────────────────┴─────────────────┐
        ▼                                   ▼
  Base Text Detector                IndicLanguagePack
 (Universal DBNet)               (Hindi / Devanagari Pack)
                                            │
                               ┌────────────┴────────────┐
                               ▼                         ▼
                          model.onnx                  dict.txt
                      (INT8 Tensor Graph)       (Character Index Map)
```

### 3.1 Non-Destructive Downstream Decoupling
The language pack foundation does not replace or modify existing Reader abstractions:
* `OcrEngine` loads the pack via `pack.toOcrModelDescriptor()`.
* `UnifiedTextContext` continues to handle tokens and bounding boxes transparently.
* `LanguageServicesBridge` and `AiReadingService` consume UTF-8 text strings without dependency on the underlying script.
* `PdfSearchableExportService` embeds generated Devanagari Unicode glyphs into derivative PDFs.

---

## 4. Hindi Pack Metadata Descriptor

The first production target is modeled as an uninstalled foundation descriptor:

| Property | Value | Description |
|---|---|---|
| **Pack ID** | `titan-ocr-indic-hindi` | Canonical pack identifier |
| **Display Name** | `Hindi (Devanagari) OCR Pack` | User-facing title |
| **Language Code** | `hi` (BCP-47 / ISO 639-1) | Target language identifier |
| **Script Code** | `Deva` (ISO 15924) | Devanagari script code |
| **Model Family** | PP-OCRv4 compatible | 2-stage decoupled recognizer |
| **Quantization Target** | `int8` | Target quantized execution |
| **License** | `Apache-2.0` | Permissive commercial redistribution |
| **Status** | `FOUNDATION READY` | Pack metadata defined; weights externalized |

---

## 5. Manifest Schema & Packaging Format (`.titanpack`)

Each modular Indic language pack is structured as a sandboxed directory or `.titanpack` archive:

```
titan-ocr-indic-hindi/
├── manifest.json   (Cryptographic, versioning & license metadata)
├── model.onnx      (INT8 quantized recognition neural weights)
├── dict.txt        (Ordered UTF-8 character dictionary)
├── LICENSE         (Apache-2.0 license text)
└── NOTICE          (Attribution notices)
```

### 5.1 Manifest Schema Specification
```json
{
  "manifestVersion": "1.0.0",
  "packId": "titan-ocr-indic-hindi",
  "displayName": "Hindi (Devanagari) OCR Pack",
  "languageCode": "hi",
  "languageName": "Hindi",
  "scriptCode": "Deva",
  "scriptName": "Devanagari",
  "engineVersion": "1.0.0",
  "modelVersion": "1.0.0",
  "modelFormat": "onnx",
  "quantization": "int8",
  "modelFileName": "model.onnx",
  "modelSizeBytes": 9856512,
  "modelSha256": "<64-hex-sha256>",
  "dictFileName": "dict.txt",
  "dictSizeBytes": 14208,
  "dictSha256": "<64-hex-sha256>",
  "licenseType": "Apache-2.0",
  "licenseUrl": "https://github.com/PaddlePaddle/PaddleOCR",
  "minimumAppVersion": "0.1.0",
  "supportedPlatforms": ["windows", "macos", "linux", "android", "ios"]
}
```

---

## 6. Security, Integrity & Sandbox Verification

1. **Path Traversal Defense**: All manifest-declared filenames are strictly validated against:
   * Relative parent traversals (`../`, `..\`, `/..`, `\..`)
   * Absolute root paths (`C:\...`, `/etc/...`)
   * Network shares (`\\server\...`)
   * Null bytes (`\x00`) and ASCII control characters
2. **Prohibited Executable Extensions**: Model packs reject `.exe`, `.dll`, `.so`, `.dylib`, `.bat`, `.cmd`, `.sh`, `.ps1`, `.vbs`, `.js`, and `.py` files.
3. **Cryptographic Validation**: Files are rejected as `IndicLanguagePackStatus.corrupted` if calculated SHA-256 hashes differ from manifest values.
4. **Memory LRU Bounding**: When active loaded recognition models exceed `maxActiveRecognitionModels` (default 2), the least recently used model is nominated for eviction.

---

## 7. Automated Test Suite & Coverage

16 automated unit and security tests were added in `test/ocr/indic_language_pack_test.dart` covering:
* Test 1: Standard FIPS 180-4 SHA-256 calculation.
* Test 2: Manifest JSON roundtrip serialization.
* Test 3: Manifest schema validation errors.
* Test 4: Hindi foundation descriptor state.
* Test 5: Synthetic pack discovery to `ready` state.
* Test 6: Model SHA-256 mismatch detection.
* Test 7: Dictionary SHA-256 mismatch detection.
* Test 8: Missing model file handling.
* Test 9: Missing dictionary file handling.
* Test 10: Missing `manifest.json` handling.
* Test 11: Malformed JSON manifest handling.
* Test 12: Unsupported host platform rejection.
* Test 13: Path traversal and executable payload security.
* Test 14: Multi-pack directory discovery and state indexing.
* Test 15: LRU memory policy access tracking and model eviction.
* Test 16: Zero network execution and offline resilience.

---

## 8. Known Limitations & Deferred Work

### 8.1 Critical Limitation Distinction
* **FOUNDATION READY**: The domain entities, manifest validation, SHA-256 verification, and manager services are complete and verified.
* **PRODUCTION HINDI MODEL NOT YET BUNDLED**: Production ONNX model weights (~9.4 MB) were intentionally not committed to Git to keep repository size minimal. Production model acquisition will be handled via external packaging in Phase 7A-2.

---

## 9. Next Engineering Phase

**Phase 7A-2: Line-Level Script Router & Multi-Session ONNX Runner**
* Scope: Build the multi-model session runner in `OnnxOcrEngine`, line-level script classifier, and test Hindi-English bilingual exam paper recognition with synthetic weights.

---

*Report prepared by Senior Implementation Engineer: Antigravity*
*Project TITAN — TITAN Reader Engineering Team*
