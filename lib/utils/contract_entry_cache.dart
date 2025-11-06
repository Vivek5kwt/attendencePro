import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ContractEntryCacheData {
  const ContractEntryCacheData({
    required this.isEnabled,
    required this.entries,
  });

  final bool isEnabled;
  final List<ContractEntryCacheItem> entries;
}

class ContractEntryCacheItem {
  const ContractEntryCacheItem({this.contractTypeId, this.units});

  final String? contractTypeId;
  final String? units;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'contractTypeId': contractTypeId,
      'units': units,
    };
  }

  factory ContractEntryCacheItem.fromJson(Map<String, dynamic> json) {
    return ContractEntryCacheItem(
      contractTypeId: _resolveString(json['contractTypeId']),
      units: _resolveString(json['units']),
    );
  }

  static String? _resolveString(Object? value) {
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (value == null) {
      return null;
    }
    return value.toString();
  }
}

class ContractEntryCache {
  static const String _storagePrefix = 'contract_entry_cache';

  static Future<ContractEntryCacheData?> load(String workId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_buildKey(workId));
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        await prefs.remove(_buildKey(workId));
        return null;
      }
      final entriesData = decoded['entries'];
      final isEnabled = decoded['enabled'] == true;
      final items = <ContractEntryCacheItem>[];
      if (entriesData is List) {
        for (final entry in entriesData) {
          if (entry is Map<String, dynamic>) {
            items.add(ContractEntryCacheItem.fromJson(entry));
          } else if (entry is Map) {
            items.add(
              ContractEntryCacheItem.fromJson(
                entry.cast<dynamic, dynamic>()
                    .map((key, value) => MapEntry(key.toString(), value)),
              ),
            );
          }
        }
      }
      return ContractEntryCacheData(isEnabled: isEnabled, entries: items);
    } catch (_) {
      await prefs.remove(_buildKey(workId));
      return null;
    }
  }

  static Future<void> save({
    required String workId,
    required bool isEnabled,
    required List<ContractEntryCacheItem> entries,
  }) async {
    final filtered = entries
        .where((entry) =>
            (entry.contractTypeId?.trim().isNotEmpty ?? false) ||
            (entry.units?.trim().isNotEmpty ?? false))
        .toList(growable: false);
    if (!isEnabled || filtered.isEmpty) {
      await clear(workId);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final payload = <String, dynamic>{
      'enabled': isEnabled,
      'entries': filtered.map((entry) => entry.toJson()).toList(),
    };
    await prefs.setString(_buildKey(workId), jsonEncode(payload));
  }

  static Future<void> clear(String workId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_buildKey(workId));
  }

  static String _buildKey(String workId) => '$_storagePrefix::$workId';
}
