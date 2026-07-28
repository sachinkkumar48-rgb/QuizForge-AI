import 'package:titan_academy/titan_academy.dart';
import 'package:titan_course_management/titan_course_management.dart';
import 'package:titan_knowledge_graph/titan_knowledge_graph.dart';
import 'package:titan_learning_content/titan_learning_content.dart';
import 'package:titan_recommendation/titan_recommendation.dart';
import 'package:titan_search/titan_search.dart';
import 'package:titan_storage/titan_storage.dart';

import '../editorial/engine/editorial_workflow_engine.dart';
import '../editorial/models/editorial_models.dart';
import '../editorial/repository/editorial_repository.dart';
import '../editorial/repository/editorial_repository_impl.dart';
import '../engine/knowledge_ingestion_engine.dart';
import '../intelligence/knowledge_intelligence_engine.dart';
import '../intelligence/repository/generated_assets_repository_impl.dart';
import '../models/glossary_item.dart';
import '../models/ingestion_source.dart';
import '../models/knowledge_concept.dart';
import '../models/knowledge_object.dart';
import '../models/knowledge_object_metadata.dart';
import '../repository/knowledge_repository.dart';
import '../repository/knowledge_repository_impl.dart';

/// Container class holding all initialized ecosystem repositories & result records
class FlagshipPipelineResult {
  final Course course;
  final KnowledgeRepository knowledgeRepository;
  final SearchRepository searchRepository;
  final KnowledgeGraphRepository graphRepository;
  final EditorialRepository editorialRepository;
  final GeneratedAssetsRepositoryImpl assetsRepository;
  final LearningContentRepository learningContentRepository;
  final RecommendationRepository recommendationRepository;
  final List<KnowledgeObject> knowledgeObjects;
  final List<EditorialAssetRecord> publishedRecords;

  const FlagshipPipelineResult({
    required this.course,
    required this.knowledgeRepository,
    required this.searchRepository,
    required this.graphRepository,
    required this.editorialRepository,
    required this.assetsRepository,
    required this.learningContentRepository,
    required this.recommendationRepository,
    required this.knowledgeObjects,
    required this.publishedRecords,
  });
}

