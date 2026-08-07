/// URL utilities for GARUDA Evidence Engine.
class EvidenceURLUtils {
  /// Validate if a string URL is a valid http, https, or file URI.
  static bool isValidUrl(String url) {
    if (url.trim().isEmpty) return false;
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return false;
    final scheme = uri.scheme.toLowerCase();
    return scheme == 'http' || scheme == 'https' || scheme == 'file';
  }

  /// Canonicalize a web URL.
  static String normalizeUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return url.trim();
    return uri.normalizePath().toString();
  }
}
