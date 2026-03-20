import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart'; 
import 'add_expense_screen.dart'; 
import '../widgets/expense_chart.dart';
import 'notes_screen.dart';
import '../models/expense.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _showIncomeChart = false;
  String searchQuery = "";
  DateTime? selectedDate;
  String sortBy = "A-Z"; 
  final darkGreen = const Color(0xFF1B5E20);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.history, color: Colors.white),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen())),
        ),
        title: const Text("BudgetO", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: darkGreen,
        centerTitle: true,
        actions: [
          if (searchQuery.isNotEmpty || selectedDate != null)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () => setState(() {
                searchQuery = "";
                selectedDate = null;
              }),
            ),
        ],
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          final now = DateTime.now();
          final filteredExpenses = provider.expenses.where((expense) {
            final matchesSearch = expense.title.toLowerCase().contains(searchQuery.toLowerCase()) || 
                                 expense.category.toLowerCase().contains(searchQuery.toLowerCase());
            final isCurrentMonth = expense.date.month == now.month && expense.date.year == now.year;
            final matchesDate = selectedDate == null 
                ? isCurrentMonth 
                : (expense.date.day == selectedDate!.day && 
                   expense.date.month == selectedDate!.month && 
                   expense.date.year == selectedDate!.year);
            return matchesSearch && matchesDate;
          }).toList();

          Map<String, List<Expense>> groupedExpenses = {};
          for (var e in filteredExpenses) {
            groupedExpenses.putIfAbsent(e.category, () => []).add(e);
          }

          var sortedKeys = groupedExpenses.keys.toList();
          if (sortBy == "A-Z") {
            sortedKeys.sort((a, b) => a.compareTo(b));
          } else if (sortBy == "High-Low") {
            sortedKeys.sort((a, b) {
              double totalA = groupedExpenses[a]!.fold(0, (sum, e) => e.isIncome ? sum + e.amount : sum - e.amount);
              double totalB = groupedExpenses[b]!.fold(0, (sum, e) => e.isIncome ? sum + e.amount : sum - e.amount);
              return totalB.abs().compareTo(totalA.abs());
            });
          }

          return Column(
            children: [
              // --- SEARCH & FILTER ROW ---
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (value) => setState(() => searchQuery = value),
                        decoration: InputDecoration(
                          hintText: "Search...",
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.calendar_month, color: selectedDate == null ? Colors.grey : darkGreen),
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => selectedDate = picked);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.sort),
                      color: darkGreen,
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.sort_by_alpha),
                                title: const Text("Alphabetical (A-Z)"),
                                onTap: () {
                                  setState(() => sortBy = "A-Z");
                                  Navigator.pop(context);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.trending_down),
                                title: const Text("Highest Spending First"),
                                onTap: () {
                                  setState(() => sortBy = "High-Low");
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              // --- BALANCE CARD ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [darkGreen, const Color(0xFF388E3C)]),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    const Text("Current Balance", style: TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(
                      "₹${filteredExpenses.fold(0.0, (sum, item) => item.isIncome ? sum + item.amount : sum - item.amount).toStringAsFixed(2)}", 
                      style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              // --- CHART SECTION ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_showIncomeChart ? "Income Breakdown" : "Expense Breakdown", 
                         style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () => setState(() => _showIncomeChart = !_showIncomeChart),
                      child: Text(_showIncomeChart ? "Show Expenses" : "Show Income"),
                    ),
                  ],
                ),
              ),
              if (filteredExpenses.isNotEmpty)
                ExpenseChart(
                  expenses: filteredExpenses, 
                  showIncome: _showIncomeChart,
                ),

              // --- TRANSACTION LIST ---
              Expanded(
                child: sortedKeys.isEmpty 
                  ? const Center(child: Text("No transactions found."))
                  : ListView.builder(
                      itemCount: sortedKeys.length,
                      itemBuilder: (context, index) {
                        String category = sortedKeys[index];
                        List<Expense> items = groupedExpenses[category]!;
                        double groupTotal = items.fold(0, (sum, item) => item.isIncome ? sum + item.amount : sum - item.amount);
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor: groupTotal >= 0 ? Colors.blue : darkGreen,
                              child: Icon(_getCategoryIcon(category), color: Colors.white, size: 20),
                            ),
                            title: Text(category, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("${items.length} transactions"),
                            trailing: Text(
                              "₹${groupTotal.abs().toStringAsFixed(0)}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                color: groupTotal >= 0 ? Colors.blue : Colors.redAccent,
                              ),
                            ),
                            children: items.map((item) => ListTile(
                              dense: true,
                              title: Text(item.title),
                              subtitle: Text("${item.date.day}/${item.date.month}"),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "${item.isIncome ? '+' : '-'}₹${item.amount.toInt()}",
                                    style: TextStyle(color: item.isIncome ? Colors.blue : Colors.redAccent),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18),
                                    onPressed: () => provider.deleteExpense(provider.expenses.indexOf(item)),
                                  ),
                                ],
                              ),
                            )).toList(),
                          ),
                        );
                      },
                    ),
              ),

              // --- SUMMARY BAR ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: const BoxDecoration(
                  color: Color(0xFF212121),
                  border: Border(top: BorderSide(color: Colors.white10)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("TOTAL INCOME", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(
                          "₹${filteredExpenses.where((e) => e.isIncome).fold(0.0, (sum, item) => sum + item.amount).toStringAsFixed(0)}",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ],
                    ),
                    Container(height: 30, width: 1, color: Colors.white24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text("TOTAL EXPENSE", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(
                          "₹${filteredExpenses.where((e) => !e.isIncome).fold(0.0, (sum, item) => sum + item.amount).toStringAsFixed(0)}",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      
      // --- FINAL POLISHED BOTTOM BAR ---
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF121212),
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 1. NOTES BUTTON
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotesScreen())),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.note_alt_outlined, color: Colors.white, size: 26),
                    const Text("Notes", style: TextStyle(color: Colors.white, fontSize: 10)),
                  ],
                ),
              ),
              
              // 2. CENTER PROFILE AVATAR (Slightly smaller for better text fit)
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
                child: CircleAvatar(
                  radius: 22, // Reduced from 25
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: darkGreen,
                    child: const Icon(Icons.person, color: Colors.white, size: 24),
                  ),
                ),
              ),
              
              // 3. ADD EXPENSE BUTTON
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddExpenseScreen())),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_circle_outline, color: Colors.white, size: 26),
                    const Text("Add New", style: TextStyle(color: Colors.white, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _getCategoryIcon(String category) {
  switch (category.toLowerCase()) {
    case 'food': return Icons.restaurant;
    case 'travel': return Icons.directions_car;
    case 'bills': return Icons.electric_bolt;
    case 'salary': return Icons.payments;
    case 'bonus': return Icons.card_giftcard;
    case 'movie': return Icons.movie;
    default: return Icons.shopping_bag;
  }
}