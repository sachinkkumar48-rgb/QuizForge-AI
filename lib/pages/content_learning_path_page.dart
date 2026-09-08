import 'package:flutter/material.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/garuda_pyq.dart';

import '../core/di/service_locator_init.dart';
import 'adaptive_practice_page.dart';

/// Learner-facing Content-to-Learning-Path Explorer Screen (P42).
///
/// Implements the complete pedagogical pathway:
/// CONTENT → EXAM → SUBJECT → TOPIC → LEARNING OBJECTIVE → DIAGNOSTIC / START POINT → PRACTICE → PROGRESS.
class ContentLearningPathPage extends StatefulWidget {
  final ContentLearningPathService? service;
  final String learnerId;
  final String? initialExamId;
  final String? initialSubjectId;
  final List<NormalizedQuestion>? corpus;

  const ContentLearningPathPage({
    super.key,
    this.service,
    this.learnerId = 'learner_titan_active',
    this.initialExamId,
    this.initialSubjectId,
    this.corpus,
  });

  @override
  State<ContentLearningPathPage> createState() =>
      _ContentLearningPathPageState();
}

class _ContentLearningPathPageState extends State<ContentLearningPathPage> {
  late final ContentLearningPathService _service;
  late ContentLearningPathState _state;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? locate<ContentLearningPathService>();
    final exams = _service.getAvailableExams();

