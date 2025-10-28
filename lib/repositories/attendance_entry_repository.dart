import '../apis/attendance_api.dart';
import '../apis/auth_api.dart' show ApiException;
import '../models/attendance_request.dart';
import '../models/missed_attendance_completion.dart';
import '../utils/session_manager.dart';

class AttendanceEntryRepository {
  AttendanceEntryRepository({
    AttendanceApi? api,
    SessionManager? sessionManager,
  })  : _api = api ?? AttendanceApi(),
        _sessionManager = sessionManager ?? const SessionManager();

  final AttendanceApi _api;
  final SessionManager _sessionManager;

  Future<List<DateTime>> fetchMissedAttendanceDates({
    required String workId,
  }) async {
    final token = await _sessionManager.getToken();
    if (token == null || token.isEmpty) {
      throw const AttendanceAuthException();
    }

    try {
      return await _api.fetchMissedAttendanceDates(workId: workId, token: token);
    } on ApiException catch (e) {
      throw AttendanceRepositoryException(e.message);
    }
  }

  Future<Map<String, dynamic>?> previewAttendance({
    required String workId,
    required DateTime date,
    bool isLeave = false,
    String? startTime,
    String? endTime,
    int? breakMinutes,
    bool? isContractEntry,
    int? contractTypeId,
    num? units,
    num? ratePerUnit,
  }) async {
    final token = await _sessionManager.getToken();
    if (token == null || token.isEmpty) {
      throw const AttendanceAuthException();
    }

    final request = _buildRequest(
      workId: workId,
      date: date,
      isLeave: isLeave,
      startTime: startTime,
      endTime: endTime,
      breakMinutes: breakMinutes,
      isContractEntry: isContractEntry,
      contractTypeId: contractTypeId,
      units: units,
      ratePerUnit: ratePerUnit,
    );

    try {
      return await _api.previewAttendance(
        request: request,
        token: token,
      );
    } on ApiException catch (e) {
      throw AttendanceRepositoryException(e.message);
    }
  }

  Future<Map<String, dynamic>?> submitAttendance({
    required String workId,
    required DateTime date,
    bool isLeave = false,
    String? startTime,
    String? endTime,
    int? breakMinutes,
    bool? isContractEntry,
    int? contractTypeId,
    num? units,
    num? ratePerUnit,
  }) async {
    final token = await _sessionManager.getToken();
    if (token == null || token.isEmpty) {
      throw const AttendanceAuthException();
    }

    final defaultedContractTypeId = contractTypeId ?? 1;

    final request = _buildRequest(
      workId: workId,
      date: date,
      isLeave: isLeave,
      startTime: startTime,
      endTime: endTime,
      breakMinutes: breakMinutes,
      isContractEntry: isContractEntry,
      contractTypeId: defaultedContractTypeId,
      units: units,
      ratePerUnit: ratePerUnit,
    );

    try {
      return await _api.submitAttendance(
        request: request,
        token: token,
      );
    } on ApiException catch (e) {
      throw AttendanceRepositoryException(e.message);
    }
  }

  Future<Map<String, dynamic>?> completeMissedAttendance({
    required List<MissedAttendanceCompletion> entries,
  }) async {
    if (entries.isEmpty) {
      return null;
    }

    final token = await _sessionManager.getToken();
    if (token == null || token.isEmpty) {
      throw const AttendanceAuthException();
    }

    final request = MissedAttendanceCompletionRequest(items: entries);

    try {
      return await _api.completeMissedAttendance(
        request: request,
        token: token,
      );
    } on ApiException catch (e) {
      throw AttendanceRepositoryException(e.message);
    }
  }

  AttendanceRequest _buildRequest({
    required String workId,
    required DateTime date,
    required bool isLeave,
    String? startTime,
    String? endTime,
    int? breakMinutes,
    bool? isContractEntry,
    int? contractTypeId,
    num? units,
    num? ratePerUnit,
  }) {
    final payloadWorkId = int.tryParse(workId) ?? workId;
    return AttendanceRequest(
      workId: payloadWorkId,
      date: date,
      isLeave: isLeave,
      startTime: startTime,
      endTime: endTime,
      breakMinutes: breakMinutes,
      isContractEntry: isContractEntry,
      contractTypeId: contractTypeId,
      units: units,
      ratePerUnit: ratePerUnit,
    );
  }
}

class AttendanceRepositoryException implements Exception {
  const AttendanceRepositoryException(this.message);
  final String message;
}

class AttendanceAuthException extends AttendanceRepositoryException {
  const AttendanceAuthException() : super('Authentication required');
}
