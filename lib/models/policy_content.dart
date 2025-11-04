import 'package:meta/meta.dart';

@immutable
class PolicyContent {
  const PolicyContent({
    required this.title,
    required this.content,
    this.lastUpdated,
    this.rawLastUpdated,
  });

  final String title;

  final String content;

  final DateTime? lastUpdated;

  final String? rawLastUpdated;

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

  String get normalizedContent {
    final lines = content.split('\n');
    final trimmed = lines.map((line) => line.trim()).toList();
    return trimmed.join('\n').trim();
  }

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
