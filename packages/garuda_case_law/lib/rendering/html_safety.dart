/// HTML safety helpers for the P8 HTML renderer (TITAN-KO-015.0 P8).
///
/// Dynamic case content is never trusted. Element text is escaped, attribute
/// values are escaped, and only `http(s)` URLs are emitted as link targets —
/// so a `javascript:` or `data:` value in case text, evidence metadata, titles
/// or URLs can never become executable content. There is no JavaScript and no
/// inline styling in any emitted HTML. Unicode / Devanagari passes through
/// unescaped (the escape modes used here only neutralise markup characters).
library;

import 'dart:convert';

class HtmlSafety {
  /// Escapes markup-significant characters (`& < >`) for safe placement inside
  /// an HTML element. Non-ASCII (Devanagari, em-dashes, etc.) is preserved.
  static const HtmlEscape _element = HtmlEscape(HtmlEscapeMode.element);

  /// Escapes characters significant inside a double-quoted HTML attribute
  /// (`& < > "`). Single quotes are left alone — attributes are always emitted
  /// with double quotes by the renderer.
  static const HtmlEscape _attribute = HtmlEscape(HtmlEscapeMode.attribute);

  /// Escapes text for safe placement inside an HTML element.
  static String escapeText(String value) => _element.convert(value);

  /// Escapes text for safe placement inside a double-quoted HTML attribute.
  static String escapeAttribute(String value) => _attribute.convert(value);

  /// Returns [url] unchanged when it is a safe `http(s)` URL, otherwise an
  /// empty string. The caller renders an empty result as plain text rather
  /// than a link, so an untrusted URL is never emitted as an `href`. This
  /// validates for output only — it never mutates authoritative source data.
  static String safeUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return '';
    final lower = trimmed.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return trimmed;
    }
    return '';
  }
}
