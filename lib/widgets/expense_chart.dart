import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/expense.dart';

class ExpenseChart extends StatelessWidget {
  final List<Expense> expenses;
  final bool showIncome;

  const ExpenseChart({super.key, required this.expenses, required this.showIncome});

  @override
  Widget build(BuildContext context) {
    Map<String, double> data = {};
    for (var item in expenses) {
      if (item.isIncome == showIncome && item.amount > 0) {
        data.update(
          item.category,
          (value) => value + item.amount,
          ifAbsent: () => item.amount,
        );
      }
    }

    if (data.isEmpty) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Text(
            showIncome ? "No income recorded yet" : "No expenses recorded yet",
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sectionsSpace: 3,
          centerSpaceRadius: 40,
          sections: data.entries.map((entry) {
            return PieChartSectionData(
              color: _getCategoryColor(entry.key, showIncome),
              value: entry.value,
              title: '${entry.key}\n₹${entry.value.toStringAsFixed(0)}',
              radius: 50,
              titleStyle: const TextStyle(
                fontSize: 10, 
                fontWeight: FontWeight.bold, 
                color: Colors.white,
                shadows: [Shadow(color: Colors.black, blurRadius: 2)],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category, bool isIncome) {
    String cat = category.toLowerCase();
    
    if (isIncome) {
      // COOL SUCCESS PALETTE (Incomes)
      switch (cat) {
        case 'salary': return Colors.green.shade700;
        case 'bonus': return Colors.teal.shade400;
        case 'gift': return Colors.cyan.shade600;
        case 'interest': return Colors.blue.shade800;
        default: return Colors.blueGrey.shade400;
      }
    } else {
      // WARM ALERT PALETTE (Expenses)
      switch (cat) {
        case 'food': return Colors.orange.shade800;
        case 'travel': return Colors.blue.shade400;
        case 'bills': return Colors.purple.shade700;
        case 'movie': return Colors.red.shade700;
        case 'shopping': return Colors.pink.shade600;
        case 'health': return Colors.redAccent.shade400;
        default: return Colors.deepOrange.shade400;
      }
    }
  }
}