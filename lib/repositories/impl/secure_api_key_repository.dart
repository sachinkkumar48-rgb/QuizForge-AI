import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../api_key_repository.dart';

class SecureApiKeyRepository implements ApiKeyRepository {
  final FlutterSecureStorage _storage;
  final http.Client _client;

  SecureApiKeyRepository({
    FlutterSecureStorage? storage,
    http.Client? client,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _client = client ?? http.Client();

  static const String _key = 'gemini_api_key';
  static const String _model = 'gemini-2.5-flash';

  @override
  Future<void> saveKey(String key) async {
    await _storage.write(key: _key, value: key.trim());
  }

  @override
  Future<String?> loadKey() async {
    return await _storage.read(key: _key);
  }

  @override
  Future<void> deleteKey() async {
    await _storage.delete(key: _key);
  }

  @override
  Future<bool> hasKey() async {
    final key = await loadKey();
    return key != null && key.isNotEmpty;
  }

  @override
  Future<bool> validateKey(String key) async {
    if (key.trim().isEmpty) {
      throw Exception("API key cannot be empty.");
    }

    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$key",
    );

    try {
      final response = await _client
          .post(
            url,
            headers: const {
              "Content-Type": "application/json",
            },
            body: jsonEncode({
              "contents": [
                {
                  "parts": [
                    {"text": "ping"}
                  ]
                }
              ]
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return true;
      }

      // Handle explicit API status codes
      if (response.statusCode == 400 ||
          response.statusCode == 401 ||
          response.statusCode == 403) {
        final bodyText = response.body;
        if (bodyText.contains("expired") || bodyText.contains("EXPIRED")) {
          throw Exception(
              "Gemini API Key has expired. Please update it in Settings.");
        }
        throw Exception("Invalid Gemini API Key. Please verify your key.");
      }

      if (response.statusCode == 429) {
        throw Exception(
            "Gemini API quota exceeded. Please try again later or use another API key.");
      }

      throw Exception(
          "Gemini API Error (${response.statusCode}): ${response.body}");
    } on TimeoutException {
      throw Exception(
          "Connection timed out. Please check your network and try again.");
    } on SocketException {
      throw Exception(
          "Network unavailable. Please check your internet connection.");
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      if (e.toString().contains("SocketException") ||
          e.toString().contains("ClientException")) {
        throw Exception(
            "Network unavailable. Please check your internet connection.");
      }
      throw Exception(
          "An unexpected error occurred during API key validation: $e");
    }
  }
}
