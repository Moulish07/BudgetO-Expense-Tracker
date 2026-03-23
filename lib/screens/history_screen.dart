import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../main.dart';

class HistoryScreen extends StatefulWidget {
  final int themeMode;
  final File? bgImage;
  final String currencySymbol;

  const HistoryScreen({
    super.key,
    required this.themeMode,
    this.bgImage,
    required this.currencySymbol,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedMonth = DateFormat('MMMM yyyy').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    final isLight = widget.themeMode == 2;

    // FIX: Grouping logic for the dropdown to prevent assertion crashes
    List<String> availableMonths = provider.expenses
        .map((e) => DateFormat('MMMM yyyy').format(e.date))
        .toSet()
        .toList();

    if (availableMonths.isEmpty) {
      availableMonths = [
        _selectedMonth,
      ]; // Fallback so Dropdown has at least one item
    } else if (!availableMonths.contains(_selectedMonth)) {
      _selectedMonth = availableMonths
          .first; // Auto-select first available if current is missing
    }

    final filteredExpenses = provider.expenses.where((e) {
      return DateFormat('MMMM yyyy').format(e.date) == _selectedMonth;
    }).toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Monthly Archive",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isLight ? Colors.black87 : Colors.white,
        ),
        titleTextStyle: TextStyle(
          color: isLight ? Colors.black87 : Colors.white,
          fontSize: 20,
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: _getBackgroundDecoration(),
        child: SafeArea(
          child: Column(
            children: [
              _buildMonthPicker(availableMonths, isLight),
              Expanded(
                child: provider.expenses.isEmpty
                    ? Center(
                        child: Text(
                          "No data for this month",
                          style: TextStyle(
                            color: isLight ? Colors.black45 : Colors.white54,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 10,
                        ),
                        itemCount: filteredExpenses.length,
                        itemBuilder: (context, index) {
                          final e = filteredExpenses[index];
                          return _buildHistoryTile(e, isLight);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthPicker(List<String> months, bool isLight) {
    return Container(
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isLight
            ? Colors.white.withOpacity(0.8)
            : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedMonth,
          dropdownColor: isLight ? Colors.white : Colors.grey[900],
          icon: Icon(
            Icons.calendar_month,
            color: isLight ? Colors.black54 : Colors.white70,
          ),
          items: months
              .map(
                (m) => DropdownMenuItem(
                  value: m,
                  child: Text(
                    m,
                    style: TextStyle(
                      color: isLight ? Colors.black87 : Colors.white,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _selectedMonth = v!),
        ),
      ),
    );
  }

  Widget _buildHistoryTile(Expense e, bool isLight) {
    return GestureDetector(
      onTap: () => _showDetailSheet(e, isLight),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isLight
              ? Colors.white.withOpacity(0.7)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: e.isIncome
                  ? Colors.blue.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
              child: Icon(
                e.isIncome ? Icons.add : Icons.remove,
                color: e.isIncome ? Colors.blue : Colors.redAccent,
                size: 18,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.title,
                    style: TextStyle(
                      color: isLight ? Colors.black87 : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat('dd MMM').format(e.date),
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${e.isIncome ? '+' : '-'}${widget.currencySymbol}${e.amount.toStringAsFixed(0)}",
                  style: TextStyle(
                    color: e.isIncome ? Colors.blueAccent : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (e.description != null && e.description!.isNotEmpty)
                  const Icon(
                    Icons.sticky_note_2_outlined,
                    size: 14,
                    color: Colors.amberAccent,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailSheet(Expense e, bool isLight) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        // FIX: Prevents the blur from bleeding outside the rounded top corners
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: isLight
                  ? Colors.white.withOpacity(0.9)
                  : Colors.black.withOpacity(0.8),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      e.category.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE, dd MMMM yyyy').format(e.date),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  e.title,
                  style: TextStyle(
                    color: isLight ? Colors.black : Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "${widget.currencySymbol}${e.amount.toStringAsFixed(2)}",
                  style: TextStyle(
                    color: e.isIncome ? Colors.blueAccent : Colors.redAccent,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Divider(height: 30, color: Colors.white10),

                // WRITER'S NOTE SECTION
                if (e.description != null && e.description!.isNotEmpty) ...[
                  Text(
                    "RESEARCH CONTEXT",
                    style: TextStyle(
                      color: isLight ? Colors.black45 : Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.amberAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.amberAccent.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      e.description!,
                      style: TextStyle(
                        color: isLight ? Colors.black87 : Colors.white,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                Row(
                  children: [
                    Icon(
                      e.isOnline ? Icons.wifi : Icons.store,
                      color: Colors.grey,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      e.isOnline ? "Digital Transaction" : "Physical Purchase",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _getBackgroundDecoration() {
    if (widget.themeMode == 1)
      return const BoxDecoration(color: Color(0xFF0F0F0F));
    if (widget.themeMode == 2)
      return const BoxDecoration(color: Color(0xFFF8F9FA));
    return BoxDecoration(
      image: widget.bgImage != null
          ? DecorationImage(
              image: FileImage(widget.bgImage!),
              fit: BoxFit.cover,
            )
          : null,
      gradient: widget.bgImage == null
          ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1B5E20), Color(0xFF001A00), Colors.black],
            )
          : null,
    );
  }
}
