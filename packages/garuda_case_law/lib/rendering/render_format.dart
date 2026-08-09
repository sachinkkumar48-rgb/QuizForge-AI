/// Export & Rendering layer (TITAN-KO-015.0 P8).
///
/// A deterministic, offline-first presentation layer that renders the existing
/// validated landmark-case knowledge into Markdown, HTML and JSON. P8 consumes
/// the P3–P7 knowledge; it never performs legal research, evidence discovery,
/// enrichment, graph construction or content generation.
library;

/// The three output formats supported by the P8 renderers.
enum RenderFormat { markdown, html, json }
