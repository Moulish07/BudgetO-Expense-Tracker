import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Needed to read Theme and Currency
import '../models/expense.dart';
import '../main.dart'; // Needed for ExpenseProvider

class ExpenseChart extends StatefulWidget {
  final List<Expense> expenses;
  final bool showIncome;

  const ExpenseChart({
    super.key,
    required this.expenses,
    required this.showIncome,
  });

  @override
  State<ExpenseChart> createState() => _ExpenseChartState();
}

class _ExpenseChartState extends State<ExpenseChart> {
  int touchedIndex = -1; // Tracks which slice is tapped

  @override
  Widget build(BuildContext context) {
    // Read global state for theme and currency
    final provider = Provider.of<ExpenseProvider>(context);
    final isLight = provider.themeMode == 2;

    Map<String, double> data = {};
    double totalValue = 0;

    for (var item in widget.expenses) {
      if (item.isIncome == widget.showIncome && item.amount > 0) {
        data.update(
          item.category,
          (value) => value + item.amount,
          ifAbsent: () => item.amount,
        );
        totalValue += item.amount;
      }
    }

    if (data.isEmpty) {
      return Center(
        child: Text(
          widget.showIncome ? "No income recorded" : "No expenses recorded",
          style: TextStyle(
            color: isLight ? Colors.black45 : Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // Center Text
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.showIncome ? "TOTAL" : "SPENT",
              style: TextStyle(
                color: isLight ? Colors.black45 : Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              // FIX: Dynamic Currency Symbol
              "${provider.currencySymbol}${totalValue.toStringAsFixed(0)}",
              style: TextStyle(
                color: isLight ? Colors.black87 : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        // Donut Chart
        AspectRatio(
          aspectRatio: 1.3,
          child: PieChart(
            PieChartData(
              // Handle Taps
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      touchedIndex = -1;
                      return;
                    }
                    touchedIndex =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              sectionsSpace: 4,
              centerSpaceRadius: 45,
              startDegreeOffset: -90,
              sections: data.entries.toList().asMap().entries.map((entry) {
                final index = entry.key;
                final dataEntry = entry.value;
                final isTouched = index == touchedIndex;

                final percentage = (dataEntry.value / totalValue) * 100;

                // Animation values for the "Pop" effect
                final double radius = isTouched ? 65.0 : 55.0;
                final double fontSize = isTouched ? 14.0 : 10.0;
                final double widgetOpacity = isTouched ? 1.0 : 0.8;

                return PieChartSectionData(
                  color: _getCategoryColor(
                    dataEntry.key,
                    widget.showIncome,
                  ).withOpacity(widgetOpacity),
                  value: dataEntry.value,
                  title: percentage > 5
                      ? '${dataEntry.key}\n${percentage.toStringAsFixed(0)}%'
                      : '',
                  radius: radius,
                  titleStyle: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors
                        .white, // Keep this white so it pops on the colored slices
                    shadows: const [
                      Shadow(color: Colors.black45, blurRadius: 4),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(String category, bool isIncome) {
    String cat = category.toLowerCase();
    if (isIncome) {
      switch (cat) {
        case 'salary':
          return Colors.greenAccent.shade700;
        case 'bonus':
          return Colors.tealAccent.shade400;
        case 'gift':
          return Colors.lightBlueAccent;
        default:
          return Colors.blueGrey.shade300;
      }
    } else {
      switch (cat) {
        case 'food':
          return Colors.orangeAccent;
        case 'travel':
          return Colors.blueAccent;
        case 'bills':
          return Colors.purpleAccent;
        case 'movie':
          return Colors.pinkAccent;
        case 'shopping':
          return Colors.amberAccent;
        case 'health':
          return Colors.redAccent;
        default:
          return Colors.deepOrangeAccent;
      }
    }
  }
}
