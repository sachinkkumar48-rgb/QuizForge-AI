/// Strongly typed HTTP request methods supported in Project TITAN.
enum HttpMethod {
  get,
  post,
  put,
  patch,
  delete,
  head;

  /// Uppercase string representation (e.g. "GET", "POST").
  String get nameUpperCase => name.toUpperCase();
}
