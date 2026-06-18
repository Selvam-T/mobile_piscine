import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/diary_entry.dart';

class DiaryService {
  DiaryService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String notesCollection = 'notes';

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _notes =>
      _firestore.collection(notesCollection);

  Future<String> createEntry(DiaryEntry entry) async {
    final DocumentReference<Map<String, dynamic>> document = await _notes.add(
      entry.toMap(),
    );

    return document.id;
  }

  Stream<List<DiaryEntry>> getEntries(String uid) {
    return _notes.where('uid', isEqualTo: uid).snapshots().map((
      QuerySnapshot<Map<String, dynamic>> snapshot,
    ) {
      final List<DiaryEntry> entries = snapshot.docs
          .map(_entryFromDocument)
          .nonNulls
          .toList();

      entries.sort(
        (DiaryEntry first, DiaryEntry second) =>
            second.date.compareTo(first.date),
      );

      return entries;
    });
  }

  Stream<List<DiaryEntry>> getLastEntries(String uid, {int limit = 2}) {
    return _notes
        .where('uid', isEqualTo: uid)
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map(_entriesFromSnapshot);
  }

  Stream<List<DiaryEntry>> getEntriesForDate(String uid, DateTime date) {
    final DateTime startOfDay = DateTime(date.year, date.month, date.day);
    final DateTime startOfNextDay = startOfDay.add(const Duration(days: 1));

    return _notes
        .where('uid', isEqualTo: uid)
        .where(
          'date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          isLessThan: Timestamp.fromDate(startOfNextDay),
        )
        .orderBy('date', descending: true)
        .snapshots()
        .map(_entriesFromSnapshot);
  }

  Future<DiaryEntry?> getEntryById(String entryId) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot = await _notes
        .doc(entryId)
        .get();

    if (!snapshot.exists) {
      return null;
    }

    return _entryFromDocument(snapshot);
  }

  Future<void> deleteEntry(String entryId) {
    return _notes.doc(entryId).delete();
  }

  List<DiaryEntry> _entriesFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs.map(_entryFromDocument).nonNulls.toList();
  }

  DiaryEntry? _entryFromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final Map<String, dynamic>? data = document.data();

    if (data == null) {
      return null;
    }

    return DiaryEntry.tryFromMap(data, id: document.id);
  }
}
