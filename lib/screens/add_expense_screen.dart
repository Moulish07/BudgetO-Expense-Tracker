import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';           
import '../models/expense.dart'; 

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _customCategoryController = TextEditingController();
  
  String _selectedCategory = 'Food';
  bool _isCustomCategory = false;
  
  // NEW: Variable to track if it's Income or Expense
  bool _isIncome = false; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isIncome ? "Add Income" : "Add Expense"),
        backgroundColor: _isIncome ? Colors.blue.shade900 : const Color(0xFF1B5E20),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. INCOME / EXPENSE TOGGLE
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Expense", style: TextStyle(fontWeight: FontWeight.bold)),
                    Switch(
                      value: _isIncome,
                      activeColor: Colors.blue,
                      inactiveThumbColor: Colors.red,
                      onChanged: (value) {
                        setState(() {
                          _isIncome = value;
                          // Set default categories based on type
                          if (_isIncome) _selectedCategory = 'Salary';
                          else _selectedCategory = 'Food';
                        });
                      },
                    ),
                    const Text("Income", style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Divider(),

              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: _isIncome ? "Source (e.g., Salary, Bonus)" : "Title (e.g., Pizza, Rent)",
                ),
              ),
              const SizedBox(height: 10),
              
              TextField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: "Amount", prefixText: "₹"),
                keyboardType: TextInputType.number, 
              ),
              const SizedBox(height: 20),

              const Text("Category:", style: TextStyle(fontSize: 16)),
              DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                items: (_isIncome ? ['Salary', 'Bonus', 'Gift', 'Other'] : ['Food', 'Travel', 'Bills', 'Other'])
                    .map((String val) => DropdownMenuItem<String>(value: val, child: Text(val)))
                    .toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCategory = newValue!;
                    _isCustomCategory = (_selectedCategory == 'Other');
                  });
                },
              ),
              
              if (_isCustomCategory) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _customCategoryController,
                  decoration: const InputDecoration(
                    labelText: "Enter Custom Category",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    // Color changes based on Income/Expense
                    backgroundColor: _isIncome ? Colors.blue.shade800 : const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onPressed: () {
                    final name = _titleController.text;
                    final money = double.tryParse(_amountController.text) ?? 0.0;
                    
                    final finalCategory = _isCustomCategory 
                        ? (_customCategoryController.text.isEmpty ? "Other" : _customCategoryController.text) 
                        : _selectedCategory;

                    if (name.isNotEmpty && money > 0) {
                      final newEntry = Expense(
                        title: name,
                        amount: money,
                        date: DateTime.now(),
                        category: finalCategory,
                        isIncome: _isIncome, // SAVE THE TYPE
                      );

                      Provider.of<ExpenseProvider>(context, listen: false).addExpense(newEntry);
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please enter a valid name and amount")),
                      );
                    }
                  },
                  child: const Text("Save Entry", style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}