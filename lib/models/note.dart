import 'package:hive/hive.dart';

part 'note.g.dart'; // <--- ADD THIS LINE

@HiveType(typeId: 1)
class Note extends HiveObject {
  @HiveField(0) String content;

  Note({required this.content});
}