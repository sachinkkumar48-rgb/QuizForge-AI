import 'dart:io';

import '../domain/entities/pdf_print_result.dart';

/// Abstract adapter contract for dispatching native OS print commands.
abstract interface class PdfPrintAdapter {
  /// Sends the PDF at [filePath] to the host operating system's native printing pipeline.
  Future<PdfPrintResult> printPdf({
    required String filePath,
    String? documentName,
  });
}

/// Production implementation of [PdfPrintAdapter] using host OS shell/spooler processes.
class PlatformPdfPrintAdapter implements PdfPrintAdapter {
  const PlatformPdfPrintAdapter();

  @override
  Future<PdfPrintResult> printPdf({
    required String filePath,
    String? documentName,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return PdfPrintResult.failed('PDF file does not exist: $filePath');
    }

    try {
      if (Platform.isWindows) {
        // Use PowerShell Start-Process with the native Windows 'Print' shell verb
        // which opens the standard Windows print dialog / spooler for the registered PDF handler.
        final escapedPath = filePath.replaceAll("'", "''");
        final processResult = await Process.run(
          'powershell',
          [
            '-NoProfile',
            '-NonInteractive',
            '-Command',
            "Start-Process -FilePath '$escapedPath' -Verb Print",
          ],
        );

        if (processResult.exitCode == 0) {
          return const PdfPrintResult.completed();
        } else {
          final err = processResult.stderr.toString().trim();
          return PdfPrintResult.failed(
            err.isNotEmpty
                ? err
                : 'Windows printing command exited with code ${processResult.exitCode}',
          );
        }
      } else if (Platform.isMacOS) {
        // macOS standard line printer command
        final processResult = await Process.run('lpr', [filePath]);
        if (processResult.exitCode == 0) {
          return const PdfPrintResult.completed();
        } else {
          return PdfPrintResult.failed(
            processResult.stderr.toString().trim(),
          );
        }
      } else if (Platform.isLinux) {
        // Linux CUPS line printer command
        final processResult = await Process.run('lp', [filePath]);
        if (processResult.exitCode == 0) {
          return const PdfPrintResult.completed();
        } else {
          return PdfPrintResult.failed(
            processResult.stderr.toString().trim(),
          );
        }
      } else {
        return PdfPrintResult.failed(
          'Native OS printing is not supported on ${Platform.operatingSystem}',
        );
      }
    } on ProcessException catch (e) {
      return PdfPrintResult.failed(
          'Failed to start print process: ${e.message}');
    } catch (e) {
      return PdfPrintResult.failed('Unexpected printing failure: $e');
    }
  }
}

/// High-level application service managing PDF print requests for TITAN Reader.
class PrintService {
  final PdfPrintAdapter _adapter;
  final Future<bool> Function(String filePath)? _fileExists;

  const PrintService(
    this._adapter, {
    Future<bool> Function(String filePath)? fileExists,
  }) : _fileExists = fileExists;

  /// Validates and prints the document at [filePath].
  Future<PdfPrintResult> printDocument({
    required String filePath,
    String? documentTitle,
  }) async {
    if (filePath.trim().isEmpty) {
      return const PdfPrintResult.failed('Document file path cannot be empty');
    }

    final exists = _fileExists != null
        ? await _fileExists!(filePath)
        : await File(filePath).exists();
    if (!exists) {
      return PdfPrintResult.failed('Document file not found at: $filePath');
    }

    return _adapter.printPdf(
      filePath: filePath,
      documentName: documentTitle,
    );
  }
}
