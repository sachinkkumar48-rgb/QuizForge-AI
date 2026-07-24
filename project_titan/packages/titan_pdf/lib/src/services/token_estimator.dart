/// Service estimating token counts for text without AI API calls or external tokenizers.
class TokenEstimator {
  const TokenEstimator();

  /// Estimates the number of LLM tokens for [text] using heuristic: tokens ≈ characters / 4.
  int estimateTokens(String text) {
    if (text.isEmpty) return 0;
    return (text.length / 4.0).ceil();
  }
}
