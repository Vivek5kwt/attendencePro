abstract class AttendanceEvent {}

class LoadStudents extends AttendanceEvent {}

class AddStudent extends AttendanceEvent {
  final String name;
  AddStudent(this.name);
}

class ToggleAttendance extends AttendanceEvent {
  final String studentId;
  ToggleAttendance(this.studentId);
}

class MarkAllPresent extends AttendanceEvent {}

class MarkAllAbsent extends AttendanceEvent {}

class SaveAttendance extends AttendanceEvent {}