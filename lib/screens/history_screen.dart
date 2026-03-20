import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../models/expense.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Past Months"), backgroundColor: const Color(0xFF1B5E20)),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          // Grouping all data by "Month Year" (e.g., "March 2026")
          Map<String, List<Expense>> monthlyData = {};
          for (var e in provider.expenses) {
            String monthKey = "${_getMonthName(e.date.month)} ${e.date.year}";
            monthlyData.putIfAbsent(monthKey, () => []).add(e);
          }

          var keys = monthlyData.keys.toList().reversed.toList(); // Newest month first

          return ListView.builder(
            itemCount: keys.length,
            itemBuilder: (context, index) {
              String month = keys[index];
              List<Expense> items = monthlyData[month]!;
              double totalInc = items.where((e) => e.isIncome).fold(0, (sum, e) => sum + e.amount);
              double totalExp = items.where((e) => !e.isIncome).fold(0, (sum, e) => sum + e.amount);

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(month, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Text("Income: ₹${totalInc.toInt()} | Expense: ₹${totalExp.toInt()}"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // You could create a detail view for that month here!
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _getMonthName(int month) {
    List<String> months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return months[month - 1];
  }
}