import 'package:flutter_test/flutter_test.dart';
import 'package:notebook_pro/features/notes/domain/note_content.dart';

void main() {
  test('empty title and body has no content', () {
    expect(noteHasContent(title: '', plainBody: '  \n'), isFalse);
  });

  test('title alone counts as content', () {
    expect(noteHasContent(title: 'Hello', plainBody: ''), isTrue);
  });

  test('body alone counts as content', () {
    expect(noteHasContent(title: '', plainBody: 'words here'), isTrue);
  });
}
