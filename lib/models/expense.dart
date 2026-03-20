import 'package:hive/hive.dart';

part 'expense.g.dart'; // <--- ADD THIS LINE (It will show an error for now, that's okay!)

@HiveType(typeId: 0)
class Expense extends HiveObject {
  @HiveField(0) String title;
  @HiveField(1) double amount;
  @HiveField(2) DateTime date;
  @HiveField(3) String category;
  @HiveField(4) bool isIncome; // <--- ADD THIS

  Expense({
    required this.title, 
    required this.amount, 
    required this.date, 
    required this.category,
    this.isIncome = false, // Default is expense
  });
}
