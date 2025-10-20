import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../models/student.dart';
import '../repositories/attendance_repository.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final AttendanceRepository repository;

  AttendanceBloc({required this.repository}) : super(AttendanceInitial()) {
    on<LoadStudents>(_onLoadStudents);
    on<AddStudent>(_onAddStudent);
    on<ToggleAttendance>(_onToggleAttendance);
    on<MarkAllPresent>(_onMarkAllPresent);
    on<MarkAllAbsent>(_onMarkAllAbsent);
    on<SaveAttendance>(_onSaveAttendance);
  }

  Future<void> _onLoadStudents(LoadStudents event, Emitter<AttendanceState> emit) async {
    emit(AttendanceLoading());
    try {
      final students = await repository.loadStudents();
      emit(AttendanceLoaded(students: students));
    } catch (e) {
      emit(AttendanceError('Failed to load students'));
    }
  }

  Future<void> _onAddStudent(AddStudent event, Emitter<AttendanceState> emit) async {
    final current = state;
    if (current is AttendanceLoaded) {
      final newStudents = List<Student>.from(current.students)
        ..add(Student(id: const Uuid().v4(), name: event.name));
      emit(current.copyWith(students: newStudents));
    }
  }

  Future<void> _onToggleAttendance(ToggleAttendance event, Emitter<AttendanceState> emit) async {
    final current = state;
    if (current is AttendanceLoaded) {
      final newStudents = current.students.map((s) {
        if (s.id == event.studentId) {
          return s.copyWith(isPresent: !s.isPresent);
        }
        return s;
      }).toList();
      emit(current.copyWith(students: newStudents));
    }
  }

  Future<void> _onMarkAllPresent(MarkAllPresent event, Emitter<AttendanceState> emit) async {
    final current = state;
    if (current is AttendanceLoaded) {
      final newStudents = current.students.map((s) => s.copyWith(isPresent: true)).toList();
      emit(current.copyWith(students: newStudents));
    }
  }

  Future<void> _onMarkAllAbsent(MarkAllAbsent event, Emitter<AttendanceState> emit) async {
    final current = state;
    if (current is AttendanceLoaded) {
      final newStudents = current.students.map((s) => s.copyWith(isPresent: false)).toList();
      emit(current.copyWith(students: newStudents));
    }
  }

  Future<void> _onSaveAttendance(SaveAttendance event, Emitter<AttendanceState> emit) async {
    final current = state;
    if (current is AttendanceLoaded) {
      emit(AttendanceLoading());
      try {
        await repository.saveStudents(current.students);
        emit(current.copyWith(lastSaved: DateTime.now()));
      } catch (e) {
        emit(AttendanceError('Failed to save attendance'));
      }
    }
  }
}
