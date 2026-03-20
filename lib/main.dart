import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'models/expense.dart';
import 'models/note.dart';
import 'screens/splash_screen.dart';

class ExpenseProvider extends ChangeNotifier {
  List<Expense> _expenses = [];
  List<Expense> get expenses => _expenses;

  // 1. Logic for the Real Balance (Income - Expense)
  double get totalBalance {
    double total = 0.0;
    for (var item in _expenses) {
      if (item.isIncome) {
        total += item.amount;
      } else {
        total -= item.amount;
      }
    }
    return total;
  }

  // 2. Logic for just Total Income (Optional but useful)
  double get totalIncome {
    return _expenses.where((e) => e.isIncome).fold(0, (sum, item) => sum + item.amount);
  }

  // 3. Logic for just Total Expenses (Optional but useful)
  double get totalExpenseOnly {
    return _expenses.where((e) => !e.isIncome).fold(0, (sum, item) => sum + item.amount);
  }

  void loadExpenses() {
    var box = Hive.box<Expense>('expenses');
    _expenses = box.values.toList();
    notifyListeners();
  }

  void addExpense(Expense newExpense) {
    var box = Hive.box<Expense>('expenses');
    box.add(newExpense);
    _expenses.add(newExpense);
    notifyListeners();
  }

  void deleteExpense(int index) {
    var box = Hive.box<Expense>('expenses');
    box.deleteAt(index);
    _expenses.removeAt(index);
    notifyListeners();
  }

  // Notes Logic
  List<Note> _notes = [];
  List<Note> get notes => _notes;

  void loadNotes() {
    var box = Hive.box<Note>('notes');
    _notes = box.values.toList();
    notifyListeners();
  }

  void addNote(String text) {
    var box = Hive.box<Note>('notes');
    final newNote = Note(content: text);
    box.add(newNote);
    _notes.add(newNote);
    notifyListeners();
  }

  void deleteNote(int index) {
    var box = Hive.box<Note>('notes');
    box.deleteAt(index);
    _notes.removeAt(index);
    notifyListeners();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  
  Hive.registerAdapter(ExpenseAdapter());
  Hive.registerAdapter(NoteAdapter()); 
  
  // Inside main()
  await Hive.openBox('userBox'); // Simple box for username/password
  await Hive.openBox<Expense>('expenses');
  await Hive.openBox<Note>('notes'); 

  runApp(
    ChangeNotifierProvider(
      create: (context) => ExpenseProvider()..loadExpenses()..loadNotes(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BudgetO',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.green.shade900,
      ),
      home: const SplashScreen(),
    );
  }
}