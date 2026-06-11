import 'package:diary_app/models/diary_emotion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DiaryEmotion', () {
    test('maps stored emotion text to emoji', () {
      expect(DiaryEmotion.emojiFor('happy'), '😊');
      expect(DiaryEmotion.emojiFor('sad'), '😢');
      expect(DiaryEmotion.emojiFor('neutral'), '😐');
      expect(DiaryEmotion.emojiFor('angry'), '😡');
      expect(DiaryEmotion.emojiFor('tired'), '😴');
      expect(DiaryEmotion.emojiFor('excited'), '🤩');
      expect(DiaryEmotion.emojiFor('anxious'), '😰');
      expect(DiaryEmotion.emojiFor('satisfied'), '🙂');
    });

    test('normalizes stored emotion text before lookup', () {
      expect(DiaryEmotion.emojiFor(' Happy '), '😊');
    });

    test('falls back to original text for unknown emotion values', () {
      expect(DiaryEmotion.emojiFor('curious'), 'curious');
    });
  });
}
