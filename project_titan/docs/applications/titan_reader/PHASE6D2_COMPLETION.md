# TITAN Reader — Phase 6D-2 Completion Report: Native PDF Outline / Table-of-Contents Navigation

**Phase**: 6D-2 — Native PDF Outline / Table-of-Contents Navigation
**Status**: Shipped & Fully Verified ✅
**Test Suite**: 481/481 passing (`titan_reader`)
**Static Analysis**: 0 issues (`dart analyze project_titan/apps/titan_reader`)
**Date**: August 21, 2026

---

## 1. Executive Summary

Phase 6D-2 delivers native **PDF Outline / Table-of-Contents (TOC) Navigation** for TITAN Reader. Built upon the engine-agnostic `PdfViewerHandle` abstraction and the native `pdfrx` document outline loader, this capability gives users an interactive, searchable, multi-level hierarchical table of contents sidebar docked directly alongside the reader viewport.

The implementation provides instant jump navigation, branch expansion/collapsing, real-time title search filtering, active section highlighting, graceful fallback for documents lacking outlines or entries with non-page targets, and full screen-reader accessibility semantics.

---

## 2. Shipped Capabilities

1. **Collapsible Table of Contents Sidebar (`OutlineSidebar`)**:
   - Left-docked navigation panel beside the main PDF viewer.
   - Dedicated AppBar toggle button (`Key('outline-sidebar-button')`) with active visual state and mutual exclusion with the page thumbnail sidebar.
   - Responsive panel width (`260dp` on desktop viewports, `210dp` on compact mobile displays).
   - Dedicated header with icon, title, global "Expand All" / "Collapse All" quick-action buttons, and close button.

2. **Hierarchical Multi-Level Tree Rendering**:
   - Recursively maps arbitrary nested outline trees from `ReaderOutlineEntry` (e.g., Part $\to$ Chapter $\to$ Section $\to$ Subsection).
   - Indentation depth scaling (`depth * 16.0`) with visual bullet markers for leaf items.
   - Individual branch expansion/collapse chevron toggles with persistent local state.
   - Destination page badges (`Page X`) displayed on entries with resolved page numbers.

3. **Instant Viewport Navigation & Bi-directional Synchronization**:
   - **Outline Node Tap**: Invokes `handle.goToOutlineEntry(entry.path)`, which resolves the native PDF destination (`controller.goToDest(dest)`) or page number.
   - **Active Section Indicator**: Highlights the outline entry whose destination page corresponds to the reader's `currentPage`, styled with primary theme tint, accent border, and bold typography.

4. **Real-Time Section Search / Filtering**:
   - Built-in search field at the top of the sidebar.
   - Instant title query filtering across all tree levels with automatic ancestor matching.
   - Quick "Clear Filter" action button with immediate tree restoration.

5. **Defensive Non-Destructive Resilience**:
   - **Empty Outline State**: Displays a clean, user-friendly "This document has no table of contents" placeholder.
   - **Unresolved / External Destinations**: Tolerates null `pageNumber` destinations (e.g. URI actions or named targets) without crashing or breaking layout.

6. **Accessibility**:
   - Implements explicit `Semantics` tags (`label`, `isButton`, `selected`) for screen readers.

---

## 3. Architecture & Engine Integration

```
┌────────────────────────────────────────────────────────────────────────┐
│                        Reader Presentation                             │
│  - ReaderScreen (AppBar toggle buttons + responsive Row body)          │
│    ├── OutlineSidebar (Left TOC Navigation Panel)                      │
│    │   ├── Expand All / Collapse All Controls                          │
│    │   ├── Search / Filter Bar                                         │
│    │   └── Recursive Node Hierarchy (title, chevron, page badge)       │
│    ├── ThumbnailSidebar (Left Visual Page Thumbnails)                  │
│    └── Main PDF Viewport (pdfrx / PDFium surface)                      │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
┌───────────────────────────────────▼────────────────────────────────────┐
│                         Engine Abstraction                             │
│  - PdfViewerHandle                                                     │
│    ├── Future<List<ReaderOutlineEntry>> loadOutline()                  │
│    ├── Future<void> goToOutlineEntry(String path)                      │
│    └── Future<void> goToPage(int pageNumber)                           │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
┌───────────────────────────────────▼────────────────────────────────────┐
│                    Concrete Rendering Adapters                         │
│  - PdfrxPdfEngine / PdfrxViewerHandle                                  │
│    ├── controller.document.loadOutline() -> PdfOutlineNode             │
│    └── controller.goToDest(dest)                                       │
│  - FakePdfEngine / FakeViewerHandle (for headless widget tests)        │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Test Verification Summary

- **New Tests Added**: `test/widgets/outline_sidebar_test.dart` (8 tests)
- **Integration Updated**: `test/screens/reader_screen_test.dart` (+1 test)
- **Total Tests Passing**: 481 / 481 in `titan_reader`
- **Static Analysis**: 0 errors, 0 warnings
- **Formatting**: 100% compliant with `dart format`

### Verified Scenarios:
1. Empty / no-outline document state rendering with guidance placeholder.
2. Single-level outline rendering with destination page badges.
3. Node tap navigation invoking `handle.goToOutlineEntry` and page navigation.
4. Multi-level nested outline hierarchy with branch expand/collapse chevron toggling.
5. Global Expand All / Collapse All action buttons toggling the entire hierarchy.
6. Real-time section title search filtering and query clearing.
7. Graceful tolerance of outline entries with null/missing page destinations.
8. Sidebar close button callback execution.
9. Reader screen toolbar button toggle and synchronized navigation.
