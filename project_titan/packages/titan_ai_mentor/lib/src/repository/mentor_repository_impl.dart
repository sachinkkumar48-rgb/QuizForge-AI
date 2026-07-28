import 'dart:convert';

import 'package:titan_storage/titan_storage.dart';

import '../models/mentor_message.dart';
import '../models/mentor_session.dart';
import 'mentor_repository.dart';

/// Concrete implementation of [MentorRepository] providing offline-first storage.
class MentorRepositoryImpl implements MentorRepository {
  final StorageService? _storageService;
  static const StorageKey _sessionsKey =
      StorageKey('mentor_sessions', namespace: 'ai_mentor');

  final Map<String, MentorSession> _sessionsMap = {};

  MentorRepositoryImpl({StorageService? storageService})
      : _storageService = storageService;

  Future<void> _persist() async {
    if (_storageService == null) return;
    try {
      final jsonStr = jsonEncode(
          _sessionsMap.values.map((session) => session.toJson()).toList());
      await _storageService.write<String>(_sessionsKey, jsonStr);
    } catch (_) {}
  }

  Future<void> _hydrate() async {
    if (_storageService == null) return;
    try {
      final jsonStr = await _storageService.read<String>(_sessionsKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List list = jsonDecode(jsonStr) as List;
        for (final item in list) {
          final session =
              MentorSession.fromJson(Map<String, dynamic>.from(item as Map));
          _sessionsMap[session.id] = session;
        }
      }
    } catch (_) {}
  }

  @override
  Future<MentorSession> createSession({
    required String userId,
    required String title,
  }) async {
    await _hydrate();
    final session = MentorSession(
      id: 'sess_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: title,
    );
    _sessionsMap[session.id] = session;
    await _persist();
    return session;
  }

  @override
  Future<List<MentorSession>> getSessions(String userId) async {
    await _hydrate();
    return _sessionsMap.values
        .where((s) => s.userId == userId && !s.isArchived)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<MentorSession?> getSession(String sessionId) async {
    await _hydrate();
    return _sessionsMap[sessionId];
  }

  @override
  Future<void> saveSession(MentorSession session) async {
    await _hydrate();
    _sessionsMap[session.id] = session;
    await _persist();
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    await _hydrate();
    _sessionsMap.remove(sessionId);
    await _persist();
  }

  @override
  Future<void> addMessage(String sessionId, MentorMessage message) async {
    await _hydrate();
    final session = _sessionsMap[sessionId];
    if (session != null) {
      final updatedMessages = List<MentorMessage>.from(session.messages)
        ..add(message);
      _sessionsMap[sessionId] = session.copyWith(
        messages: updatedMessages,
        updatedAt: DateTime.now(),
      );
      await _persist();
    }
  }
}
