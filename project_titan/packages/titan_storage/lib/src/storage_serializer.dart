import 'storage_exception.dart';

/// Contract for serializing and deserializing generic object types for storage persistence.
abstract class StorageSerializer<T> {
  /// Converts an instance of [T] into a primitive or storable representation.
  dynamic serialize(T value);

  /// Converts a storable representation back into an instance of [T].
  T deserialize(dynamic serialized);
}

/// Default identity serializer for primitive or already-storable types.
class IdentityStorageSerializer<T> implements StorageSerializer<T> {
  const IdentityStorageSerializer();

  @override
  dynamic serialize(T value) => value;

  @override
  T deserialize(dynamic serialized) => serialized as T;
}

/// JSON map based storage serializer wrapper.
class JsonStorageSerializer<T> implements StorageSerializer<T> {
  final Map<String, dynamic> Function(T value) _toJson;
  final T Function(Map<String, dynamic> json) _fromJson;

  const JsonStorageSerializer({
    required Map<String, dynamic> Function(T value) toJson,
    required T Function(Map<String, dynamic> json) fromJson,
  })  : _toJson = toJson,
        _fromJson = fromJson;

  @override
  dynamic serialize(T value) => _toJson(value);

  @override
  T deserialize(dynamic serialized) {
    if (serialized is Map<String, dynamic>) {
      return _fromJson(serialized);
    } else if (serialized is Map) {
      return _fromJson(Map<String, dynamic>.from(serialized));
    }
    throw StorageReadException(
        'Invalid JSON payload type: ${serialized.runtimeType}');
  }
}

/// Registry mapping types [T] to their registered [StorageSerializer] instances.
class StorageSerializerRegistry {
  final Map<Type, StorageSerializer<dynamic>> _serializers = {};

  /// Registers a [serializer] for type [T].
  void register<T>(StorageSerializer<T> serializer) {
    _serializers[T] = serializer;
  }

  /// Resolves the registered [StorageSerializer] for type [T], returning null if unregistered.
  StorageSerializer<T>? get<T>() {
    return _serializers[T] as StorageSerializer<T>?;
  }

  /// Serializes [value] using a registered serializer for [T], or passes it through if unregistered.
  dynamic serialize<T>(T value) {
    final serializer = get<T>();
    if (serializer != null) {
      return serializer.serialize(value);
    }
    return value;
  }

  /// Deserializes [raw] using a registered serializer for [T], or casts it if unregistered.
  T deserialize<T>(dynamic raw) {
    final serializer = get<T>();
    if (serializer != null) {
      return serializer.deserialize(raw);
    }
    return raw as T;
  }
}
