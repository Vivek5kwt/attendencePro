import 'package:meta/meta.dart';

/// Represents policy content such as terms & conditions or privacy policy.
@immutable
class PolicyContent {
  const PolicyContent({
    required this.title,
    required this.content,
    this.lastUpdated,
    this.rawLastUpdated,
  });

  /// The title returned by the API.
  final String title;

  /// The raw content text returned by the API.
  final String content;

  /// Parsed representation of [rawLastUpdated], if available.
  final DateTime? lastUpdated;

  /// The raw "last_updated" string returned by the API.
  final String? rawLastUpdated;

  /// Creates an instance from a JSON map.
  factory PolicyContent.fromJson(Map<String, dynamic> json) {
    final rawUpdated = json['last_updated']?.toString();
    DateTime? parsedUpdated;
    if (rawUpdated != null && rawUpdated.trim().isNotEmpty) {
      parsedUpdated = DateTime.tryParse(rawUpdated);
      parsedUpdated ??= DateTime.tryParse(rawUpdated.replaceFirst(' ', 'T'));
    }

    final title = (json['title'] as String?)?.trim() ?? '';
    final content = (json['content'] as String?) ?? '';

    return PolicyContent(
      title: title,
      content: content,
      lastUpdated: parsedUpdated,
      rawLastUpdated: rawUpdated,
    );
  }

  /// Returns a normalized version of [content] with trimmed lines.
  String get normalizedContent {
    final lines = content.split('\n');
    final trimmed = lines.map((line) => line.trim()).toList();
    return trimmed.join('\n').trim();
  }

  /// Returns the best-effort representation of the last updated label.
  String? get lastUpdatedLabel {
    final DateTime? dt = lastUpdated?.toLocal();
    if (dt != null) {
      String two(int value) => value.toString().padLeft(2, '0');
      final formatted =
          '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
      return formatted;
    }

    final raw = rawLastUpdated?.trim();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }
}
