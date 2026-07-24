import 'dart:convert';
import 'package:hive/hive.dart';
import '../../models/exam.dart';
import '../exam_repository.dart';

class HiveExamRepository implements ExamRepository {
  static const String _examBoxName = 'engine_exams';
  static const String _paperBoxName = 'engine_papers';

  Box<String>? _examBox;
  Box<String>? _paperBox;

  Future<Box<String>> _getExamBox() async {
    if (_examBox != null && _examBox!.isOpen) return _examBox!;
    _examBox = await Hive.openBox<String>(_examBoxName);
    return _examBox!;
  }

  Future<Box<String>> _getPaperBox() async {
    if (_paperBox != null && _paperBox!.isOpen) return _paperBox!;
    _paperBox = await Hive.openBox<String>(_paperBoxName);
    return _paperBox!;
  }

  @override
  Future<List<Exam>> getExams() async {
    final box = await _getExamBox();
    final List<Exam> list = [];
    for (final key in box.keys) {
      final jsonStr = box.get(key);
      if (jsonStr != null) {
        try {
          list.add(Exam.fromJson(jsonDecode(jsonStr)));
        } catch (_) {}
      }
    }
    return list;
  }

  @override
  Future<Exam?> getExamById(String examId) async {
    final box = await _getExamBox();
    final jsonStr = box.get(examId);
    if (jsonStr == null) return null;
    try {
      return Exam.fromJson(jsonDecode(jsonStr));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Paper>> getPapers({String? examId, int? year}) async {
    final box = await _getPaperBox();
    final List<Paper> list = [];
    for (final key in box.keys) {
      final jsonStr = box.get(key);
      if (jsonStr != null) {
        try {
          final paper = Paper.fromJson(jsonDecode(jsonStr));
          if (examId != null && paper.examId != examId) continue;
          if (year != null && paper.year != year) continue;
          list.add(paper);
        } catch (_) {}
      }
    }
    list.sort((a, b) => b.year.compareTo(a.year));
    return list;
  }

  @override
  Future<List<int>> getAvailableYears({String? examId}) async {
    final papers = await getPapers(examId: examId);
    final years = papers.map((p) => p.year).toSet().toList();
    years.sort((a, b) => b.compareTo(a));
    return years;
  }

  @override
  Future<void> saveExam(Exam exam) async {
    final box = await _getExamBox();
    await box.put(exam.examId, jsonEncode(exam.toJson()));
  }

  @override
  Future<void> savePaper(Paper paper) async {
    final box = await _getPaperBox();
    await box.put(paper.paperId, jsonEncode(paper.toJson()));
  }

  @override
  Future<void> clear() async {
    final eBox = await _getExamBox();
    final pBox = await _getPaperBox();
    await eBox.clear();
    await pBox.clear();
  }
}
