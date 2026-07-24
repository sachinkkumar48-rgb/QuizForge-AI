import 'sync_metadata.dart';

/// Generic envelope pairing a domain payload object (or JSON map) with [SyncMetadata].
class SyncEntity<T> {
  final SyncMetadata metadata;
  final T payload;

  SyncEntity({
    required this.metadata,
    required this.payload,
  });

  factory SyncEntity.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json) fromJsonT,
  ) {
    final meta = SyncMetadata.fromJson(
      Map<String, dynamic>.from(json['metadata'] as Map),
    );
    final payloadObj = fromJsonT(
      Map<String, dynamic>.from(json['payload'] as Map),
    );
    return SyncEntity<T>(
      metadata: meta,
      payload: payloadObj,
    );
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T obj) toJsonT) {
    return {
      'metadata': metadata.toJson(),
      'payload': toJsonT(payload),
    };
  }
}
