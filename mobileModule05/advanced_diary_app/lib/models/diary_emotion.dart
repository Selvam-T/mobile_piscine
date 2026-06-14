class DiaryEmotion {
  const DiaryEmotion({
    required this.value,
    required this.label,
    required this.emoji,
  });

  final String value;
  final String label;
  final String emoji;

  static const List<DiaryEmotion> options = <DiaryEmotion>[
    DiaryEmotion(value: 'happy', label: 'Happy', emoji: '😊'),
    DiaryEmotion(value: 'sad', label: 'Sad', emoji: '😢'),
    DiaryEmotion(value: 'neutral', label: 'Neutral', emoji: '😐'),
    DiaryEmotion(value: 'angry', label: 'Angry', emoji: '😡'),
    DiaryEmotion(value: 'tired', label: 'Tired', emoji: '😴'),
    DiaryEmotion(value: 'excited', label: 'Excited', emoji: '🤩'),
    DiaryEmotion(value: 'anxious', label: 'Anxious', emoji: '😰'),
    DiaryEmotion(value: 'satisfied', label: 'Satisfied', emoji: '🙂'),
  ];

  static DiaryEmotion? findByValue(String value) {
    final String normalizedValue = value.trim().toLowerCase();

    for (final DiaryEmotion emotion in options) {
      if (emotion.value == normalizedValue) {
        return emotion;
      }
    }

    return null;
  }

  static String emojiFor(String value) {
    return findByValue(value)?.emoji ?? value;
  }
}
