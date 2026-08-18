# TITAN Reader — Privacy

## LOCAL_ONLY default

Every imported document is stored with `DocumentPrivacyState.localOnly`.
Phase 1 has **no network surface at all**: no uploads, no analytics, no
telemetry, no AI calls. Documents are read from and indexed on the device
only.

## Enforcement points

| Point | Behavior |
| ----- | -------- |
| `ReaderDocument` entity | privacy state field defaults to `localOnly` |
| `LibraryService.importFile` | persists entries as `localOnly` |
| Persistence | all library/position/history data goes through `titan_storage` on-device storage |
| PDF rendering | `pdfrx`/PDFium renders local files; no remote document sources are used |

## Later phases

Dictionary, grammar and AI-assistant features (Phase 2+) may require
external services. The mandate requires:

1. explicit, per-feature user opt-in before any data leaves the device;
2. privacy state transitions visible on the document (never silent);
3. LOCAL_ONLY remaining the default for every new import.

Any such change must update this document and the feature matrix.
