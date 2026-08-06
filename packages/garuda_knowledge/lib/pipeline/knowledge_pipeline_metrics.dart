class KnowledgePipelineMetrics {
  int registrationCount = 0;
  int successCount = 0;
  int failureCount = 0;
  int rollbackCount = 0;
  int validationFailureCount = 0;
  int duplicateCount = 0;
  double totalProcessingTimeMs = 0.0;

  double get successRate =>
      registrationCount > 0 ? (successCount / registrationCount) * 100.0 : 0.0;

  double get failureRate =>
      registrationCount > 0 ? (failureCount / registrationCount) * 100.0 : 0.0;

  double get averageProcessingTimeMs =>
      registrationCount > 0 ? totalProcessingTimeMs / registrationCount : 0.0;

  void recordSuccess(double durationMs) {
    registrationCount++;
    successCount++;
    totalProcessingTimeMs += durationMs;
  }

  void recordFailure(double durationMs, {bool isValidation = false, bool isDuplicate = false}) {
    registrationCount++;
    failureCount++;
    if (isValidation) validationFailureCount++;
    if (isDuplicate) duplicateCount++;
    totalProcessingTimeMs += durationMs;
  }

  void recordRollback() {
    rollbackCount++;
  }

  Map<String, dynamic> toJson() => {
        'registrationCount': registrationCount,
        'successCount': successCount,
        'failureCount': failureCount,
        'successRate': successRate,
        'failureRate': failureRate,
        'averageProcessingTimeMs': averageProcessingTimeMs,
        'rollbackCount': rollbackCount,
        'validationFailureCount': validationFailureCount,
        'duplicateCount': duplicateCount,
      };
}
