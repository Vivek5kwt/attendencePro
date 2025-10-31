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

class UpdateStudent extends AttendanceEvent {
  final String studentId;
  final String newName;

  UpdateStudent(this.studentId, this.newName);
}

class DeleteStudent extends AttendanceEvent {
  final String studentId;

  DeleteStudent(this.studentId);
}

class SaveAttendance extends AttendanceEvent {}
