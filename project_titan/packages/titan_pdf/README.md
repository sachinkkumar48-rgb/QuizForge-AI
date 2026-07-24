# titan_pdf

PDF Domain Module for **Project TITAN**.

## Overview
`titan_pdf` provides high-level business domain abstractions for importing, validating, extracting, segmenting (chunking), and managing PDF document lifecycles without any direct third-party drivers or Flutter UI dependencies.

## Architecture
This package follows the TITAN Domain Module Template specifications:
- **Presentation / Feature Layer**: Consumes `PdfRepository` via `TitanServiceLocator`.
- **Domain Contracts**: Defines `PdfRepository`, `PdfDocument`, `PdfChunk`, `ChunkOptions`, and `PdfStatus`.
- **Services**: `PdfValidationService`, `PdfChunkService`, `PdfImportService`, and `TokenEstimator`.
- **Platform Coordination**: `PdfRepositoryImpl` extends `BaseRepository<PdfDocument>` and delegates persistence to `StorageService` (`titan_storage`).

## Dependencies
- `titan_core` (DI locator, config, logging, error handling)
- `titan_domain` (BaseRepository, RepositoryResult, CacheStrategy, TitanModuleBootstrap)
- Infrastructure abstractions (`titan_storage`, `titan_network`, `titan_ai`)

## Public API Exports
- `TitanPdfBootstrap`
- `PdfRepository` & `PdfRepositoryImpl`
- `PdfDocument`, `PdfMetadata`, `PdfChunk`, `ChunkOptions`, `PdfImportResult`
- `PdfStatus`
- `PdfException` hierarchy (`PdfImportException`, `PdfValidationException`, `PdfExtractionException`, `PdfChunkException`)

## Testing
Run unit test suite:
```bash
flutter test
```

## Extension Points
- Custom Chunking Strategies via `ChunkOptions`.
- Specialized text extraction integrations via `PdfRepositoryImpl`.
