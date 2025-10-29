import '../apis/reports_api.dart';
import '../models/monthly_report.dart';
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

  Future<MonthlyReport> fetchMonthlyReport({
    required int month,
    required int year,
    required MonthlyReportType type,
    String? fallbackUserId,
  }) async {
    String? token;
    String? userId = fallbackUserId;

    try {
      token = await _sessionManager.getToken();
    } catch (_) {
      token = null;
    }

    try {
      final storedUserId = await _sessionManager.getUserId();
      if (storedUserId != null && storedUserId.trim().isNotEmpty) {
        userId = storedUserId.trim();
      }
    } catch (_) {
      // Ignore retrieval errors and rely on fallback.
    }

    if (userId == null || userId.trim().isEmpty) {
      throw const ReportsRepositoryException(
        'Unable to determine user for monthly report.',
      );
    }

    try {
      return await _api.fetchMonthlyReport(
        userId: userId.trim(),
        month: month,
        year: year,
        type: type,
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
