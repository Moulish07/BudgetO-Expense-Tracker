import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'expense.g.dart'; // <--- The red error is totally normal until you run the build command!

@HiveType(typeId: 0)
class Expense extends HiveObject {
  @HiveField(0)
  final String title;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final String category;

  @HiveField(4)
  final bool isIncome;

  @HiveField(5)
  final bool isOnline;

  @HiveField(6)
  final String id;

  @HiveField(7)
  final String? description;

  Expense({
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.isIncome,
    required this.id,
    this.isOnline = true,
    this.description,
  });

  // --- FIREBASE SYNC METHODS ---

  // Converts the Hive object into a format Firestore can save
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': Timestamp.fromDate(
        date,
      ), // Firestore requires Timestamps, not DateTimes
      'category': category,
      'isIncome': isIncome,
      'isOnline': isOnline,
      'description': description,
    };
  }

  // Creates a Hive object from downloaded Firestore data
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] ?? '',
      title: map['title'] ?? 'Unknown',
      amount: (map['amount'] ?? 0.0).toDouble(),
      date: (map['date'] as Timestamp)
          .toDate(), // Converts back to Dart DateTime
      category: map['category'] ?? 'Other',
      isIncome: map['isIncome'] ?? false,
      isOnline: map['isOnline'] ?? true,
      description: map['description'],
    );
  }
}
