import 'package:flutter_test/flutter_test.dart';
import 'package:notebook_pro/features/notes/domain/title_from_body.dart';

void main() {
  group('deriveTitleFromBody', () {
    test('takes up to 6 words from first sentence', () {
      expect(
        deriveTitleFromBody(
          'Satu dua tiga empat lima enam tujuh delapan. Next.',
        ),
        'Satu dua tiga empat lima enam',
      );
    });

    test('stops at sentence boundary before 6 words', () {
      expect(
        deriveTitleFromBody('Hello world. More text here.'),
        'Hello world',
      );
    });

    test('uses first non-empty line when no punctuation', () {
      expect(
        deriveTitleFromBody('Catatan pagi ini tentang fokus\nbaris dua'),
        'Catatan pagi ini tentang fokus',
      );
    });

    test('returns empty for blank body', () {
      expect(deriveTitleFromBody('   \n  '), '');
    });
  });

  group('looksLikeUrl', () {
    test('accepts https urls', () {
      expect(looksLikeUrl('https://example.com/a'), isTrue);
    });

    test('accepts bare domains', () {
      expect(looksLikeUrl('example.com'), isTrue);
    });

    test('rejects sentences', () {
      expect(looksLikeUrl('hello world'), isFalse);
    });
  });
}
