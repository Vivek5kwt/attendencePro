import '../models/student.dart';

abstract class AttendanceState {}

class AttendanceInitial extends AttendanceState {}

class AttendanceLoading extends AttendanceState {}

class AttendanceLoaded extends AttendanceState {
  final List<Student> students;
  final DateTime lastSaved;
  AttendanceLoaded({required this.students, DateTime? lastSaved})
      : lastSaved = lastSaved ?? DateTime.fromMillisecondsSinceEpoch(0);

  int get total => students.length;
  int get present => students.where((s) => s.isPresent).length;
  int get absent => total - present;

  AttendanceLoaded copyWith({List<Student>? students, DateTime? lastSaved}) {
    return AttendanceLoaded(
      students: students ?? this.students,
      lastSaved: lastSaved ?? this.lastSaved,
    );
  }
}

class AttendanceError extends AttendanceState {
  final String message;
  AttendanceError(this.message);
}