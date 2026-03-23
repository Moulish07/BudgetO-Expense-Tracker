import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expense.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. Safe getter for UID
  String? get uid => _auth.currentUser?.uid;

  // 2. ADD/UPDATE EXPENSE (Anti-Duplicate Logic)
  Future<void> saveExpenseToCloud(Expense expense) async {
    if (uid == null) return;

    // Use .doc(expense.id).set() to ensure we overwrite if the ID exists
    // instead of creating a duplicate document.
    await _db
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .doc(expense.id) // Using our unique Hive ID
        .set({
      'id': expense.id,
      'title': expense.title,
      'amount': expense.amount,
      'date': expense.date,
      'category': expense.category,
      'isIncome': expense.isIncome,
      'isOnline': expense.isOnline, // Added the new field
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)); // Merge prevents wiping other fields
  }

  // 3. DELETE FROM CLOUD
  Future<void> deleteExpenseFromCloud(String expenseId) async {
    if (uid == null) return;
    await _db
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .doc(expenseId)
        .delete();
  }

  // 4. STREAM EXPENSES (Now with ID and isOnline mapping)
  Stream<List<Expense>> streamExpenses() {
    if (uid == null) return Stream.value([]);

    return _db
      .collection('users')
      .doc(uid)
      .collection('expenses')
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return Expense(
              id: data['id'] ?? doc.id, // Fallback to doc ID if field missing
              title: data['title'],
              amount: (data['amount'] as num).toDouble(), // Safe casting
              date: (data['date'] as Timestamp).toDate(),
              category: data['category'],
              isIncome: data['isIncome'] ?? false,
              isOnline: data['isOnline'] ?? true, // Map the new field
            );
          }).toList());
  }
}