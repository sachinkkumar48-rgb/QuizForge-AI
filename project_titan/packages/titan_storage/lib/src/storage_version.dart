import 'package:meta/meta.dart';

/// Represents storage schema version metadata for Project TITAN.
@immutable
class StorageVersion implements Comparable<StorageVersion> {
  final int major;
  final int minor;
  final int patch;

  const StorageVersion(this.major, this.minor, this.patch);

  /// Current system storage schema version (1.0.0).
  static const StorageVersion current = StorageVersion(1, 0, 0);

  /// Formatted semver string (e.g. "1.0.0").
  String get versionString => '$major.$minor.$patch';

  @override
  int compareTo(StorageVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  bool operator >=(StorageVersion other) => compareTo(other) >= 0;
  bool operator <=(StorageVersion other) => compareTo(other) <= 0;
  bool operator >(StorageVersion other) => compareTo(other) > 0;
  bool operator <(StorageVersion other) => compareTo(other) < 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StorageVersion &&
          runtimeType == other.runtimeType &&
          major == other.major &&
          minor == other.minor &&
          patch == other.patch;

  @override
  int get hashCode => major.hashCode ^ minor.hashCode ^ patch.hashCode;

  @override
  String toString() => versionString;
}
