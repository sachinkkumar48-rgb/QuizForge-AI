import 'package:meta/meta.dart';

/// Immutable domain model summarizing the execution results of a sync operation.
@immutable
class SyncResult {
  final bool isSuccess;
  final int itemsProcessed;
  final int itemsFailed;
  final int conflictsDetected;
  final DateTime completedAt;
  final String? errorMessage;

  const SyncResult({
    required this.isSuccess,
    required this.itemsProcessed,
    this.itemsFailed = 0,
    this.conflictsDetected = 0,
    required this.completedAt,
    this.errorMessage,
  });

  factory SyncResult.empty() => SyncResult(
        isSuccess: true,
        itemsProcessed: 0,
        completedAt: DateTime.now(),
      );

  SyncResult copyWith({
    bool? isSuccess,
    int? itemsProcessed,
    int? itemsFailed,
    int? conflictsDetected,
    DateTime? completedAt,
    String? errorMessage,
  }) {
    return SyncResult(
      isSuccess: isSuccess ?? this.isSuccess,
      itemsProcessed: itemsProcessed ?? this.itemsProcessed,
      itemsFailed: itemsFailed ?? this.itemsFailed,
      conflictsDetected: conflictsDetected ?? this.conflictsDetected,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toJson() => {
        'isSuccess': isSuccess,
        'itemsProcessed': itemsProcessed,
        'itemsFailed': itemsFailed,
        'conflictsDetected': conflictsDetected,
        'completedAt': completedAt.toIso8601String(),
        'errorMessage': errorMessage,
      };

  factory SyncResult.fromJson(Map<String, dynamic> json) => SyncResult(
        isSuccess: json['isSuccess'] as bool? ?? false,
        itemsProcessed: json['itemsProcessed'] as int? ?? 0,
        itemsFailed: json['itemsFailed'] as int? ?? 0,
        conflictsDetected: json['conflictsDetected'] as int? ?? 0,
        completedAt: DateTime.parse(json['completedAt'] as String),
        errorMessage: json['errorMessage'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncResult &&
          runtimeType == other.runtimeType &&
          isSuccess == other.isSuccess &&
          itemsProcessed == other.itemsProcessed &&
          itemsFailed == other.itemsFailed &&
          conflictsDetected == other.conflictsDetected &&
          completedAt == other.completedAt &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(
        isSuccess,
        itemsProcessed,
        itemsFailed,
        conflictsDetected,
        completedAt,
        errorMessage,
      );
}
