import '../models/live_models.dart';
import '../repository/live_class_repository.dart';

/// Use case for recording student attendance in a live class.
class MarkAttendanceUseCase {
  final LiveClassRepository repository;

  const MarkAttendanceUseCase(this.repository);

  Future<Attendance> execute(Attendance attendance) {
    return repository.recordAttendance(attendance);
  }
}
