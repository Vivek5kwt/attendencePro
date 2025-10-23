import '../apis/auth_api.dart';
import '../apis/dashboard_api.dart';
import '../models/dashboard_summary.dart';
import '../utils/session_manager.dart';

class DashboardRepository {
  DashboardRepository({
    DashboardApi? api,
    SessionManager? sessionManager,
  })  : _api = api ?? DashboardApi(),
        _sessionManager = sessionManager ?? const SessionManager();

  final DashboardApi _api;
  final SessionManager _sessionManager;

  Future<DashboardSummary> fetchSummary({required String workId}) async {
    final token = await _sessionManager.getToken();
    if (token == null || token.isEmpty) {
      throw const DashboardAuthException();
    }

    try {
      return await _api.fetchSummary(workId: workId, token: token);
    } on ApiException catch (e) {
      throw DashboardRepositoryException(e.message);
    }
  }
}

class DashboardRepositoryException implements Exception {
  const DashboardRepositoryException(this.message);
  final String message;
}

class DashboardAuthException extends DashboardRepositoryException {
  const DashboardAuthException() : super('Authentication required');
}
