import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'models/expense.dart';
import 'models/note.dart';
import 'screens/splash_screen.dart';
import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/pin_screen.dart';
import 'screens/dashboard_screen.dart';

class ExpenseProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Expense> _expenses = [];
  List<Expense> get expenses => _expenses;

  List<Note> _notes = [];
  List<Note> get notes => _notes;

  User? _user;
  User? get user => _user;

  bool _isUnlocked = false;
  bool get isUnlocked => _isUnlocked;

  int _themeMode = 0;
  int get themeMode => _themeMode;

  String _currencySymbol = "₹";
  String get currencySymbol => _currencySymbol;

  // Novel Integration: 2005 Bengal Economic Adjustments
  double inflationMultiplier = 0.45;
  bool _isHistoricalMode = false;
  bool get isHistoricalMode => _isHistoricalMode;

  ExpenseProvider() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      if (user != null) {
        loadExpenses();
        loadNotes();
      } else {
        _expenses = [];
        _notes = [];
        _isUnlocked = false;
      }
      notifyListeners();
    });
  }

  // --- AGGREGATE DASHBOARD GETTERS ---

  double get totalIncome {
    double income = _expenses
        .where((e) => e.isIncome)
        .fold(0.0, (sum, e) => sum + e.amount);
    return _isHistoricalMode ? income * inflationMultiplier : income;
  }

  double get totalExpenseOnly {
    double exp = _expenses
        .where((e) => !e.isIncome)
        .fold(0.0, (sum, e) => sum + e.amount);
    return _isHistoricalMode ? exp * inflationMultiplier : exp;
  }

  double get totalBalance => totalIncome - totalExpenseOnly;

  // --- AUTHENTICATION LOGIC ---

  Future<void> signInWithGoogle() async {
    try {
      await GoogleSignIn().signOut();
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint("🚨 LOGIN ERROR: $e");
    }
  }

  void logout() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
    _isUnlocked = false;
    notifyListeners();
  }

  void unlockApp() {
    _isUnlocked = true;
    notifyListeners();
  }

  // --- LOCAL STORAGE (HIVE) LOGIC ---

  void loadExpenses() {
    var box = Hive.box<Expense>('expenses');
    var userBox = Hive.box('userBox');
    _expenses = box.values.toList();
    _themeMode = userBox.get('themeMode', defaultValue: 0);
    _currencySymbol = userBox.get('currencySymbol', defaultValue: "₹");
    notifyListeners();
  }

  void loadNotes() {
    var box = Hive.box<Note>('notes');
    _notes = box.values.toList();
    notifyListeners();
  }

  // --- UI ACTION METHODS ---

  void addExpense(Expense expense) {
    var box = Hive.box<Expense>('expenses');
    box.add(expense);
    _expenses = box.values.toList();
    notifyListeners();
  }

  void deleteExpense(int index) {
    var box = Hive.box<Expense>('expenses');
    box.deleteAt(index);
    _expenses = box.values.toList();
    notifyListeners();
  }

  void addNote(String content) {
    var box = Hive.box<Note>('notes');
    // Assuming your Note model takes a content string and a DateTime
    final newNote = Note(content: content, date: DateTime.now());
    box.add(newNote);
    _notes = box.values.toList();
    notifyListeners();
  }

  void deleteNote(int index) {
    var box = Hive.box<Note>('notes');
    box.deleteAt(index);
    _notes = box.values.toList();
    notifyListeners();
  }

  void setTheme(int mode) {
    _themeMode = mode;
    Hive.box('userBox').put('themeMode', mode);
    notifyListeners();
  }

  void setCurrency(String symbol) {
    _currencySymbol = symbol;
    Hive.box('userBox').put('currencySymbol', symbol);
    notifyListeners();
  }

  void toggleHistoricalMode() {
    _isHistoricalMode = !_isHistoricalMode;
    notifyListeners();
  }

  // --- CLOUD SYNC LOGIC ---

  Future<void> syncAllToCloud() async {
    if (_user == null) return;
    try {
      final batch = _firestore.batch();
      final collection = _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('expenses');

      // Clear existing cloud data to prevent duplicates (basic sync strategy)
      final existingDocs = await collection.get();
      for (var doc in existingDocs.docs) {
        batch.delete(doc.reference);
      }

      // Upload local Hive data
      for (var expense in _expenses) {
        final docRef = collection.doc();
        batch.set(
          docRef,
          expense.toMap(),
        ); // Assuming Expense has a toMap() method
      }

      await batch.commit();
      debugPrint("✅ Sync complete!");
    } catch (e) {
      debugPrint("🚨 Cloud Sync Error: $e");
    }
  }
}

// --- APP INITIALIZATION ---

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Hive.initFlutter();

  // Registering Adapters for custom objects
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ExpenseAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(NoteAdapter());

  // Opening Local Databases
  await Hive.openBox('userBox');
  await Hive.openBox<Expense>('expenses');
  await Hive.openBox<Note>('notes');

  runApp(
    ChangeNotifierProvider(
      create: (context) => ExpenseProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BudgetO',
      theme: ThemeData(
        useMaterial3: true,
        brightness: provider.themeMode == 2
            ? Brightness.light
            : Brightness.dark,
        colorSchemeSeed: Colors.green.shade900,
      ),
      home: const SplashScreen(),
    );
  }
}
