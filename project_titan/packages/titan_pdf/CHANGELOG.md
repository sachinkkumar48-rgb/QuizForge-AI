# Changelog

## 0.1.0

- Initial release of the TITAN PDF Domain Module (`titan_pdf`).
- Implemented `PdfDocument`, `PdfMetadata`, `PdfChunk`, `PdfImportResult`, `ChunkOptions`, and `PdfStatus` models.
- Implemented `PdfException` domain exception hierarchy.
- Implemented `TokenEstimator`, `PdfValidationService`, `PdfChunkService`, and `PdfImportService`.
- Implemented `PdfRepository` contract and `PdfRepositoryImpl` extending `BaseRepository<PdfDocument>`.
- Implemented `TitanPdfBootstrap` integrating dependency registration into `TitanServiceLocator`.
