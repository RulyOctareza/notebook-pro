/// Derives a short title from the first sentence of [plainText].
///
/// Takes at most [maxWords] words from the first sentence (split on `.` `!`
/// `?` `…`). Returns an empty string when there is no usable text.
String deriveTitleFromBody(String plainText, {int maxWords = 6}) {
  final trimmed = plainText.trim();
  if (trimmed.isEmpty) return '';

  final firstSentence = trimmed
      .split(RegExp(r'[.!?…\n]'))
      .map((s) => s.trim())
      .firstWhere((s) => s.isNotEmpty, orElse: () => '');

  if (firstSentence.isEmpty) return '';

  final words = firstSentence
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .take(maxWords)
      .toList();

  return words.join(' ');
}

/// Loose URL detector for clipboard / paste flows.
bool looksLikeUrl(String? value) {
  if (value == null) return false;
  final text = value.trim();
  if (text.isEmpty || text.contains(RegExp(r'\s'))) return false;
  final uri = Uri.tryParse(text);
  if (uri == null) return false;
  if (uri.hasScheme) {
    return uri.scheme == 'http' ||
        uri.scheme == 'https' ||
        uri.scheme == 'mailto';
  }
  // Bare domains like example.com/path
  return RegExp(
    r'^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z]{2,})+(/.*)?$',
  ).hasMatch(text);
}

String normalizeUrl(String value) {
  final text = value.trim();
  final uri = Uri.tryParse(text);
  if (uri != null && uri.hasScheme) return text;
  return 'https://$text';
}
