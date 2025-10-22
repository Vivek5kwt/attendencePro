import 'package:attendancepro/models/student.dart';
import 'package:uuid/uuid.dart';

abstract class AttendanceRepository {
  Future<List<Student>> loadStudents();
  Future<void> saveStudents(List<Student> students);
}

class InMemoryAttendanceRepository implements AttendanceRepository {
  List<Student> _store = [
    Student(id: const Uuid().v4(), name: 'Alice'),
    Student(id: const Uuid().v4(), name: 'Bob'),
    Student(id: const Uuid().v4(), name: 'Charlie'),
  ];

  @override
  Future<List<Student>> loadStudents() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _store.map((s) => s.copyWith()).toList();
  }

  @override
  Future<void> saveStudents(List<Student> students) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _store = students.map((s) => s.copyWith()).toList();
  }
}