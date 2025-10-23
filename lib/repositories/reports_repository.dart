import '../apis/reports_api.dart';
import '../models/report_summary.dart';
import '../utils/session_manager.dart';
import '../apis/auth_api.dart' show ApiException;

class ReportsRepository {
  ReportsRepository({
    ReportsApi? api,
    SessionManager? sessionManager,
  })  : _api = api ?? ReportsApi(),
        _sessionManager = sessionManager ?? const SessionManager();

  final ReportsApi _api;
  final SessionManager _sessionManager;

  Future<ReportSummary> fetchSummary({
    required String workId,
    required int month,
    required int year,
  }) async {
    String? token;
    try {
      token = await _sessionManager.getToken();
    } catch (_) {
      token = null;
    }

    try {
      return await _api.fetchSummary(
        workId: workId,
        month: month,
        year: year,
        token: token,
      );
    } on ApiException catch (e) {
      throw ReportsRepositoryException(e.message);
    }
  }
}

class ReportsRepositoryException implements Exception {
  const ReportsRepositoryException(this.message);
  final String message;
}
