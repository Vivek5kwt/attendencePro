import '../apis/attendance_api.dart';
import '../apis/auth_api.dart' show ApiException;
import '../utils/session_manager.dart';

class AttendanceEntryRepository {
  AttendanceEntryRepository({
    AttendanceApi? api,
    SessionManager? sessionManager,
  })  : _api = api ?? AttendanceApi(),
        _sessionManager = sessionManager ?? const SessionManager();

  final AttendanceApi _api;
  final SessionManager _sessionManager;

  Future<Map<String, dynamic>?> submitAttendance({
    required String workId,
    required DateTime date,
    required String startTime,
    required String endTime,
    required int breakMinutes,
    bool isContractEntry = false,
    int? contractTypeId,
    num? units,
    num? ratePerUnit,
  }) async {
    final token = await _sessionManager.getToken();
    if (token == null || token.isEmpty) {
      throw const AttendanceAuthException();
    }

    final payloadWorkId = int.tryParse(workId) ?? workId;

    try {
      return await _api.submitAttendance(
        workId: payloadWorkId,
        date: date,
        startTime: startTime,
        endTime: endTime,
        breakMinutes: breakMinutes,
        isContractEntry: isContractEntry,
        contractTypeId: contractTypeId,
        units: units,
        ratePerUnit: ratePerUnit,
        token: token,
      );
    } on ApiException catch (e) {
      throw AttendanceRepositoryException(e.message);
    }
  }
}

class AttendanceRepositoryException implements Exception {
  const AttendanceRepositoryException(this.message);
  final String message;
}

class AttendanceAuthException extends AttendanceRepositoryException {
  const AttendanceAuthException() : super('Authentication required');
}
