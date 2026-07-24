import 'package:flutter/foundation.dart';
import 'titan_log_entry.dart';

/// Abstract contract for output sinks consuming structured [TitanLogEntry] records.
abstract class LogSink {
  /// Writes a structured log entry to the underlying destination.
  void write(TitanLogEntry entry);
}

/// Standard console output implementation of [LogSink].
class ConsoleLogSink implements LogSink {
  final void Function(String message)? _printer;

  const ConsoleLogSink({void Function(String message)? printer})
      : _printer = printer;

  @override
  void write(TitanLogEntry entry) {
    final formatted = formatEntry(entry);
    final printer = _printer;
    if (printer != null) {
      printer(formatted);
    } else {
      debugPrint(formatted);
    }
  }

  /// Formats a [TitanLogEntry] into a clean multi-line console format.
  /// Example:
  /// 2026-08-10 11:05:31
  /// [WARNING]
  /// [Bootstrap]
  /// Configuration missing...
  String formatEntry(TitanLogEntry entry) {
    final buffer = StringBuffer();
    buffer.writeln(_formatTimestamp(entry.timestamp));
    buffer.writeln('[${entry.level.name.toUpperCase()}]');
    final tag = entry.tag;
    if (tag != null && tag.isNotEmpty) {
      buffer.writeln('[$tag]');
    }
    buffer.write(entry.message);
    if (entry.exception != null) {
      buffer.writeln();
      buffer.write('Exception: ${entry.exception}');
    }
    if (entry.stackTrace != null) {
      buffer.writeln();
      buffer.write('StackTrace: ${entry.stackTrace}');
    }
    return buffer.toString();
  }

  static String _formatTimestamp(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final ss = dt.second.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm:$ss';
  }
}
