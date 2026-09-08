/// Sync Envelope Domain Entity (TITAN-KO-047.0 P47).
///
/// Encapsulates a synchronizable payload with tenant identity, monotonic revision,
/// client device coordinates, and cryptographic checksum for tampering/corruption protection.
library;

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';

import 'sync_status.dart';

/// Immutable container wrapping synchronizable learner data for durable local outbox
/// queuing and remote transport.
@immutable
class SyncEnvelope {
  /// Unique synchronization record identifier.
  final String syncId;

  /// Target learner identifier.
  final String learnerId;

  /// Target examination identifier.
  final String examId;

  /// Monotonic revision sequence number of the encapsulated state (>= 1).
  final int revision;

  /// Client or device origin identifier (e.g. 'device_mobile_a', 'device_web_b').
  final String deviceId;

  /// UTC timestamp when this envelope was created.
  final DateTime createdAt;

  /// UTC timestamp when this envelope was last modified or processed.
  final DateTime updatedAt;

  /// Current synchronization lifecycle status.
  final SyncStatus status;

  /// SHA-256 cryptographic checksum over the canonical payload JSON.
  final String checksum;

  /// Encapsulated payload JSON map (e.g. serialized AuthoritativeLearnerState).
  final Map<String, dynamic> payload;

  /// Optional error message from a failed sync attempt.
  final String? errorMessage;

  /// Number of sync attempts performed.
  final int retryCount;

  SyncEnvelope({
    required String syncId,
    required String learnerId,
    required String examId,
    required this.revision,
    required String deviceId,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.status = SyncStatus.pendingSync,
    String? checksum,
    required Map<String, dynamic> payload,
    this.errorMessage,
    this.retryCount = 0,
  })  : syncId = syncId.trim(),
        learnerId = learnerId.trim(),
        examId = examId.trim().toLowerCase(),
        deviceId = deviceId.trim(),
        createdAt = createdAt ?? DateTime.now().toUtc(),
        updatedAt = updatedAt ?? DateTime.now().toUtc(),
        payload = Map<String, dynamic>.unmodifiable(payload),
        checksum = checksum ?? computeChecksum(payload) {
    if (this.syncId.isEmpty) throw ArgumentError('syncId cannot be empty');
    if (this.learnerId.isEmpty)
      throw ArgumentError('learnerId cannot be empty');
    if (this.examId.isEmpty) throw ArgumentError('examId cannot be empty');
    if (this.deviceId.isEmpty) throw ArgumentError('deviceId cannot be empty');
    if (revision < 1)
      throw ArgumentError('revision must be >= 1 (got $revision)');
    if (retryCount < 0) throw ArgumentError('retryCount cannot be negative');
    if (this.checksum.isEmpty) throw ArgumentError('checksum cannot be empty');
  }

  /// Computes a deterministic SHA-256 digest over the canonical JSON representation of [payload].
  static String computeChecksum(Map<String, dynamic> payload) {
    // Sort keys deterministically for canonical digest
    final sortedKeys = payload.keys.toList()..sort();
    final canonicalMap = <String, dynamic>{};
    for (final key in sortedKeys) {
      canonicalMap[key] = payload[key];
    }
    final jsonStr = jsonEncode(canonicalMap);
    final bytes = utf8.encode(jsonStr);
    return sha256.convert(bytes).toString();
  }

  /// Verifies whether the stored checksum matches the actual payload digest.
  bool verifyChecksum() {
    return checksum == computeChecksum(payload);
  }

  SyncEnvelope copyWith({
    String? syncId,
    String? learnerId,
    String? examId,
    int? revision,
    String? deviceId,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? status,
    String? checksum,
    Map<String, dynamic>? payload,
    String? errorMessage,
    int? retryCount,
  }) {
    return SyncEnvelope(
      syncId: syncId ?? this.syncId,
      learnerId: learnerId ?? this.learnerId,
      examId: examId ?? this.examId,
      revision: revision ?? this.revision,
      deviceId: deviceId ?? this.deviceId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      checksum: checksum ?? this.checksum,
      payload: payload ?? this.payload,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'syncId': syncId,
        'learnerId': learnerId,
        'examId': examId,
        'revision': revision,
        'deviceId': deviceId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'status': status.name,
        'checksum': checksum,
        'payload': payload,
        'errorMessage': errorMessage,
        'retryCount': retryCount,
      };

  factory SyncEnvelope.fromJson(Map<String, dynamic> json) {
    return SyncEnvelope(
      syncId: json['syncId'] as String,
      learnerId: json['learnerId'] as String,
      examId: json['examId'] as String,
      revision: json['revision'] as int,
      deviceId: json['deviceId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
      updatedAt: DateTime.parse(json['updatedAt'] as String).toUtc(),
      status: SyncStatus.values.byName(json['status'] as String),
      checksum: json['checksum'] as String,
      payload: Map<String, dynamic>.from(json['payload'] as Map),
      errorMessage: json['errorMessage'] as String?,
      retryCount: json['retryCount'] as int? ?? 0,
    );
  }
}
