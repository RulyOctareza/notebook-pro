final RegExp _hashtagRegex = RegExp(
  r'(?:^|[\s\n\r\(\[\{])#([a-zA-Z0-9_\-]+)',
  multiLine: true,
);

/// Extracts unique hashtag names (lowercase, without leading `#`) from text.
List<String> extractTagsFromText(String text) {
  if (text.isEmpty) return const [];
  final matches = _hashtagRegex.allMatches(text);
  final tags = <String>{};
  for (final m in matches) {
    final tag = m.group(1)?.toLowerCase().trim();
    if (tag != null && tag.isNotEmpty) {
      // Filter out pure numbers if desired or keep standard alphanumeric
      tags.add(tag);
    }
  }
  final sorted = tags.toList()..sort();
  return sorted;
}

/// Extracts combined tags from note title, plain body text, and optional explicit tags.
List<String> extractNoteTags({
  required String title,
  required String plainBody,
  List<String> explicitTags = const [],
}) {
  final fromTitle = extractTagsFromText(title);
  final fromBody = extractTagsFromText(plainBody);
  final combined = <String>{...fromTitle, ...fromBody};

  for (final tag in explicitTags) {
    final clean = tag.replaceAll('#', '').toLowerCase().trim();
    if (clean.isNotEmpty) {
      combined.add(clean);
    }
  }

  final sorted = combined.toList()..sort();
  return sorted;
}
