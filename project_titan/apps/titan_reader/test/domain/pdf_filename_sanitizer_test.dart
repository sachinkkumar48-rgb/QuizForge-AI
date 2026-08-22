import 'package:flutter_test/flutter_test.dart';
import 'package:titan_reader/src/domain/entities/pdf_filename_sanitizer.dart';

void main() {
  group('PdfFilenameSanitizer Security & Normalization Tests', () {
    test('neutralizes path traversal attacks', () {
      expect(PdfFilenameSanitizer.sanitize('../../evil.exe'), 'evil.exe');
      expect(
          PdfFilenameSanitizer.sanitize(r'..\..\malware.bat'), 'malware.bat');
      expect(PdfFilenameSanitizer.sanitize(r'C:\Windows\System32\payload.dll'),
          'payload.dll');
      expect(PdfFilenameSanitizer.sanitize('/etc/passwd'), 'passwd');
      expect(PdfFilenameSanitizer.sanitize(r'\\remote-server\share\data.zip'),
          'data.zip');
    });

    test('strips null bytes and control characters', () {
      expect(PdfFilenameSanitizer.sanitize('safe\x00file.pdf'), 'safefile.pdf');
      expect(PdfFilenameSanitizer.sanitize('doc\x1F\x07.txt'), 'doc.txt');
    });

    test('replaces illegal filesystem characters with underscores', () {
      expect(PdfFilenameSanitizer.sanitize('report:2026*final?.pdf'),
          'report_2026_final_.pdf');
      expect(PdfFilenameSanitizer.sanitize('<secret>"data"|pipe.csv'),
          '_secret__data__pipe.csv');
    });

    test('sanitizes leading and trailing dots or whitespace', () {
      expect(PdfFilenameSanitizer.sanitize('  ...hidden_file.txt...  '),
          'hidden_file.txt');
      expect(PdfFilenameSanitizer.sanitize('   '), 'attachment.bin');
      expect(PdfFilenameSanitizer.sanitize(null), 'attachment.bin');
    });

    test('renames Windows reserved device names to prevent OS freezing', () {
      expect(PdfFilenameSanitizer.sanitize('CON'), 'CON_file');
      expect(PdfFilenameSanitizer.sanitize('con.txt'), 'con_file.txt');
      expect(PdfFilenameSanitizer.sanitize('PRN.pdf'), 'PRN_file.pdf');
      expect(PdfFilenameSanitizer.sanitize('aux.png'), 'aux_file.png');
      expect(PdfFilenameSanitizer.sanitize('NUL.dat'), 'NUL_file.dat');
      expect(PdfFilenameSanitizer.sanitize('COM1.bin'), 'COM1_file.bin');
      expect(PdfFilenameSanitizer.sanitize('lpt9.log'), 'lpt9_file.log');
    });

    test('resolves safe destination path within target directory', () {
      final dest = PdfFilenameSanitizer.resolveSafeDestinationPath(
        destinationDirectoryPath: '/storage/downloads',
        desiredFilename: '../../evil.pdf',
        fileExists: (path) => false,
      );
      expect(dest, '/storage/downloads/evil.pdf');
    });

    test(
        'avoids file overwrites with incrementing counter when overwrite is false',
        () {
      final existingFiles = {
        '/storage/downloads/report.pdf',
        '/storage/downloads/report (1).pdf',
      };

      final dest = PdfFilenameSanitizer.resolveSafeDestinationPath(
        destinationDirectoryPath: '/storage/downloads',
        desiredFilename: 'report.pdf',
        overwrite: false,
        fileExists: (path) => existingFiles.contains(path),
      );

      expect(dest, '/storage/downloads/report (2).pdf');
    });

    test('allows overwrite when explicit overwrite flag is true', () {
      final existingFiles = {'/storage/downloads/report.pdf'};

      final dest = PdfFilenameSanitizer.resolveSafeDestinationPath(
        destinationDirectoryPath: '/storage/downloads',
        desiredFilename: 'report.pdf',
        overwrite: true,
        fileExists: (path) => existingFiles.contains(path),
      );

      expect(dest, '/storage/downloads/report.pdf');
    });
  });
}
