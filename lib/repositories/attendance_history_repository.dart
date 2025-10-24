import '../apis/attendance_api.dart';
import '../apis/auth_api.dart' show ApiException;
import '../models/attendance_history.dart';
import '../utils/session_manager.dart';

class AttendanceHistoryRepository {
  AttendanceHistoryRepository({
    AttendanceApi? api,
    SessionManager? sessionManager,
  })  : _api = api ?? AttendanceApi(),
        _sessionManager = sessionManager ?? const SessionManager();

  final AttendanceApi _api;
  final SessionManager _sessionManager;

  Future<AttendanceHistoryData> fetchHistory({
    required String workId,
    required String workName,
    required int month,
    required int year,
  }) async {
    final token = await _sessionManager.getToken();
    if (token == null || token.isEmpty) {
      throw const AttendanceHistoryAuthException();
    }

    try {
      return await _api.fetchAttendanceHistory(
        workId: workId,
        month: month,
        year: year,
        token: token,
        fallbackWorkName: workName,
      );
    } on ApiException catch (e) {
      throw AttendanceHistoryRepositoryException(e.message);
    }
  }
}

class AttendanceHistoryRepositoryException implements Exception {
  const AttendanceHistoryRepositoryException(this.message);

  final String message;
}

class AttendanceHistoryAuthException
    extends AttendanceHistoryRepositoryException {
  const AttendanceHistoryAuthException()
      : super('Authentication required');
}