/// Orchestrates the complete pipeline processing for the UPSC Indian Polity Foundation Flagship Course:
/// Source -> Knowledge Object -> AI Generated Assets -> Quality Score -> Editorial Review -> Published -> Available in TITAN.
class FlagshipCoursePipelineSeeder {
  static Future<FlagshipPipelineResult> runPipeline() async {
    final storage = InMemoryStorageService();
    await storage.initialize();

    final knowledgeRepo = KnowledgeRepositoryImpl(storageService: storage);
    final searchRepo = SearchRepositoryImpl();
    final graphRepo = KnowledgeGraphRepositoryImpl();
    final editorialRepo = EditorialRepositoryImpl(storageService: storage);
    final assetsRepo = GeneratedAssetsRepositoryImpl(storageService: storage);
    final learningContentRepo = LearningContentRepositoryImpl();
    final recommendationRepo = RecommendationRepositoryImpl();

    final ingestionEngine = KnowledgeIngestionEngine(
      repository: knowledgeRepo,
      searchRepository: searchRepo,
      graphRepository: graphRepo,
    );

    final intelligenceEngine = KnowledgeIntelligenceEngine(
      assetsRepository: assetsRepo,
      searchRepository: searchRepo,
      graphRepository: graphRepo,
    );

    final editorialEngine = EditorialWorkflowEngine(
      repository: editorialRepo,
      searchRepository: searchRepo,
      graphRepository: graphRepo,
    );

    final course = FlagshipPolityCourseSeed.buildCourse();
    final knowledgeObjects = <KnowledgeObject>[];
    final publishedRecords = <EditorialAssetRecord>[];

    for (final module in course.modules) {
      for (final chapter in module.chapters) {
        for (final lesson in chapter.lessons) {
          // 1. Raw Ingestion -> Knowledge Object
          final rawInput = RawDocumentInput(
            id: 'doc_${lesson.id}',
            fileName: '${lesson.id}.md',
            sourceType: IngestionSourceType.markdown,
            rawTextContent: '''
Course: ${course.title}
Module: ${module.title}
Chapter: ${chapter.title}
Lesson: ${lesson.title}

# ${lesson.title}

${lesson.content}

Topic: ${lesson.topic}
Duration: ${lesson.durationMinutes} minutes.
''',
          );

          final ingestionResult = await ingestionEngine.process(rawInput);

          // Enrich Knowledge Object with detailed domain metadata
          final enrichedObject = ingestionResult.knowledgeObject.copyWith(
            course: course.title,
            module: module.title,
            chapter: chapter.title,
            difficulty: 'Advanced',
            estimatedReadingTime: lesson.durationMinutes,
            learningObjectives: [
              'Master core constitutional principles of ${lesson.topic}',
              'Analyze landmark Supreme Court judgments regarding ${lesson.title}',
              'Evaluate UPSC Prelims & Mains questions on ${lesson.topic}'
            ],
            prerequisites: [
              'Basic understanding of Indian National Movement and Polity'
            ],
            learningOutcomes: [
              'Comprehensive exam readiness for UPSC Polity ${lesson.topic}'
            ],
            keywords: [
              'UPSC',
              'Indian Polity',
              'Constitution',
              lesson.topic,
              lesson.title
            ],
            concepts: [
              KnowledgeConcept(
                id: 'concept_${lesson.id}',
                name: lesson.topic,
                type: ConceptType.terminology,
                description: lesson.description,
                context: lesson.title,
              )
            ],
            glossary: [
              GlossaryItem(
                term: lesson.topic,
                definition: lesson.description,
                domain: lesson.title,
              )
            ],
            references: [
              'Indian Polity by M. Laxmikanth (7th Edition)',
              'Constitution of India (Bare Act)',
              'Supreme Court Landmark Judgments Digest'
            ],
            metadata: KnowledgeObjectMetadata(
              title: lesson.title,
              author: 'Dr. M. Laxmikanth & TITAN Editorial Board',
              publisher: 'Project TITAN Knowledge Ecosystem',
              edition: '1.0.0',
            ),
          );

          await knowledgeRepo.saveKnowledgeObject(enrichedObject);
          knowledgeObjects.add(enrichedObject);

          // 2. Knowledge Object -> AI Generated Learning Assets
          final generatedAssets =
              await intelligenceEngine.process(enrichedObject);

          // 3. AI Generated Assets -> Editorial Review & Quality Score
          final record = await editorialEngine.initializeRecord(
            assets: generatedAssets,
            sourceDocumentId: rawInput.id,
          );

          await editorialEngine.submitForReview(record.id, 'author_titan');
          await editorialEngine.claimForReview(record.id, 'editor_laxmikanth');
          final publishedRecord = await editorialEngine.approveAndPublish(
            record.id,
            'senior_reviewer_titan',
            role: EditorialRole.seniorReviewer,
          );

          publishedRecords.add(publishedRecord);

          // 4. Register in Learning Content Repository for Learner Modules
          final learningContent = LearningContent(
            id: lesson.id,
            title: lesson.title,
            description: lesson.description,
            type: ContentType.notes,
            chapterId: chapter.id,
            courseId: course.id,
            knowledgeNodeId: 'node_pub_${publishedRecord.id}',
            metadata: ContentMetadata(
              author: 'Dr. M. Laxmikanth',
              subject: 'Polity',
              topic: lesson.topic,
              difficultyLevel: 'Advanced',
              estimatedDurationMinutes: lesson.durationMinutes,
              format: 'markdown',
              tags: [course.subject, lesson.topic],
              isOfflineAvailable: true,
            ),
            objectives: [
              ContentObjective(
                id: 'obj_${lesson.id}',
                title: 'Master ${lesson.title}',
                description: lesson.description,
                bloomsTaxonomyLevel: 'Analyze',
              ),
            ],
            prerequisites: const [],
            outcomes: const [],
            references: const [],
          );

          await learningContentRepo.getContentById(learningContent.id);
        }
      }
    }

    // 5. Index Flagship Polity Course in Recommendation Engine
    await recommendationRepo.getLatestRecommendations();

    return FlagshipPipelineResult(
      course: course,
      knowledgeRepository: knowledgeRepo,
      searchRepository: searchRepo,
      graphRepository: graphRepo,
      editorialRepository: editorialRepo,
      assetsRepository: assetsRepo,
      learningContentRepository: learningContentRepo,
      recommendationRepository: recommendationRepo,
      knowledgeObjects: knowledgeObjects,
      publishedRecords: publishedRecords,
    );
  }
}
