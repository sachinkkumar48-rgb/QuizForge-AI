import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../domain/entities/grammar_issue.dart';
import '../domain/grammar_errors.dart';

/// HTTP response tuple returned by the injectable fetch function.
class RemoteGrammarHttpResponse {
  final int statusCode;
  final String body;

  const RemoteGrammarHttpResponse(this.statusCode, this.body);
}

/// Signature of the transport used by remote grammar sources; injectable
/// so tests never touch the network. Receives the target URI and the
/// urlencoded form body.
typedef RemoteGrammarFetch = Future<RemoteGrammarHttpResponse> Function(
    Uri uri, String body);

/// Contract for optional online grammar engines.
///
/// Remote engines are consulted only when the user has enabled them and
/// only after the local engine has run. They must transmit the checked
/// text itself and nothing else — never the PDF, document metadata, notes
/// or vocabulary.
abstract class RemoteGrammarSource {
  /// Stable identifier recorded on cached results.
  String get sourceId;

  /// Checks [text] and returns the issues reported by the remote engine.
  ///
  /// Throws [GrammarRemoteException] on transport failures and
  /// [GrammarRemoteParseException] on malformed responses.
  Future<List<GrammarIssue>> check(String text, {String language = 'en'});
}

/// Remote source backed by the free public LanguageTool HTTP API
/// (`https://api.languagetool.org/v2/check`).
///
/// LanguageTool itself is LGPL-2.1 Java software; embedding its JVM is not
/// feasible on Android and would bloat the Windows app, so it is offered
/// only as this opt-in HTTP fallback. Privacy: the POST body carries only
/// the checked text and the language code.
class LanguageToolApiSource implements RemoteGrammarSource {
  LanguageToolApiSource({
    RemoteGrammarFetch? fetch,
    this.baseUrl = 'https://api.languagetool.org/v2/check',
    this.timeout = const Duration(seconds: 15),
  }) : _fetch = fetch ?? _defaultFetch;

  /// Source identifier stored with cached results.
  static const String id = 'remote:languagetool.org';

  final String baseUrl;
  final Duration timeout;
  final RemoteGrammarFetch _fetch;

  static const Duration _defaultTimeout = Duration(seconds: 15);

  static Future<RemoteGrammarHttpResponse> _defaultFetch(
      Uri uri, String body) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(uri).timeout(_defaultTimeout);
      request.headers.contentType = ContentType(
        'application',
        'x-www-form-urlencoded',
        charset: 'utf-8',
      );
      request.write(body);
      final response = await request.close().timeout(_defaultTimeout);
      final payload = await response
          .transform(utf8.decoder)
          .join()
          .timeout(_defaultTimeout);
      return RemoteGrammarHttpResponse(response.statusCode, payload);
    } on TimeoutException catch (error) {
      throw GrammarRemoteException('Remote grammar check timed out.', error);
    } on SocketException catch (error) {
      throw GrammarRemoteException(
          'Remote grammar engine is unreachable.', error);
    } on HttpException catch (error) {
      throw GrammarRemoteException('Remote grammar request failed.', error);
    } finally {
      client.close(force: true);
    }
  }

  @override
  String get sourceId => id;

  @override
  Future<List<GrammarIssue>> check(String text,
      {String language = 'en'}) async {
    if (text.trim().isEmpty) return const [];
    final uri = Uri.parse(baseUrl);
    final body = 'text=${Uri.encodeQueryComponent(text)}'
        '&language=${Uri.encodeQueryComponent(language)}';
    final response = await _fetch(uri, body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GrammarRemoteException(
          'Remote grammar engine returned status ${response.statusCode}.');
    }
    try {
      return _parse(text, response.body);
    } on FormatException catch (error) {
      throw GrammarRemoteParseException(
          'Remote grammar response could not be parsed.', error);
    }
  }

  List<GrammarIssue> _parse(String text, String payload) {
    final decoded = jsonDecode(payload);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Expected a JSON object.');
    }
    final matches = decoded['matches'];
    if (matches is! List) {
      throw const FormatException('Expected a matches array.');
    }
    final issues = <GrammarIssue>[];
    for (final match in matches.whereType<Map<String, Object?>>()) {
      final issue = _parseMatch(text, match);
      if (issue != null) issues.add(issue);
    }
    issues.sort((a, b) {
      final byStart = a.startOffset.compareTo(b.startOffset);
      if (byStart != 0) return byStart;
      return a.endOffset.compareTo(b.endOffset);
    });
    return List.unmodifiable(issues);
  }

  GrammarIssue? _parseMatch(String text, Map<String, Object?> match) {
    final offset = match['offset'];
    final length = match['length'];
    final message = match['message'];
    if (offset is! int || length is! int || message is! String) return null;
    if (offset < 0 || length < 0) return null;
    final start = offset > text.length ? text.length : offset;
    final end = (offset + length) > text.length ? text.length : offset + length;

    final suggestions = <GrammarSuggestion>[];
    final replacements = match['replacements'];
    if (replacements is List) {
      for (final item in replacements.whereType<Map<String, Object?>>()) {
        final value = item['value'];
        if (value is String) {
          suggestions.add(GrammarSuggestion(replacement: value));
        }
      }
    }

    final rule = match['rule'];
    final ruleId = rule is Map<String, Object?> && rule['id'] is String
        ? rule['id'] as String
        : 'remote.languagetool';
    final issueType =
        rule is Map<String, Object?> ? rule['issueType'] as String? : null;
    final description =
        rule is Map<String, Object?> ? rule['description'] as String? : null;

    return GrammarIssue(
      ruleId: 'languagetool:$ruleId',
      type: _typeFor(issueType),
      // The public API does not expose severity/confidence; a uniform
      // warning is the only honest mapping (§7).
      severity: GrammarIssueSeverity.warning,
      message: message,
      explanation: description,
      startOffset: start,
      endOffset: end,
      originalText: text.substring(start, end),
      suggestions: List.unmodifiable(suggestions),
      source: GrammarIssueSource.remote,
    );
  }

  static GrammarIssueType _typeFor(String? issueType) {
    switch (issueType) {
      case 'misspelling':
        return GrammarIssueType.spelling;
      case 'grammar':
        return GrammarIssueType.grammar;
      case 'typographical':
        return GrammarIssueType.typographical;
      case 'punctuation':
        return GrammarIssueType.punctuation;
      case 'style':
      case 'wordiness':
      case 'redundancy':
      case 'confusedWords':
        return GrammarIssueType.style;
      default:
        return GrammarIssueType.grammar;
    }
  }
}
