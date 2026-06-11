import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diary_app/models/diary_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DiaryEntry', () {
    test('converts to a Firestore map', () {
      final Timestamp date = Timestamp.fromDate(DateTime(2026, 6, 10));
      final DiaryEntry entry = DiaryEntry(
        id: 'entry-1',
        uid: 'user-123',
        usermail: 'student@example.com',
        date: date,
        icon: 'satisfied',
        title: 'First entry',
        text: 'Today I connected my diary model.',
      );

      expect(entry.toMap(), <String, dynamic>{
        'uid': 'user-123',
        'usermail': 'student@example.com',
        'date': date,
        'icon': 'satisfied',
        'title': 'First entry',
        'text': 'Today I connected my diary model.',
      });
    });

    test('converts from a Firestore map', () {
      final Timestamp date = Timestamp.fromDate(DateTime(2026, 6, 10));
      final DiaryEntry entry = DiaryEntry.fromMap(<String, dynamic>{
        'uid': 'user-123',
        'usermail': 'student@example.com',
        'date': date,
        'icon': 'satisfied',
        'title': 'First entry',
        'text': 'Today I connected my diary model.',
      }, id: 'entry-1');

      expect(entry.id, 'entry-1');
      expect(entry.uid, 'user-123');
      expect(entry.usermail, 'student@example.com');
      expect(entry.date, date);
      expect(entry.icon, 'satisfied');
      expect(entry.title, 'First entry');
      expect(entry.text, 'Today I connected my diary model.');
    });

    test(
      'returns null when a Firestore map is missing required list fields',
      () {
        final DiaryEntry? entry = DiaryEntry.tryFromMap(<String, dynamic>{
          'uid': 'user-123',
          'usermail': 'student@example.com',
          'icon': 'satisfied',
          'title': 'First entry',
          'text': 'Missing a Timestamp date.',
        });

        expect(entry, isNull);
      },
    );
  });
}
