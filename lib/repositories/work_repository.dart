import '../apis/auth_api.dart';
import '../apis/work_api.dart';
import '../models/user_profile.dart';
import '../models/work.dart';
import '../utils/session_manager.dart';

class WorkRepository {
  WorkRepository({
    WorkApi? api,
    SessionManager? sessionManager,
  })  : _api = api ?? WorkApi(),
        _sessionManager = sessionManager ?? const SessionManager();

  final WorkApi _api;
  final SessionManager _sessionManager;

  Future<UserProfile> loadUserProfile() async {
    final details = await _sessionManager.getUserProfile();
    return UserProfile.fromSession(details);
  }

  Future<List<Work>> fetchWorks() async {
    final token = await _sessionManager.getToken();
    if (token == null || token.isEmpty) {
      throw const WorkAuthException();
    }
    try {
      return await _api.fetchWorks(token: token);
    } on ApiException catch (e) {
      throw WorkRepositoryException(e.message);
    }
  }

  Future<WorkActionResult> createWork({
    required String name,
    required num hourlyRate,
    required bool isContract,
  }) async {
    final token = await _sessionManager.getToken();
    if (token == null || token.isEmpty) {
      throw const WorkAuthException();
    }

    try {
      final response = await _api.createWork(
        name: name,
        hourlyRate: hourlyRate,
        isContract: isContract,
        token: token,
      );
      return WorkActionResult.from(response);
    } on ApiException catch (e) {
      throw WorkRepositoryException(e.message);
    }
  }

  Future<WorkActionResult> deleteWork(Work work) async {
    final token = await _sessionManager.getToken();
    if (token == null || token.isEmpty) {
      throw const WorkAuthException();
    }

    try {
      final response = await _api.deleteWork(id: work.id, token: token);
      return WorkActionResult.from(response);
    } on ApiException catch (e) {
      throw WorkRepositoryException(e.message);
    }
  }

  Future<WorkActionResult> updateWork({
    required Work work,
    required String name,
    required num hourlyRate,
    required bool isContract,
  }) async {
    final token = await _sessionManager.getToken();
    if (token == null || token.isEmpty) {
      throw const WorkAuthException();
    }

    try {
      final response = await _api.updateWork(
        id: work.id,
        name: name,
        hourlyRate: hourlyRate,
        isContract: isContract,
        token: token,
      );
      return WorkActionResult.from(response);
    } on ApiException catch (e) {
      throw WorkRepositoryException(e.message);
    }
  }

  Future<WorkActionResult> activateWork(Work work) async {
    final token = await _sessionManager.getToken();
    if (token == null || token.isEmpty) {
      throw const WorkAuthException();
    }

    try {
      final response = await _api.setActiveWork(id: work.id, token: token);
      return WorkActionResult.from(response);
    } on ApiException catch (e) {
      throw WorkRepositoryException(e.message);
    }
  }
}

class WorkActionResult {
  const WorkActionResult({this.message});

  factory WorkActionResult.from(Map<String, dynamic>? response) {
    if (response == null) {
      return const WorkActionResult();
    }

    const possibleKeys = ['message', 'status', 'detail'];
    for (final key in possibleKeys) {
      final value = response[key];
      if (value is String && value.trim().isNotEmpty) {
        return WorkActionResult(message: value.trim());
      }
    }

    return const WorkActionResult();
  }

  final String? message;
}

class WorkRepositoryException implements Exception {
  const WorkRepositoryException(this.message);
  final String message;
}

class WorkAuthException extends WorkRepositoryException {
  const WorkAuthException() : super('Authentication required');
}
