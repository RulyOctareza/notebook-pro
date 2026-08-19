import 'package:flutter_test/flutter_test.dart';
import 'package:notebook_pro/features/notes/domain/tag_extractor.dart';

void main() {
  group('TagExtractor', () {
    test('extracts single and multiple hashtags from text', () {
      const text = 'Meeting notes with #project-alpha and #flutter team #urgent';
      final tags = extractTagsFromText(text);

      expect(tags, containsAll(['project-alpha', 'flutter', 'urgent']));
      expect(tags.length, 3);
    });

    test('deduplicates and lowercases hashtags', () {
      const text = '#FLUTTER #Flutter #flutter and #Tech';
      final tags = extractTagsFromText(text);

      expect(tags, ['flutter', 'tech']);
    });

    test('extracts combined tags from title, plainBody, and explicit tags', () {
      final tags = extractNoteTags(
        title: 'Draft for #v2_release',
        plainBody: 'Remember to check #api and #performance tests',
        explicitTags: ['custom_tag', '#FLUTTER'],
      );

      expect(
        tags,
        containsAll([
          'api',
          'custom_tag',
          'flutter',
          'performance',
          'v2_release',
        ]),
      );
    });

    test('handles text with no hashtags gracefully', () {
      const text = 'Just a regular plain text without tags';
      final tags = extractTagsFromText(text);

      expect(tags, isEmpty);
    });
  });
}
