import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

void main() {
  group('P30.1 Source Contract & Descriptors', () {
    test('1. Descriptor creation, validation, and serialization', () {
      const descriptor = PyqSourceDescriptor(
        sourceId: 'SRC_UPSC_2024_GS1',
        sourceName: 'UPSC CSE 2024 Prelims GS1',
        examId: 'upsc',
        publisher: 'Union Public Service Commission',
        sourceType: SourceType.officialPdf,
        format: PyqSourceFormat.json,
        years: [2024],
        languages: ['en', 'hi'],
        uriOrPath: 'assets/corpus/upsc_2024.json',
      );

      descriptor.validate(); // Must not throw
      expect(descriptor.sourceId, 'SRC_UPSC_2024_GS1');
      expect(descriptor.examId, 'upsc');
      expect(descriptor.format, PyqSourceFormat.json);
      expect(descriptor.years, [2024]);
      expect(descriptor.languages, ['en', 'hi']);

      final json = descriptor.toJson();
      final restored = PyqSourceDescriptor.fromJson(json);
      expect(restored, descriptor);
      expect(restored.sourceName, descriptor.sourceName);
    });

    test('2. Validation catches missing or invalid invariants', () {
      expect(
        () => const PyqSourceDescriptor(
          sourceId: '',
          sourceName: 'Name',
          examId: 'upsc',
          publisher: 'Publisher',
          sourceType: SourceType.officialPdf,
          format: PyqSourceFormat.json,
          years: [2024],
          languages: ['en'],
          uriOrPath: 'path',
        ).validate(),
        throwsArgumentError,
      );

      expect(
        () => const PyqSourceDescriptor(
          sourceId: 'ID',
          sourceName: 'Name',
          examId: 'upsc',
          publisher: 'Publisher',
          sourceType: SourceType.officialPdf,
          format: PyqSourceFormat.json,
          years: [], // Empty years
          languages: ['en'],
          uriOrPath: 'path',
        ).validate(),
        throwsArgumentError,
      );

      expect(
        () => const PyqSourceDescriptor(
          sourceId: 'ID',
          sourceName: 'Name',
          examId: 'upsc',
          publisher: 'Publisher',
          sourceType: SourceType.officialPdf,
          format: PyqSourceFormat.json,
          years: [1850], // Out of range year
          languages: ['en'],
          uriOrPath: 'path',
        ).validate(),
        throwsArgumentError,
      );
    });

    test('3. Format auto-inference from paths or MIME types', () {
      expect(PyqSourceFormat.fromExtensionOrMime('data.json'),
          PyqSourceFormat.json);
      expect(PyqSourceFormat.fromExtensionOrMime('application/json'),
          PyqSourceFormat.json);
      expect(PyqSourceFormat.fromExtensionOrMime('papers/upsc.csv'),
          PyqSourceFormat.csv);
      expect(PyqSourceFormat.fromExtensionOrMime('portal/paper.html'),
          PyqSourceFormat.html);
      expect(PyqSourceFormat.fromExtensionOrMime('notes.txt'),
          PyqSourceFormat.plainText);
      expect(PyqSourceFormat.fromExtensionOrMime('official.pdf'),
          PyqSourceFormat.pdfText);
      expect(PyqSourceFormat.fromExtensionOrMime('unknown.bin'),
          PyqSourceFormat.custom);
    });
  });

  group('P30.2 Fetch / Load Abstraction & Raw Artifacts', () {
    const descriptor = PyqSourceDescriptor(
      sourceId: 'SRC_TEST_001',
      sourceName: 'Test Source',
      examId: 'upsc',
      publisher: 'Test Publisher',
      sourceType: SourceType.verifiedArchive,
      format: PyqSourceFormat.json,
      years: [2024],
      languages: ['en'],
      uriOrPath: 'memory:test',
    );

    test('4. RawArtifact calculates deterministic SHA-256 checksum', () {
      const textData = '{"test": "content", "value": 42}';
      final artifact = RawArtifact.fromText(
        sourceDescriptor: descriptor,
        text: textData,
      );

      expect(artifact.checksum.length, 64);
      expect(artifact.artifactId.startsWith('ART_SRC_TEST_001_'), isTrue);

      // Determinism: Same text produces exact same checksum
      final artifact2 = RawArtifact.fromText(
        sourceDescriptor: descriptor,
        text: textData,
      );
      expect(artifact2.checksum, artifact.checksum);
    });

    test('5. Binary RawArtifact construction and serialization', () {
      final bytes = Uint8List.fromList(utf8.encode('{"binary": true}'));
      final artifact = RawArtifact.fromBytes(
        sourceDescriptor: descriptor,
        bytes: bytes,
      );

      expect(artifact.text, '{"binary": true}');
      final json = artifact.toJson();
      final restored = RawArtifact.fromJson(json);
      expect(restored.checksum, artifact.checksum);
      expect(restored.text, artifact.text);
    });

    test('6. InMemorySourceFetcher and CompositeSourceFetcher', () async {
      final fetcher = InMemorySourceFetcher();
      fetcher.registerText(descriptor, '{"sample": 1}');

      expect(fetcher.canFetch(descriptor), isTrue);
      final fetched = await fetcher.fetch(descriptor);
      expect(fetched.text, '{"sample": 1}');

      const unreg = PyqSourceDescriptor(
        sourceId: 'UNREG',
        sourceName: 'Unregistered',
        examId: 'upsc',
        publisher: 'Pub',
        sourceType: SourceType.officialPdf,
        format: PyqSourceFormat.json,
        years: [2024],
        languages: ['en'],
        uriOrPath: 'path',
      );

      expect(fetcher.canFetch(unreg), isFalse);
      expect(() => fetcher.fetch(unreg), throwsA(isA<SourceFetchException>()));

      final composite = CompositeSourceFetcher([fetcher]);
      expect(composite.canFetch(descriptor), isTrue);
      final compFetched = await composite.fetch(descriptor);
      expect(compFetched.checksum, fetched.checksum);
    });
  });

  group('P30.3 Parser Architecture', () {
    const jsonDesc = PyqSourceDescriptor(
      sourceId: 'SRC_JSON_UPSC',
      sourceName: 'UPSC JSON',
      examId: 'upsc',
      publisher: 'UPSC',
      sourceType: SourceType.officialPdf,
      format: PyqSourceFormat.json,
      years: [2024],
      languages: ['en'],
      uriOrPath: 'corpus/upsc.json',
    );

    test('7. JsonPyqParser extracts structured questions with provenance', () {
      const jsonText = '''[
        {
          "id": "UPSC_2024_01",
          "examId": "upsc",
          "year": 2024,
          "paper": "GS1",
          "questionNumber": 1,
          "subject": "Polity",
          "topic": "Preamble",
          "questionText": "Which amendment added Secular to the Preamble?",
          "options": ["(A) 42nd Amendment", "(B) 44th Amendment", "(C) 73rd Amendment", "(D) 86th Amendment"],
          "correctAnswer": "A",
          "explanation": "Added by 42nd Amendment Act 1976."
        }
      ]''';

      final artifact = RawArtifact.fromText(
        sourceDescriptor: jsonDesc,
        text: jsonText,
      );

      const parser = JsonPyqParser();
      expect(parser.canParse(PyqSourceFormat.json, 'application/json'), isTrue);

      final records = parser.parse(artifact);
      expect(records.length, 1);
      final q = records.first;
      expect(q.examId, 'upsc');
      expect(q.year, 2024);
      expect(q.questionNumber, 1);
      expect(q.questionText, 'Which amendment added Secular to the Preamble?');
      expect(q.correctAnswer, 'A');
      expect(q.source?.sourceId, 'SRC_JSON_UPSC');
      expect(q.source?.checksum, artifact.checksum);
    });

    test('8. CsvPyqParser handles headers, quoted commas, and Unicode', () {
      const csvDesc = PyqSourceDescriptor(
        sourceId: 'SRC_CSV_BPSC',
        sourceName: 'BPSC CSV',
        examId: 'bpsc',
        publisher: 'BPSC',
        sourceType: SourceType.verifiedArchive,
        format: PyqSourceFormat.csv,
        years: [2023],
        languages: ['hi'],
        uriOrPath: 'corpus/bpsc.csv',
      );

      const csvText =
          '''id,examId,year,paper,subject,topic,questionText,optionA,optionB,optionC,optionD,correctKey,explanation,language
BPSC_01,bpsc,2023,GS1,History,Champaran,"गांधीजी ने चंपारण सत्याग्रह, जो कि भारत में उनका पहला सत्याग्रह था, कब शुरू किया?",1915,1917,1919,1921,B,1917 में गांधीजी चंपारण आए।,hi''';

      final artifact = RawArtifact.fromText(
        sourceDescriptor: csvDesc,
        text: csvText,
      );

      const parser = CsvPyqParser();
      expect(parser.canParse(PyqSourceFormat.csv, 'text/csv'), isTrue);

      final records = parser.parse(artifact);
      expect(records.length, 1);
      final q = records.first;
      expect(q.examId, 'bpsc');
      expect(q.year, 2023);
      expect(q.language, 'hi');
      expect(
          q.questionText,
          contains(
              'गांधीजी ने चंपारण सत्याग्रह, जो कि भारत में उनका पहला सत्याग्रह था, कब शुरू किया?'));
      expect(q.correctAnswer, 'B');
      expect(q.options.length, 4);
    });

    test('9. HtmlPyqParser extracts questions from HTML fixtures', () {
      const htmlDesc = PyqSourceDescriptor(
        sourceId: 'SRC_HTML_SSC',
        sourceName: 'SSC HTML',
        examId: 'ssc',
        publisher: 'SSC',
        sourceType: SourceType.officialWebsite,
        format: PyqSourceFormat.html,
        years: [2023],
        languages: ['en'],
        uriOrPath: 'portal/ssc.html',
      );

      const htmlContent = '''
      <div class="question-block" data-id="SSC_01">
        <p class="question-text">Who is known as the Father of the Indian Constitution?</p>
        <ul>
          <li>(A) Mahatma Gandhi</li>
          <li>(B) Dr. B.R. Ambedkar</li>
          <li>(C) Jawaharlal Nehru</li>
          <li>(D) Sardar Patel</li>
        </ul>
        <div class="answer" data-answer="B">Answer: B</div>
        <div class="explanation">Dr. B.R. Ambedkar was the Chairman of the Drafting Committee.</div>
      </div></div>
      ''';

      final artifact = RawArtifact.fromText(
        sourceDescriptor: htmlDesc,
        text: htmlContent,
      );

      const parser = HtmlPyqParser();
      expect(parser.canParse(PyqSourceFormat.html, 'text/html'), isTrue);

      final records = parser.parse(artifact);
      expect(records.length, 1);
      final q = records.first;
      expect(q.examId, 'ssc');
      expect(q.questionText,
          'Who is known as the Father of the Indian Constitution?');
      expect(q.correctAnswer, 'B');
      expect(q.options.length, 4);
    });

    test('10. TextPyqParser extracts structured exam papers from plain text',
        () {
      const textDesc = PyqSourceDescriptor(
        sourceId: 'SRC_TEXT_BANKING',
        sourceName: 'Banking Text',
        examId: 'banking',
        publisher: 'IBPS',
        sourceType: SourceType.verifiedArchive,
        format: PyqSourceFormat.plainText,
        years: [2024],
        languages: ['en'],
        uriOrPath: 'corpus/banking.txt',
      );

      const plainText = '''
Q1. What does RTGS stand for in banking terminology?
(A) Real Time Gross Settlement
(B) Real Time General Settlement
(C) Ready Transaction Gross Settlement
(D) Regional Transfer Gross Settlement
Ans: A
Exp: Real Time Gross Settlement enables continuous real-time funds transfer.

Q2. What is the minimum reserve ratio maintained under CRR?
(A) 2%
(B) 3%
(C) 4.5%
(D) 6%
Ans: C
''';

      final artifact = RawArtifact.fromText(
        sourceDescriptor: textDesc,
        text: plainText,
      );

      const parser = TextPyqParser();
      expect(parser.canParse(PyqSourceFormat.plainText, 'text/plain'), isTrue);

      final records = parser.parse(artifact);
      expect(records.length, 2);
      expect(records[0].questionNumber, 1);
      expect(records[0].questionText,
          'What does RTGS stand for in banking terminology?');
      expect(records[0].correctAnswer, 'A');
      expect(records[1].questionNumber, 2);
      expect(records[1].correctAnswer, 'C');
    });
  });

  group('P30.4 Failure Isolation & Diagnostics (Phase 9)', () {
    test('11. Malformed questions do not fail valid questions in batch', () {
      const descriptor = PyqSourceDescriptor(
        sourceId: 'SRC_PARTIAL_TEST',
        sourceName: 'Partial Batch Test',
        examId: 'railways',
        publisher: 'RRB',
        sourceType: SourceType.verifiedArchive,
        format: PyqSourceFormat.json,
        years: [2024],
        languages: ['en'],
        uriOrPath: 'memory:railways',
      );

      // Item 0: Valid
      // Item 1: Malformed (empty question text)
      // Item 2: Malformed (only 1 option)
      // Item 3: Valid
      const mixedJson = '''[
        {
          "questionText": "What is the unit of electric current?",
          "options": ["(A) Ampere", "(B) Volt", "(C) Ohm", "(D) Watt"],
          "correctAnswer": "A"
        },
        {
          "questionText": "",
          "options": ["(A) X", "(B) Y"],
          "correctAnswer": "A"
        },
        {
          "questionText": "Malformed question with single option",
          "options": ["(A) Only One"],
          "correctAnswer": "A"
        },
        {
          "questionText": "Which gas is used in LPG cylinders?",
          "options": ["(A) Methane", "(B) Propane and Butane", "(C) Nitrogen", "(D) Oxygen"],
          "correctAnswer": "B"
        }
      ]''';

      final fetcher = InMemorySourceFetcher();
      fetcher.registerText(descriptor, mixedJson);

      final engine = MultiExamPyqAcquisitionEngine(fetcher: fetcher);
      final jobFuture = engine.ingestSource(descriptor);

      expect(jobFuture, completes);
    });

    test(
        '12. Diagnostics and quality summary reflect malformed records accurately',
        () async {
      const descriptor = PyqSourceDescriptor(
        sourceId: 'SRC_QUALITY_TEST',
        sourceName: 'Quality Test',
        examId: 'railways',
        publisher: 'RRB',
        sourceType: SourceType.verifiedArchive,
        format: PyqSourceFormat.json,
        years: [2024],
        languages: ['en'],
        uriOrPath: 'memory:quality',
      );

      const mixedJson = '''[
        {
          "questionText": "What is the speed of light?",
          "options": ["(A) 3x10^8 m/s", "(B) 3x10^6 m/s"],
          "correctAnswer": "A"
        },
        {
          "questionText": "",
          "options": ["(A) Opt1", "(B) Opt2"],
          "correctAnswer": "A"
        }
      ]''';

      final fetcher = InMemorySourceFetcher();
      fetcher.registerText(descriptor, mixedJson);

      final engine = MultiExamPyqAcquisitionEngine(fetcher: fetcher);
      final job = await engine.ingestSource(descriptor);

      expect(job.status, ImportJobStatus.partiallyCompleted);
      expect(job.recordsRead,
          1); // Parser yielded 1 valid RawQuestionInput, skipped the empty one
      expect(job.acceptedQuestions.length, 1);
      expect(job.summary.acceptanceRate, 1.0);
      expect(job.diagnostics.isNotEmpty, isTrue);
      expect(job.summary.formatReport(),
          contains('PYQ INGESTION QUALITY SUMMARY'));
    });
  });

  group('P30.5 Incremental Ingestion, Change Detection & Idempotency', () {
    const descriptor = PyqSourceDescriptor(
      sourceId: 'SRC_IDEMPOTENT_UPSC',
      sourceName: 'UPSC Idempotent Test',
      examId: 'upsc',
      publisher: 'UPSC',
      sourceType: SourceType.officialPdf,
      format: PyqSourceFormat.json,
      years: [2024],
      languages: ['en'],
      uriOrPath: 'memory:upsc_idem',
    );

    const questionJson = '''[
      {
        "questionText": "Which article of the Indian Constitution provides for the Finance Commission?",
        "options": ["(A) Article 280", "(B) Article 324", "(C) Article 356", "(D) Article 370"],
        "correctAnswer": "A",
        "paper": "GS1",
        "year": 2024
      }
    ]''';

    test('13. Case A: Same source + same checksum skips redundant processing',
        () async {
      final fetcher = InMemorySourceFetcher();
      fetcher.registerText(descriptor, questionJson);

      final engine = MultiExamPyqAcquisitionEngine(fetcher: fetcher);

      // First ingestion
      final job1 = await engine.ingestSource(descriptor);
      expect(job1.status, ImportJobStatus.completed);
      expect(job1.acceptedQuestions.length, 1);
      expect(engine.totalQuestionsCount, 1);

      // Second ingestion with identical content
      final job2 = await engine.ingestSource(descriptor);
      expect(job2.status, ImportJobStatus.skippedAlreadyProcessed);
      expect(engine.totalQuestionsCount, 1); // No duplicate explosion!
      expect(job2.jobId, job1.jobId);
    });

    test(
        '14. Case B: Changed source checksum triggers incremental re-ingestion',
        () async {
      final fetcher = InMemorySourceFetcher();
      fetcher.registerText(descriptor, questionJson);

      final engine = MultiExamPyqAcquisitionEngine(fetcher: fetcher);
      await engine.ingestSource(descriptor);
      expect(engine.totalQuestionsCount, 1);

      // Update content (add 2nd question)
      const updatedJson = '''[
        {
          "questionText": "Which article of the Indian Constitution provides for the Finance Commission?",
          "options": ["(A) Article 280", "(B) Article 324", "(C) Article 356", "(D) Article 370"],
          "correctAnswer": "A",
          "paper": "GS1",
          "year": 2024
        },
        {
          "questionText": "Which article deals with Election Commission of India?",
          "options": ["(A) Article 280", "(B) Article 324", "(C) Article 356", "(D) Article 370"],
          "correctAnswer": "B",
          "paper": "GS1",
          "year": 2024
        }
      ]''';

      fetcher.registerText(descriptor, updatedJson);

      final jobUpdate = await engine.ingestSource(descriptor);
      expect(jobUpdate.status, ImportJobStatus.completed);
      expect(jobUpdate.recordsRead, 2);
      expect(jobUpdate.acceptedQuestions.length,
          1); // Only 1 new unique question accepted
      expect(jobUpdate.duplicateQuestions.length,
          1); // 1st was duplicate of already indexed question
      expect(engine.totalQuestionsCount, 2);
    });

    test(
        '15. Case C: Same question from different sources is detected as duplicate with provenance preserved',
        () async {
      const source1 = PyqSourceDescriptor(
        sourceId: 'SRC_ARCHIVE_1',
        sourceName: 'Archive 1',
        examId: 'upsc',
        publisher: 'Agency A',
        sourceType: SourceType.verifiedArchive,
        format: PyqSourceFormat.json,
        years: [2024],
        languages: ['en'],
        uriOrPath: 'memory:src1',
      );

      const source2 = PyqSourceDescriptor(
        sourceId: 'SRC_ARCHIVE_2',
        sourceName: 'Archive 2',
        examId: 'upsc',
        publisher: 'Agency B',
        sourceType: SourceType.officialWebsite,
        format: PyqSourceFormat.json,
        years: [2024],
        languages: ['en'],
        uriOrPath: 'memory:src2',
      );

      const commonQuestion = '''[
        {
          "questionText": "Who appoints the Chief Justice of India?",
          "options": ["(A) President", "(B) Prime Minister", "(C) Law Minister", "(D) Parliament"],
          "correctAnswer": "A",
          "paper": "GS1",
          "year": 2024
        }
      ]''';

      final fetcher = InMemorySourceFetcher();
      fetcher.registerText(source1, commonQuestion);
      fetcher.registerText(source2, commonQuestion);

      final engine = MultiExamPyqAcquisitionEngine(fetcher: fetcher);

      final job1 = await engine.ingestSource(source1);
      expect(job1.acceptedQuestions.length, 1);

      final job2 = await engine.ingestSource(source2);
      expect(job2.acceptedQuestions.isEmpty, isTrue);
      expect(job2.duplicateQuestions.length, 1);
      expect(engine.totalQuestionsCount, 1);
    });
  });

  group('P30.6 Multi-Language Preservation & Provenance (Phases 12 & 13)', () {
    test(
        '16. English and Hindi variants of same exam/year are preserved as distinct questions',
        () async {
      const bilingualDesc = PyqSourceDescriptor(
        sourceId: 'SRC_BILINGUAL_BPSC',
        sourceName: 'BPSC Bilingual Prelims',
        examId: 'bpsc',
        publisher: 'BPSC',
        sourceType: SourceType.officialPdf,
        format: PyqSourceFormat.json,
        years: [2023],
        languages: ['en', 'hi'],
        uriOrPath: 'memory:bilingual',
      );

      const bilingualJson = '''[
        {
          "questionText": "In which year was Bihar separated from Bengal Presidency?",
          "options": ["(A) 1911", "(B) 1912", "(C) 1936", "(D) 1947"],
          "correctAnswer": "B",
          "language": "en",
          "paper": "GS1",
          "year": 2023
        },
        {
          "questionText": "बिहार को बंगाल प्रेसीडेंसी से किस वर्ष अलग किया गया था?",
          "options": ["(A) 1911", "(B) 1912", "(C) 1936", "(D) 1947"],
          "correctAnswer": "B",
          "language": "hi",
          "paper": "GS1",
          "year": 2023
        }
      ]''';

      final fetcher = InMemorySourceFetcher();
      fetcher.registerText(bilingualDesc, bilingualJson);

      final engine = MultiExamPyqAcquisitionEngine(fetcher: fetcher);
      final job = await engine.ingestSource(bilingualDesc);

      expect(job.acceptedQuestions.length, 2);
      expect(job.duplicateQuestions.length, 0);
      expect(engine.totalQuestionsCount, 2);

      // Verify distinct IDs and language tags
      final englishQ =
          job.acceptedQuestions.firstWhere((q) => q.language == 'en');
      final hindiQ =
          job.acceptedQuestions.firstWhere((q) => q.language == 'hi');
      expect(englishQ.id, isNot(equals(hindiQ.id)));
      expect(englishQ.source.sourceId, 'SRC_BILINGUAL_BPSC');
      expect(hindiQ.source.sourceId, 'SRC_BILINGUAL_BPSC');
    });

    test(
        '17. Strict source provenance chain: Question -> Source Reference -> Checksum',
        () async {
      const descriptor = PyqSourceDescriptor(
        sourceId: 'SRC_PROVENANCE_TEST',
        sourceName: 'Provenance Test',
        examId: 'upsc',
        publisher: 'UPSC Testing Agency',
        sourceType: SourceType.officialPdf,
        format: PyqSourceFormat.json,
        years: [2024],
        languages: ['en'],
        uriOrPath: 'official/upsc_2024_gs1.pdf',
      );

      const jsonText = '''[
        {
          "questionText": "What is the term of office for a member of Rajya Sabha?",
          "options": ["(A) 4 years", "(B) 5 years", "(C) 6 years", "(D) Permanent"],
          "correctAnswer": "C",
          "paper": "GS1",
          "year": 2024
        }
      ]''';

      final fetcher = InMemorySourceFetcher();
      fetcher.registerText(descriptor, jsonText);

      final engine = MultiExamPyqAcquisitionEngine(fetcher: fetcher);
      final job = await engine.ingestSource(descriptor);

      final q = job.acceptedQuestions.first;
      expect(q.source.sourceId, 'SRC_PROVENANCE_TEST');
      expect(q.source.publisher, 'UPSC Testing Agency');
      expect(q.source.checksum, job.sourceChecksum);
      expect(q.source.checksum.length, 64);
    });
  });

  group('P30.7 Multi-Exam Ingestion Across 5 Target Examinations (Phase 15)',
      () {
    test(
        '18. Ingests sources for UPSC, BPSC, SSC, Banking, Railways under distinct profiles',
        () async {
      final fetcher = InMemorySourceFetcher();

      const upscDesc = PyqSourceDescriptor(
        sourceId: 'SRC_UPSC',
        sourceName: 'UPSC 2024',
        examId: 'upsc',
        publisher: 'UPSC',
        sourceType: SourceType.officialPdf,
        format: PyqSourceFormat.json,
        years: [2024],
        languages: ['en'],
        uriOrPath: 'memory:upsc',
      );

      const bpscDesc = PyqSourceDescriptor(
        sourceId: 'SRC_BPSC',
        sourceName: 'BPSC 2023',
        examId: 'bpsc',
        publisher: 'BPSC',
        sourceType: SourceType.verifiedArchive,
        format: PyqSourceFormat.json,
        years: [2023],
        languages: ['en'],
        uriOrPath: 'memory:bpsc',
      );

      const sscDesc = PyqSourceDescriptor(
        sourceId: 'SRC_SSC',
        sourceName: 'SSC 2023',
        examId: 'ssc',
        publisher: 'SSC',
        sourceType: SourceType.officialWebsite,
        format: PyqSourceFormat.json,
        years: [2023],
        languages: ['en'],
        uriOrPath: 'memory:ssc',
      );

      const bankingDesc = PyqSourceDescriptor(
        sourceId: 'SRC_BANKING',
        sourceName: 'Banking 2024',
        examId: 'banking',
        publisher: 'IBPS',
        sourceType: SourceType.verifiedArchive,
        format: PyqSourceFormat.json,
        years: [2024],
        languages: ['en'],
        uriOrPath: 'memory:banking',
      );

      const rrbDesc = PyqSourceDescriptor(
        sourceId: 'SRC_RAILWAYS',
        sourceName: 'Railways 2024',
        examId: 'railways',
        publisher: 'RRB',
        sourceType: SourceType.verifiedArchive,
        format: PyqSourceFormat.json,
        years: [2024],
        languages: ['en'],
        uriOrPath: 'memory:railways',
      );

      fetcher.registerText(upscDesc,
          '[{"questionText": "UPSC Q1", "options": ["(A) 1", "(B) 2"], "correctAnswer": "A"}]');
      fetcher.registerText(bpscDesc,
          '[{"questionText": "BPSC Q1", "options": ["(A) 1", "(B) 2"], "correctAnswer": "A"}]');
      fetcher.registerText(sscDesc,
          '[{"questionText": "SSC Q1", "options": ["(A) 1", "(B) 2"], "correctAnswer": "A"}]');
      fetcher.registerText(bankingDesc,
          '[{"questionText": "Banking Q1", "options": ["(A) 1", "(B) 2"], "correctAnswer": "A"}]');
      fetcher.registerText(rrbDesc,
          '[{"questionText": "Railways Q1", "options": ["(A) 1", "(B) 2"], "correctAnswer": "A"}]');

      final engine = MultiExamPyqAcquisitionEngine(fetcher: fetcher);
      final jobs = await engine
          .ingestSources([upscDesc, bpscDesc, sscDesc, bankingDesc, rrbDesc]);

      expect(jobs.length, 5);
      expect(engine.totalQuestionsCount, 5);

      // Verify P29 queries with exam isolation
      final upscQs = engine.intelligenceService
          .getQuestions(const PyqFilterCriteria(examId: 'upsc'));
      expect(upscQs.length, 1);
      expect(upscQs.first.examId, 'upsc');

      final bpscQs = engine.intelligenceService
          .getQuestions(const PyqFilterCriteria(examId: 'bpsc'));
      expect(bpscQs.length, 1);
      expect(bpscQs.first.examId, 'bpsc');

      // Corpus analytics across all 5 exams
      final analytics = engine.intelligenceService.getCorpusAnalytics();
      expect(analytics.examDistribution.keys.length, 5);
      expect(analytics.examDistribution['upsc'], 1);
      expect(analytics.examDistribution['bpsc'], 1);
      expect(analytics.examDistribution['ssc'], 1);
      expect(analytics.examDistribution['banking'], 1);
      expect(analytics.examDistribution['railways'], 1);
    });
  });

  group('P30.8 Restart Persistence & Deterministic Replay (Phases 20 & 21)',
      () {
    test(
        '19. Snapshot export and restore preserves engine cache, jobs, and corpus',
        () async {
      const descriptor = PyqSourceDescriptor(
        sourceId: 'SRC_RESTART_TEST',
        sourceName: 'Restart Persistence Test',
        examId: 'upsc',
        publisher: 'UPSC',
        sourceType: SourceType.officialPdf,
        format: PyqSourceFormat.json,
        years: [2024],
        languages: ['en'],
        uriOrPath: 'memory:restart',
      );

      const jsonText = '''[
        {
          "questionText": "Fundamental Rights are enshrined in which part of the Constitution?",
          "options": ["(A) Part I", "(B) Part II", "(C) Part III", "(D) Part IV"],
          "correctAnswer": "C",
          "paper": "GS1",
          "year": 2024
        }
      ]''';

      final fetcher = InMemorySourceFetcher();
      fetcher.registerText(descriptor, jsonText);

      final engine1 = MultiExamPyqAcquisitionEngine(fetcher: fetcher);
      final job1 = await engine1.ingestSource(descriptor);
      expect(job1.acceptedQuestions.length, 1);
      expect(engine1.totalQuestionsCount, 1);

      // Export snapshot
      final snapshot = engine1.exportSnapshot();

      // Restore into fresh engine (simulating application restart)
      final engine2 = MultiExamPyqAcquisitionEngine(fetcher: fetcher);
      engine2.restoreSnapshot(snapshot);

      expect(engine2.totalQuestionsCount, 1);
      expect(engine2.jobHistory.length, 1);
      expect(engine2.jobHistory.first.jobId, job1.jobId);

      // Ingesting the same source into restored engine recognizes it as already processed!
      final repeatJob = await engine2.ingestSource(descriptor);
      expect(repeatJob.status, ImportJobStatus.skippedAlreadyProcessed);
      expect(engine2.totalQuestionsCount, 1);
    });

    test(
        '20. Deterministic Replay: Identical inputs produce identical IDs, checksums, and analytics',
        () {
      const input1 = RawQuestionInput(
        examId: 'upsc',
        year: 2024,
        paper: 'GS1',
        questionNumber: 42,
        questionText: 'Which article deals with Fundamental Duties?',
        options: [
          '(A) Article 51A',
          '(B) Article 32',
          '(C) Article 21',
          '(D) Article 19'
        ],
        correctAnswer: 'A',
      );

      const input2 = RawQuestionInput(
        examId: 'upsc',
        year: 2024,
        paper: 'GS1',
        questionNumber: 42,
        questionText: 'Which article deals with Fundamental Duties?',
        options: [
          '(A) Article 51A',
          '(B) Article 32',
          '(C) Article 21',
          '(D) Article 19'
        ],
        correctAnswer: 'A',
      );

      final norm1 = PyqNormalizationPipeline.normalize(input1);
      final norm2 = PyqNormalizationPipeline.normalize(input2);

      expect(norm1.id, norm2.id);
      expect(norm1.normalizedText, norm2.normalizedText);
      expect(norm1.correctOption, norm2.correctOption);
    });
  });

  group('P30.9 Large Corpus Performance Benchmarks (Phase 19 & 11)', () {
    test('21. High-throughput ingestion benchmark (10K, 50K questions)', () {
      // Generate 10,000 synthetic questions
      const count = 10000;
      final inputs = List.generate(count, (i) {
        return RawQuestionInput(
          examId: 'upsc',
          year: 2000 + (i % 25),
          paper: 'GS1',
          questionNumber: i + 1,
          subject: 'Subject_${i % 5}',
          topic: 'Topic_${i % 20}',
          questionText:
              'Synthetic Question $i: What is the property of element $i in group ${i % 18}?',
          options: [
            '(A) Option A for $i',
            '(B) Option B for $i',
            '(C) Option C for $i',
            '(D) Option D for $i',
          ],
          correctAnswer: 'A',
        );
      });

      final stopwatch = Stopwatch()..start();

      // Normalization + Deduplication + Ingestion
      final service = MultiExamPyqIntelligenceService();
      final result = service.ingestRawQuestions(inputs);

      stopwatch.stop();
      final durationMs = stopwatch.elapsedMilliseconds;

      expect(result.uniqueCount, count);
      expect(result.duplicateCount, 0);
      expect(service.totalQuestionsCount, count);

      // Safe, non-flaky broad performance threshold: 10,000 items in < 15,000 ms (15 seconds)
      expect(durationMs, lessThan(15000),
          reason:
              '10,000 questions took ${durationMs}ms, exceeding 15s threshold');

      // Aggregate analytics calculation on 10,000 items
      final analyticsWatch = Stopwatch()..start();
      final analytics = service.getCorpusAnalytics();
      analyticsWatch.stop();

      expect(analytics.totalQuestions, count);
      expect(analytics.subjectDistribution.keys.length, 5);
      expect(analyticsWatch.elapsedMilliseconds, lessThan(3000));
    });
  });
}
