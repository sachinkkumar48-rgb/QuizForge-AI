import 'package:flutter_test/flutter_test.dart';
import 'package:titan_academy/titan_academy.dart';
import 'package:titan_ai_tutor/titan_ai_tutor.dart';
import 'package:titan_course_management/titan_course_management.dart';
import 'package:titan_dashboard/titan_dashboard.dart';
import 'package:titan_ingestion_pipeline/titan_ingestion_pipeline.dart';
import 'package:titan_knowledge_graph/titan_knowledge_graph.dart';
import 'package:titan_learning/titan_learning.dart';
import 'package:titan_learning_journey/titan_learning_journey.dart';
import 'package:titan_notes/titan_notes.dart';
import 'package:titan_planner/titan_planner.dart';
import 'package:titan_recommendation/titan_recommendation.dart';
import 'package:titan_revision/titan_revision.dart';
import 'package:titan_search/titan_search.dart';

void main() {
  group('TITAN-K4-001 Flagship Course Production & Validation Tests', () {
    late FlagshipPipelineResult pipelineResult;

    setUpAll(() async {
      pipelineResult = await FlagshipCoursePipelineSeeder.runPipeline();
    });

    test('1. Course Hierarchy & 10 Modules Validation', () {
      final course = pipelineResult.course;

      expect(course.id, equals('course_upsc_polity_foundation'));
      expect(course.title, contains('UPSC Civil Services'));
      expect(course.subject, equals('Indian Polity & Governance'));
      expect(course.modules.length, equals(10));

      final expectedModuleTitles = [
        'Historical Background',
        'Making of the Constitution',
        'Salient Features of the Constitution',
        'Preamble of the Constitution',
        'Union & Its Territory',
        'Citizenship',
        'Fundamental Rights',
        'Directive Principles of State Policy (DPSP)',
        'Fundamental Duties',
        'Amendment Procedure of the Constitution',
      ];

      for (var i = 0; i < 10; i++) {
        expect(course.modules[i].title, contains(expectedModuleTitles[i]));
        expect(course.modules[i].chapters.isNotEmpty, isTrue);
        for (final chapter in course.modules[i].chapters) {
          expect(chapter.lessons.isNotEmpty, isTrue);
        }
      }
    });

    test('2. Lesson Metadata & Properties Completeness', () {
      for (final ko in pipelineResult.knowledgeObjects) {
        expect(ko.title.isNotEmpty, isTrue);
        expect(ko.course, contains('UPSC Civil Services'));
        expect(ko.module, isNotNull);
        expect(ko.chapter, isNotNull);
        expect(ko.estimatedReadingTime, greaterThan(0));
        expect(ko.difficulty, equals('Advanced'));
        expect(ko.learningObjectives.isNotEmpty, isTrue);
        expect(ko.prerequisites.isNotEmpty, isTrue);
        expect(ko.learningOutcomes.isNotEmpty, isTrue);
        expect(ko.keywords.isNotEmpty, isTrue);
        expect(ko.concepts.isNotEmpty, isTrue);
        expect(ko.glossary.isNotEmpty, isTrue);
        expect(ko.references.isNotEmpty, isTrue);
        expect(ko.metadata.title, equals(ko.title));
      }
    });

    test(
        '3. Learning Asset Generation (Summaries, Notes, Flashcards, Mind Map, Questions, Tutor Context)',
        () {
      for (final record in pipelineResult.publishedRecords) {
        final assets = record.assets;

        // Lesson Content & Summaries
        expect(assets.summaries.summary30s.isNotEmpty, isTrue);
        expect(assets.summaries.summary5m.isNotEmpty, isTrue);
        expect(assets.summaries.detailedSummary.isNotEmpty, isTrue);

        // Revision Notes
        expect(assets.revisionNotes.onePageNotes.isNotEmpty, isTrue);
        expect(assets.revisionNotes.lastMinuteNotes.isNotEmpty, isTrue);
        expect(assets.revisionNotes.examNotes.isNotEmpty, isTrue);

        // Flashcards
        expect(assets.flashcards.isNotEmpty, isTrue);

        // Practice & Subjective Questions
        expect(assets.questions.isNotEmpty, isTrue);

        // Mind Map Structure
        expect(assets.mindMap.rootNode.label.isNotEmpty, isTrue);

        // AI Tutor Context
        expect(assets.tutorContext.contextPrompt.isNotEmpty, isTrue);
      }
    });

    test('4. Editorial Workflow & Publication Audit Validation', () {
      for (final record in pipelineResult.publishedRecords) {
        expect(record.status, equals(EditorialStatus.published));

        // Quality Score evaluation
        expect(record.qualityScore.overallScore, greaterThanOrEqualTo(80.0));
        expect(
            record.qualityScore.knowledgeQuality, greaterThanOrEqualTo(80.0));

        // Versioning history
        expect(record.versionHistory.isNotEmpty, isTrue);
        expect(record.versionHistory.first.versionNumber, equals('1.0.0'));

        // Audit Trail
        expect(record.auditLog.isNotEmpty, isTrue);
        expect(
          record.auditLog.any((a) => a.toStatus == EditorialStatus.published),
          isTrue,
        );
        expect(record.provenance.reviewerId, equals('senior_reviewer_titan'));
      }
    });

    test('5. Search, Knowledge Graph, & Recommendation Indexing', () async {
      final searchRepo = pipelineResult.searchRepository;
      final graphRepo = pipelineResult.graphRepository;

      // Verify Search Indexing for Polity terms
      final searchResults = await searchRepo.search(SearchQuery(
        query: 'Preamble',
        scopes: const [SearchScope.notes, SearchScope.revision],
      ));
      expect(searchResults.isNotEmpty, isTrue);

      // Verify Knowledge Graph Expansion
      final nodeCount = await graphRepo.getNodeCount();
      expect(nodeCount, greaterThan(0));

      final graphData = await graphRepo.getGraphData();
      expect(graphData.nodes.isNotEmpty, isTrue);
    });

    test('6. Learner Integration & End-to-End Success Journey', () async {
      // 1. Course Enrollment
      final courseRepo = CourseManagementRepositoryImpl();
      final fetchedCourse =
          await courseRepo.getCourseById('course_upsc_polity_foundation');
      expect(fetchedCourse, isNotNull);
      expect(fetchedCourse!.id, equals('course_upsc_polity_foundation'));

      // 2. Study Content Consumption
      final contentRepo = pipelineResult.learningContentRepository;
      final firstLessonId =
          fetchedCourse.modules.first.chapters.first.lessons.first.id;
      final lessonContent = await contentRepo.getContentById(firstLessonId);
      expect(lessonContent, isNotNull);

      // 3. Mark Progress & Completion
      final updatedProgress = await contentRepo.updateProgress(
        userId: 'learner_101',
        contentId: firstLessonId,
        lastPositionSeconds: 600,
        completionPercentage: 100.0,
        timeSpentSeconds: 600,
      );
      expect(updatedProgress.isCompleted, isTrue);

      // 4. Revision & Notes
      final searchRepo = pipelineResult.searchRepository;
      final revResults = await searchRepo.search(SearchQuery(
        query: 'Fundamental Rights',
        scopes: const [SearchScope.revision],
      ));
      expect(revResults.isNotEmpty, isTrue);

      // 5. Learner Dashboard & Journey Sync
      expect(fetchedCourse.modules.length, equals(10));
    });
  });
}
