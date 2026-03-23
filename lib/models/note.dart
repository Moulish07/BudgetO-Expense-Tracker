import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'note.g.dart'; // <--- The red error is totally normal until you run the build command!

@HiveType(typeId: 1)
class Note extends HiveObject {
  @HiveField(0)
  String content;

  @HiveField(1)
  DateTime date; // Added to match the logic in main.dart

  Note({required this.content, required this.date});

  // --- FIREBASE SYNC METHODS ---

  // Converts the Hive object into a format Firestore can save
  Map<String, dynamic> toMap() {
    return {'content': content, 'date': Timestamp.fromDate(date)};
  }

  // Creates a Hive object from downloaded Firestore data
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      content: map['content'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
    );
  }
}