    if (widget.initialExamId != null) {
      final selectedExam = exams.firstWhere(
        (e) => e.id == widget.initialExamId,
        orElse: () => exams.first,
      );
      final subjects = _service.getSubjectsForExam(selectedExam.id);

      if (widget.initialSubjectId != null) {
        final selectedSubject = subjects.firstWhere(
          (s) => s.id == widget.initialSubjectId,
          orElse: () => subjects.first,
        );
        final topics = _service.getTopicsForSubject(
          selectedExam.id,
          selectedSubject.id,
          corpus: widget.corpus,
        );
        _state = ContentLearningPathState(
          status: ContentPathStatus.subjectSelected,
          availableExams: exams,
          selectedExam: selectedExam,
          availableSubjects: subjects,
          selectedSubject: selectedSubject,
          availableTopics: topics,
        );
      } else {
        _state = ContentLearningPathState(
          status: ContentPathStatus.examSelected,
          availableExams: exams,
          selectedExam: selectedExam,
          availableSubjects: subjects,
        );
      }
    } else {
      _state = ContentLearningPathState.initial(availableExams: exams);
    }
  }

  void _handleExamSelected(ExamContext exam) {
    if (!exam.isSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${exam.name} is currently in catalogue preview. Active learning paths are available for UPSC Civil Services.',
          ),
          backgroundColor: Colors.blueGrey.shade800,
        ),
      );
      return;
    }

    final subjects = _service.getSubjectsForExam(exam.id);
    setState(() {
      _state = _state.copyWith(
        status: ContentPathStatus.examSelected,
        selectedExam: exam,
        availableSubjects: subjects,
        selectedSubject: null,
        availableTopics: const [],
        selectedTopic: null,
        resolvedObjective: null,
        errorMessage: null,
      );
    });
  }

  void _handleSubjectSelected(SubjectContext subject) {
    final topics = _service.getTopicsForSubject(
      _state.selectedExam?.id ?? 'upsc_prelims_gs1',
      subject.id,
      corpus: widget.corpus,
    );
    setState(() {
      _state = _state.copyWith(
        status: ContentPathStatus.subjectSelected,
        selectedSubject: subject,
        availableTopics: topics,
        selectedTopic: null,
        resolvedObjective: null,
        errorMessage: null,
      );
    });
  }

  Future<void> _handleTopicSelected(TopicContext topic) async {
    setState(() {
      _state = _state.copyWith(status: ContentPathStatus.loading);
    });

    final resolved = await _service.resolveLearningPath(
      learnerId: widget.learnerId,
      examId: _state.selectedExam?.id ?? 'upsc_prelims_gs1',
      subjectId: _state.selectedSubject?.id ?? 'indian_polity',
      topicId: topic.id,
      corpus: widget.corpus,
    );

    setState(() {
      _state = resolved;
    });
  }

  void _handleActionTrigger() {
    final topic = _state.selectedTopic?.name ?? 'UPSC Practice';
    final isDiag =
        _state.recommendedAction == AdaptiveActionType.takeDiagnostic ||
            _state.isDiagnosticRequired;

    if (_state.canResumeActiveSession) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdaptivePracticePage(
            isResumeMode: true,
            resumeSessionId: _state.activeSessionId,
            targetTopic: topic,
            examId: _state.selectedExam?.id ?? 'upsc_prelims_gs1',
            learnerId: widget.learnerId,
            corpus: widget.corpus,
          ),
        ),
      ).then((_) => _refreshTopicState());
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdaptivePracticePage(
            targetTopic: topic,
            examId: _state.selectedExam?.id ?? 'upsc_prelims_gs1',
            learnerId: widget.learnerId,
            corpus: widget.corpus,
            isDiagnosticMode: isDiag,
            targetObjectiveId: _state.resolvedObjective?.id,
          ),
        ),
      ).then((_) => _refreshTopicState());
    }
  }

  Future<void> _refreshTopicState() async {
    if (_state.selectedTopic != null &&
        _state.selectedExam != null &&
        _state.selectedSubject != null) {
      final resolved = await _service.resolveLearningPath(
        learnerId: widget.learnerId,
        examId: _state.selectedExam!.id,
        subjectId: _state.selectedSubject!.id,
        topicId: _state.selectedTopic!.id,
        corpus: widget.corpus,
      );
      if (mounted) {
        setState(() {
          _state = resolved;
        });
      }
    }
  }

  void _navigateBackOneLevel() {
    setState(() {
      if (_state.status == ContentPathStatus.topicSelected ||
          _state.status == ContentPathStatus.emptyContent) {
        _state = _state.copyWith(
          status: ContentPathStatus.subjectSelected,
          selectedTopic: null,
          resolvedObjective: null,
        );
      } else if (_state.status == ContentPathStatus.subjectSelected) {
        _state = _state.copyWith(
          status: ContentPathStatus.examSelected,
          selectedSubject: null,
          availableTopics: const [],
        );
      } else if (_state.status == ContentPathStatus.examSelected) {
        _state = _state.copyWith(
          status: ContentPathStatus.initial,
          selectedExam: null,
          availableSubjects: const [],
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Paths & Content'),
        leading: _state.status != ContentPathStatus.initial
            ? IconButton(
                key: const Key('content_path_back_button'),
                icon: const Icon(Icons.arrow_back),
                onPressed: _navigateBackOneLevel,
              )
            : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBreadcrumbHeader(context),
              const SizedBox(height: 16),
              Expanded(
                child: _buildBodyContent(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreadcrumbHeader(BuildContext context) {
    final theme = Theme.of(context);
    final steps = <String>['Exams'];
    if (_state.selectedExam != null) {
      steps.add(_state.selectedExam!.code);
    }
    if (_state.selectedSubject != null) {
      steps.add(_state.selectedSubject!.name);
    }
    if (_state.selectedTopic != null) {
      steps.add(_state.selectedTopic!.name);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_tree_outlined,
              size: 18, color: Colors.deepPurple),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              steps.join('  ›  '),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.deepPurple.shade700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent(BuildContext context) {
    switch (_state.status) {
      case ContentPathStatus.loading:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Resolving curriculum learning path...',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        );

      case ContentPathStatus.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                _state.errorMessage ?? 'An error occurred loading the path.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _state = ContentLearningPathState.initial(
                      availableExams: _service.getAvailableExams(),
                    );
                  });
                },
                icon: const Icon(Icons.restart_alt),
                label: const Text('Back to Catalogue'),
              ),
            ],
          ),
        );

      case ContentPathStatus.initial:
        return _buildExamCatalogue(context);

      case ContentPathStatus.examSelected:
        return _buildSubjectSelection(context);

      case ContentPathStatus.subjectSelected:
        return _buildTopicSelection(context);

      case ContentPathStatus.emptyContent:
        return _buildEmptyContentState(context);

      case ContentPathStatus.topicSelected:
        return _buildTopicDetailsAndAction(context);
    }
  }

  Widget _buildExamCatalogue(BuildContext context) {
    final exams = _state.availableExams;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Examination',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose your target competitive exam to explore curriculum domains and PYQ learning paths.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            key: const Key('content_path_exam_list'),
            itemCount: exams.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final exam = exams[index];
              return Card(
                key: Key('content_path_exam_${exam.id}'),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: exam.isSupported
                        ? Colors.deepPurple.shade200
                        : Colors.grey.shade300,
                  ),
                ),
                color: exam.isSupported
                    ? Colors.deepPurple.withValues(alpha: 0.05)
                    : Colors.grey.withValues(alpha: 0.05),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: exam.isSupported
                        ? Colors.deepPurple
                        : Colors.grey.shade400,
                    child: Icon(
                      exam.isSupported ? Icons.school : Icons.lock_clock,
                      color: Colors.white,
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          exam.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (exam.isSupported)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Supported',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Preview',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(exam.description),
                      const SizedBox(height: 4),
                      Text(
                        'Conducting Body: ${exam.conductingBody}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _handleExamSelected(exam),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectSelection(BuildContext context) {
    final subjects = _state.availableSubjects;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Subject for ${_state.selectedExam?.name}',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Explore topics and learning objectives structured under each subject curriculum.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: subjects.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final subject = subjects[index];
              return Card(
                key: Key('content_path_subject_${subject.id}'),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.indigo.shade200),
                ),
                color: Colors.indigo.withValues(alpha: 0.05),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    subject.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(subject.description),
                      const SizedBox(height: 4),
                      Text(
                        '${subject.topicCount} Curriculum Topics Available',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.indigo.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _handleSubjectSelected(subject),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTopicSelection(BuildContext context) {
    final topics = _state.availableTopics;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Topics in ${_state.selectedSubject?.name}',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Select a topic to resolve its learning objective and enter personalized practice.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: topics.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final topic = topics[index];
              final hasContent = topic.hasPyqContent;

              return Card(
                key: Key('content_path_topic_${topic.id}'),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: hasContent
                        ? Colors.deepPurple.shade300
                        : Colors.grey.shade300,
                  ),
                ),
                color: hasContent ? Colors.white : Colors.grey.shade50,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: hasContent
                        ? Colors.deepPurple.shade50
                        : Colors.grey.shade200,
                    child: Icon(
                      hasContent ? Icons.bookmark_added : Icons.bookmark_border,
                      color:
                          hasContent ? Colors.deepPurple : Colors.grey.shade600,
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          topic.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: hasContent
                              ? Colors.green.shade50
                              : Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: hasContent
                                ? Colors.green.shade300
                                : Colors.amber.shade300,
                          ),
                        ),
                        child: Text(
                          hasContent ? '${topic.questionCount} PYQs' : '0 PYQs',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: hasContent
                                ? Colors.green.shade800
                                : Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(topic.description),
                      if (topic.objectiveTitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Objective: ${topic.objectiveTitle}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.deepPurple.shade700,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => _handleTopicSelected(topic),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyContentState(BuildContext context) {
    return Center(
      child: Card(
        key: const Key('content_path_empty_state'),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.amber.shade300),
        ),
        color: Colors.amber.shade50.withValues(alpha: 0.3),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined,
                  size: 48, color: Colors.amber.shade800),
              const SizedBox(height: 12),
              Text(
                _state.actionTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _state.actionDescription,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _state = _state.copyWith(
                      status: ContentPathStatus.subjectSelected,
                      selectedTopic: null,
                      resolvedObjective: null,
                    );
                  });
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Choose Another Topic'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopicDetailsAndAction(BuildContext context) {
    final topic = _state.selectedTopic!;
    final objective = _state.resolvedObjective;
    final progress = _state.authoritativeProgress;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Topic Overview Card
          Card(
            key: const Key('content_path_objective_card'),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.deepPurple.shade200),
            ),
            color: Colors.deepPurple.withValues(alpha: 0.04),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _state.selectedSubject?.name.toUpperCase() ??
                              'POLITY',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple.shade900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${topic.questionCount} Questions Available',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    topic.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(topic.description),
                  if (objective != null) ...[
                    const Divider(height: 24),
                    Text(
                      'Learning Objective',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      objective.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Bloom Level: ${objective.bloomLevel.name.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.deepPurple.shade700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'ID: ${objective.id}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Objective Mastered Banner
          if (_state.isObjectiveAchieved) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'OBJECTIVE MASTERED',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'You have achieved competency on ${topic.name}.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.green.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Next Sequential Objective in Syllabus
          if (_state.nextObjectiveTitle != null) ...[
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.indigo.shade200),
              ),
              color: Colors.indigo.shade50.withValues(alpha: 0.3),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  children: [
                    const Icon(Icons.fast_forward, color: Colors.indigo),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'NEXT CURRICULUM OBJECTIVE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _state.nextObjectiveTitle!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        if (_state.selectedExam != null &&
                            _state.selectedSubject != null &&
                            _state.selectedTopic != null) {
                          final next = _service.getNextTopicForTopic(
                            _state.selectedExam!.id,
                            _state.selectedSubject!.id,
                            _state.selectedTopic!.id,
                            corpus: widget.corpus,
                          );
                          if (next != null) {
                            _handleTopicSelected(next);
                          }
                        }
                      },
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: const Text('Advance'),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Authoritative Progress Metrics (if available)
          if (progress != null) ...[
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.blueGrey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Authoritative Progress',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricColumn(
                          'Attempts',
                          progress.attemptCount.toString(),
                        ),
                        _buildMetricColumn(
                          'Correct',
                          progress.correctCount.toString(),
                        ),
                        _buildMetricColumn(
                          'Accuracy',
                          '${(progress.successRate * 100).toInt()}%',
                        ),
                        _buildMetricColumn(
                          'Status',
                          progress.status.displayName,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Recommended Next Action Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: _state.canResumeActiveSession
                    ? Colors.amber.shade400
                    : Colors.deepPurple.shade400,
                width: 1.5,
              ),
            ),
            color: _state.canResumeActiveSession
                ? Colors.amber.shade50.withValues(alpha: 0.3)
                : Colors.deepPurple.shade50.withValues(alpha: 0.3),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: _state.canResumeActiveSession
                            ? Colors.amber.shade700
                            : Colors.deepPurple,
                        radius: 18,
                        child: Icon(
                          _state.canResumeActiveSession
                              ? Icons.play_arrow
                              : (_state.recommendedAction ==
                                      AdaptiveActionType.takeDiagnostic
                                  ? Icons.assignment_outlined
                                  : (_state.recommendedAction ==
                                          AdaptiveActionType.startRemedialLesson
                                      ? Icons.healing
                                      : (_state.recommendedAction ==
                                              AdaptiveActionType.practicePyqs
                                          ? Icons.auto_stories
                                          : (_state.recommendedAction ==
                                                  AdaptiveActionType
                                                      .reviewWeakTopic
                                              ? Icons.refresh
                                              : Icons.school)))),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _state.canResumeActiveSession
                            ? 'RESUME IN-FLIGHT SESSION'
                            : (_state.recommendedAction ==
                                    AdaptiveActionType.takeDiagnostic
                                ? 'RECOMMENDED ENTRY POINT'
                                : (_state.recommendedAction ==
                                        AdaptiveActionType.startRemedialLesson
                                    ? 'TARGETED REMEDIATION'
                                    : (_state.recommendedAction ==
                                            AdaptiveActionType.practicePyqs
                                        ? 'PYQ PRACTICE READY'
                                        : (_state.recommendedAction ==
                                                AdaptiveActionType
                                                    .reviewWeakTopic
                                            ? 'SPACED RETENTION REVISION'
                                            : 'ADAPTIVE PRACTICE READY')))),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _state.canResumeActiveSession
                              ? Colors.amber.shade900
                              : Colors.deepPurple.shade900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _state.actionTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _state.actionDescription,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: _state.canResumeActiveSession
                          ? const Key('content_path_resume_button')
                          : const Key('content_path_action_button'),
                      onPressed: _handleActionTrigger,
                      icon: Icon(
                        _state.canResumeActiveSession
                            ? Icons.play_circle_fill
                            : (_state.recommendedAction ==
                                    AdaptiveActionType.takeDiagnostic
                                ? Icons.assignment_outlined
                                : (_state.recommendedAction ==
                                        AdaptiveActionType.startRemedialLesson
                                    ? Icons.healing
                                    : (_state.recommendedAction ==
                                            AdaptiveActionType.practicePyqs
                                        ? Icons.auto_stories
                                        : (_state.recommendedAction ==
                                                AdaptiveActionType
                                                    .reviewWeakTopic
                                            ? Icons.refresh
                                            : Icons.arrow_forward)))),
                      ),
                      label: Text(
                        _state.canResumeActiveSession
                            ? 'Resume Learning'
                            : (_state.recommendedAction ==
                                    AdaptiveActionType.takeDiagnostic
                                ? 'Take Diagnostic Assessment'
                                : (_state.recommendedAction ==
                                        AdaptiveActionType.startRemedialLesson
                                    ? 'Start Remedial Lesson'
                                    : (_state.recommendedAction ==
                                            AdaptiveActionType.practicePyqs
                                        ? 'Practice UPSC PYQs'
                                        : (_state.recommendedAction ==
                                                AdaptiveActionType
                                                    .reviewWeakTopic
                                            ? 'Review Mastered Concepts'
                                            : 'Start Learning')))),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: _state.canResumeActiveSession
                            ? Colors.amber.shade900
                            : Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
