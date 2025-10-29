import '../apis/auth_api.dart';
import '../apis/contract_type_api.dart';
import '../models/contract_type.dart';
import '../utils/contract_type_normalizer.dart';
import '../utils/session_manager.dart';

class ContractTypeRepository {
  ContractTypeRepository({
    ContractTypeApi? api,
    SessionManager? sessionManager,
  })  : _api = api ?? ContractTypeApi(),
        _sessionManager = sessionManager ?? const SessionManager();

  final ContractTypeApi _api;
  final SessionManager _sessionManager;

  Future<ContractTypeCollection> fetchContractTypes() async {
    final token = await _sessionManager.getToken();
    if (token == null || token.isEmpty) {
      throw const ContractTypeAuthException();
    }

    try {
      return await _api.fetchContractTypes(token: token);
    } on ApiException catch (e) {
      throw ContractTypeRepositoryException(e.message);
    }
  }

  Future<ContractType> createContractType({
    required String name,
    required String subtype,
    required double ratePerUnit,
    required String unitLabel,
  }) async {
    final token = await _sessionManager.getToken();
    if (token == null || token.isEmpty) {
      throw const ContractTypeAuthException();
    }

    try {
      final normalizedSubtype = normalizeContractSubtype(subtype);
      return await _api.createContractType(
        token: token,
        name: name,
        subtype: normalizedSubtype,
        ratePerUnit: ratePerUnit,
        unitLabel: unitLabel,
      );
    } on ApiException catch (e) {
      throw ContractTypeRepositoryException(e.message);
    }
  }

  Future<ContractType> updateContractType({
    required String id,
    required String name,
    required String subtype,
    required double ratePerUnit,
    required String unitLabel,
  }) async {
    final token = await _sessionManager.getToken();
    if (token == null || token.isEmpty) {
      throw const ContractTypeAuthException();
    }

    try {
      final normalizedSubtype = normalizeContractSubtype(subtype);
      return await _api.updateContractType(
        token: token,
        contractTypeId: id,
        name: name,
        subtype: normalizedSubtype,
        ratePerUnit: ratePerUnit,
        unitLabel: unitLabel,
      );
    } on ApiException catch (e) {
      throw ContractTypeRepositoryException(e.message);
    }
  }

  Future<void> deleteContractType({
    required String id,
  }) async {
    final token = await _sessionManager.getToken();
    if (token == null || token.isEmpty) {
      throw const ContractTypeAuthException();
    }

    try {
      await _api.deleteContractType(
        token: token,
        contractTypeId: id,
      );
    } on ApiException catch (e) {
      throw ContractTypeRepositoryException(e.message);
    }
  }
}

class ContractTypeRepositoryException implements Exception {
  const ContractTypeRepositoryException(this.message);
  final String message;
}

class ContractTypeAuthException extends ContractTypeRepositoryException {
  const ContractTypeAuthException()
      : super('Authentication required to load contract types.');
}
