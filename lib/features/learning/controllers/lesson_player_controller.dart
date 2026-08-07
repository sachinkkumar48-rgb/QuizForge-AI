import 'package:flutter/foundation.dart';
import '../data/lesson_repository.dart';
import '../models/lesson_model.dart';

class LessonPlayerController extends ChangeNotifier {
  final LessonRepository _repository;
  LessonModel? _lesson;
  int _currentStepIndex = 0;
  bool _isLoading = false;

  LessonPlayerController({
    LessonModel? initialLesson,
    LessonRepository? repository,
  })  : _lesson = initialLesson,
        _repository = repository ?? LessonRepository();

  LessonModel? get lesson => _lesson;
  int get currentStepIndex => _currentStepIndex;
  bool get isLoading => _isLoading;

  int get currentStep => _currentStepIndex + 1;
  int get totalSteps => (_lesson == null || _lesson!.steps.isEmpty) ? 1 : _lesson!.steps.length;

  double get progressRatio => totalSteps > 0 ? (currentStep / totalSteps) : 0.0;
  int get completionPercentage => (progressRatio * 100).round();

  bool get hasPrevious => _currentStepIndex > 0;
  bool get hasNext => _currentStepIndex < totalSteps - 1;

  LessonStep? get currentStepData =>
      (_lesson != null && _lesson!.steps.isNotEmpty && _currentStepIndex < _lesson!.steps.length)
          ? _lesson!.steps[_currentStepIndex]
          : null;

  Future<void> loadLesson(String lessonId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _lesson = await _repository.getLessonById(lessonId);
      _currentStepIndex = 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void nextStep() {
    if (hasNext) {
      _currentStepIndex++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (hasPrevious) {
      _currentStepIndex--;
      notifyListeners();
    }
  }

  void goToStep(int index) {
    if (index >= 0 && index < totalSteps) {
      _currentStepIndex = index;
      notifyListeners();
    }
  }
}
