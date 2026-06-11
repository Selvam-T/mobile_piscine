import 'package:cloud_firestore/cloud_firestore.dart';

class DiaryEntry {
  const DiaryEntry({
    this.id,
    required this.uid,
    required this.usermail,
    required this.date,
    required this.icon,
    required this.title,
    required this.text,
  });

  final String? id;
  final String uid;
  final String usermail;
  final Timestamp date;
  final String icon;
  final String title;
  final String text;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'usermail': usermail,
      'date': date,
      'icon': icon,
      'title': title,
      'text': text,
    };
  }

  factory DiaryEntry.fromMap(Map<String, dynamic> map, {String? id}) {
    return DiaryEntry(
      id: id,
      uid: map['uid'] as String,
      usermail: map['usermail'] as String,
      date: map['date'] as Timestamp,
      icon: map['icon'] as String,
      title: map['title'] as String,
      text: map['text'] as String,
    );
  }

  static DiaryEntry? tryFromMap(Map<String, dynamic> map, {String? id}) {
    final Object? uid = map['uid'];
    final Object? usermail = map['usermail'];
    final Object? date = map['date'];
    final Object? icon = map['icon'];
    final Object? title = map['title'];
    final Object? text = map['text'];

    if (uid is! String ||
        date is! Timestamp ||
        icon is! String ||
        title is! String) {
      return null;
    }

    return DiaryEntry(
      id: id,
      uid: uid,
      usermail: usermail is String ? usermail : '',
      date: date,
      icon: icon,
      title: title,
      text: text is String ? text : '',
    );
  }
}
