import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/contract_type.dart';
import 'auth_api.dart';
import 'logging_client.dart';

class ContractTypeApi {
  ContractTypeApi({
    this.baseUrl = 'https://attendancepro.shauryacoder.com',
    http.Client? httpClient,
  }) : _client = LoggingClient(httpClient);

  final String baseUrl;
  final http.Client _client;

  Future<ContractTypeCollection> fetchContractTypes({required String token}) async {
    final uri = Uri.parse('$baseUrl/api/contract-types');
    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await _client.get(uri, headers: headers);
      final decoded = _decodeBody(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _parseContractTypes(decoded);
      }

      throw ApiException(_extractErrorMessage(decoded, response.statusCode));
    } on SocketException {
      throw ApiException('Unable to reach the server. Please check your connection.');
    } on HttpException {
      throw ApiException('A network error occurred while contacting the server.');
    } on FormatException {
      throw ApiException('Received an invalid response from the server.');
    }
  }

  Future<ContractType> createContractType({
    required String token,
    required String name,
    required String subtype,
    required double ratePerUnit,
    required String unitLabel,
  }) async {
    final uri = Uri.parse('$baseUrl/api/contract-types');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final payload = jsonEncode({
      'name': name,
      'subtype': subtype,
      'rate_per_unit': ratePerUnit,
      'unit_label': unitLabel,
    });

    try {
      final response = await _client.post(uri, headers: headers, body: payload);
      final decoded = _decodeBody(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _parseSingleContractType(decoded);
      }

      throw ApiException(_extractErrorMessage(decoded, response.statusCode));
    } on SocketException {
      throw ApiException('Unable to reach the server. Please check your connection.');
    } on HttpException {
      throw ApiException('A network error occurred while contacting the server.');
    } on FormatException {
      throw ApiException('Received an invalid response from the server.');
    }
  }

  Future<ContractType> updateContractType({
    required String token,
    required String contractTypeId,
    required String name,
    required String subtype,
    required double ratePerUnit,
    required String unitLabel,
  }) async {
    final encodedId = Uri.encodeComponent(contractTypeId);
    final uri = Uri.parse('$baseUrl/api/contract-types/$encodedId');
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final payload = jsonEncode({
      'name': name,
      'subtype': subtype,
      'rate_per_unit': ratePerUnit,
      'unit_label': unitLabel,
    });

    try {
      final response = await _client.put(uri, headers: headers, body: payload);
      final decoded = _decodeBody(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _parseSingleContractType(decoded);
      }

      throw ApiException(_extractErrorMessage(decoded, response.statusCode));
    } on SocketException {
      throw ApiException('Unable to reach the server. Please check your connection.');
    } on HttpException {
      throw ApiException('A network error occurred while contacting the server.');
    } on FormatException {
      throw ApiException('Received an invalid response from the server.');
    }
  }

  ContractTypeCollection _parseContractTypes(Map<String, dynamic>? decoded) {
    final data = _extractDataNode(decoded);
    final globalRaw = _extractList(data, const [
      'global',
      'global_types',
      'globalTypes',
      'global_contracts',
      'globalContracts',
      'default',
      'default_types',
      'defaultTypes',
    ]);
    final userRaw = _extractList(data, const [
      'user',
      'user_types',
      'userTypes',
      'user_contracts',
      'userContracts',
      'user_contract_types',
      'userContractTypes',
      'custom',
      'custom_types',
      'customTypes',
      'mine',
      'my',
    ]);

    final itemsRaw = _extractList(data, const [
      'items',
      'contracts',
      'contract_types',
      'contractTypes',
      'user_contracts',
      'userContracts',
      'mine',
      'my',
      'data',
    ]);

    final global = globalRaw
        .map((item) => ContractType.fromJson(item))
        .toList(growable: false);
    final user = userRaw
        .map((item) => ContractType.fromJson(item))
        .toList(growable: false);

    if (global.isNotEmpty || user.isNotEmpty) {
      return ContractTypeCollection(globalTypes: global, userTypes: user);
    }

    final parsedItems = itemsRaw
        .map((item) => ContractType.fromJson(item))
        .toList(growable: false);

    if (parsedItems.isEmpty) {
      return const ContractTypeCollection(globalTypes: [], userTypes: []);
    }

    final partitionedGlobal = <ContractType>[];
    final partitionedUser = <ContractType>[];
    for (final item in parsedItems) {
      if (item.isGlobal || item.isDefault) {
        partitionedGlobal.add(item);
      } else {
        partitionedUser.add(item);
      }
    }

    return ContractTypeCollection(
      globalTypes: partitionedGlobal,
      userTypes: partitionedUser,
    );
  }

  ContractType _parseSingleContractType(Map<String, dynamic>? decoded) {
    Map<String, dynamic>? resolve() {
      final dataNode = _extractDataNode(decoded);
      if (dataNode == null) {
        return null;
      }

      if (_looksLikeContractTypeMap(dataNode)) {
        return dataNode;
      }

      const possibleKeys = [
        'contract_type',
        'contractType',
        'item',
        'result',
      ];

      for (final key in possibleKeys) {
        final value = dataNode[key];
        if (value is Map<String, dynamic>) {
          return value;
        }
      }

      return dataNode;
    }

    final map = resolve();
    if (map == null || map.isEmpty) {
      throw ApiException('Contract type response missing data.');
    }

    return ContractType.fromJson(map);
  }

  bool _looksLikeContractTypeMap(Map<String, dynamic> map) {
    const requiredKeys = ['name', 'rate', 'rate_per_unit', 'unit_label', 'unitLabel'];
    for (final key in requiredKeys) {
      if (map.containsKey(key)) {
        return true;
      }
    }
    return false;
  }

  Map<String, dynamic>? _decodeBody(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {'data': decoded};
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? _extractDataNode(Map<String, dynamic>? decoded) {
    if (decoded == null) {
      return null;
    }

    final possibleKeys = [
      'data',
      'result',
      'payload',
      'contracts',
      'contract_types',
      'contractTypes',
      'response',
    ];

    for (final key in possibleKeys) {
      final value = decoded[key];
      if (value is Map<String, dynamic>) {
        return value;
      }
    }

    return decoded;
  }

  List<Map<String, dynamic>> _extractList(
    Map<String, dynamic>? data,
    List<String> keys,
  ) {
    if (data == null) return const [];

    for (final key in keys) {
      final value = data[key];
      if (value == null) {
        continue;
      }

      if (value is List) {
        return value
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
      }

      if (value is Map<String, dynamic>) {
        // Some responses embed lists under a nested "data" key
        final nested = value['data'];
        if (nested is List) {
          return nested
              .whereType<Map<String, dynamic>>()
              .toList(growable: false);
        }
      }
    }

    return const [];
  }

  String _extractErrorMessage(Map<String, dynamic>? decoded, int statusCode) {
    if (decoded == null) {
      return 'Request failed with status: $statusCode';
    }

    final possibleKeys = ['message', 'error', 'detail', 'status'];
    for (final key in possibleKeys) {
      final value = decoded[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return 'Request failed with status: $statusCode';
  }
}
