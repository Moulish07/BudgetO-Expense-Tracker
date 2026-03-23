import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../models/expense.dart';

class AddExpenseScreen extends StatefulWidget {
  final int themeMode;
  final File? bgImage;

  const AddExpenseScreen({super.key, required this.themeMode, this.bgImage});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _customCategoryController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'Food';
  bool _isCustomCategory = false;
  bool _isIncome = false;
  bool _isOnline = true;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _customCategoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    final darkGreen = const Color(0xFF1B5E20);
    bool isLight = widget.themeMode == 2;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          _isIncome ? "Add Income" : "Add Expense",
          style: TextStyle(
            color: isLight ? Colors.black87 : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isLight ? Colors.black87 : Colors.white,
        ),
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: _getBackgroundDecoration(darkGreen),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: _buildThemedForm(isLight, provider),
          ),
        ),
      ),
    );
  }

  BoxDecoration _getBackgroundDecoration(Color darkGreen) {
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
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _isIncome ? Colors.blue.shade900 : darkGreen,
                const Color(0xFF001A00),
                Colors.black,
              ],
            )
          : null,
    );
  }

  Widget _buildThemedForm(bool isLight, ExpenseProvider provider) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: widget.themeMode == 0 ? 15 : 0,
          sigmaY: widget.themeMode == 0 ? 15 : 0,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isLight
                ? Colors.white.withOpacity(0.6)
                : Colors.white.withOpacity(widget.themeMode == 1 ? 0.05 : 0.08),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isLight ? Colors.white : Colors.white.withOpacity(0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isLight
                        ? Colors.white.withOpacity(0.5)
                        : Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: isLight
                          ? Colors.white
                          : Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Expense",
                        style: TextStyle(
                          color: !_isIncome ? Colors.redAccent : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Switch(
                        value: _isIncome,
                        activeColor: Colors.blueAccent,
                        inactiveThumbColor: Colors.redAccent,
                        trackColor: WidgetStateProperty.resolveWith(
                          (states) => isLight ? Colors.white70 : Colors.black45,
                        ),
                        onChanged: (value) => setState(() {
                          _isIncome = value;
                          _selectedCategory = _isIncome ? 'Salary' : 'Food';
                        }),
                      ),
                      Text(
                        "Income",
                        style: TextStyle(
                          color: _isIncome ? Colors.blueAccent : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              _buildThemedTextField(
                controller: _titleController,
                label: _isIncome ? "Source" : "Title",
                icon: Icons.edit,
                isLight: isLight,
              ),
              const SizedBox(height: 20),
              _buildThemedTextField(
                controller: _amountController,
                label: "Amount",
                icon: provider.currencySymbol == "₹"
                    ? Icons.currency_rupee
                    : Icons.attach_money,
                isNumber: true,
                isLight: isLight,
              ),
              const SizedBox(height: 20),

              Text(
                "Payment Mode",
                style: TextStyle(
                  color: isLight ? Colors.black54 : Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text("Online")),
                      selected: _isOnline,
                      onSelected: (val) => setState(() => _isOnline = true),
                      selectedColor: Colors.blueAccent.withOpacity(0.3),
                      backgroundColor: isLight
                          ? Colors.white.withOpacity(0.5)
                          : Colors.black.withOpacity(0.2),
                      side: BorderSide(
                        color: isLight
                            ? Colors.white
                            : Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text("Cash")),
                      selected: !_isOnline,
                      onSelected: (val) => setState(() => _isOnline = false),
                      selectedColor: Colors.orangeAccent.withOpacity(0.3),
                      backgroundColor: isLight
                          ? Colors.white.withOpacity(0.5)
                          : Colors.black.withOpacity(0.2),
                      side: BorderSide(
                        color: isLight
                            ? Colors.white
                            : Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Text(
                "Category",
                style: TextStyle(
                  color: isLight ? Colors.black54 : Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildThemedDropdown(isLight),

              if (_isCustomCategory) ...[
                const SizedBox(height: 20),
                _buildThemedTextField(
                  controller: _customCategoryController,
                  label: "Enter Custom Category",
                  icon: Icons.category,
                  isLight: isLight,
                ),
              ],

              const SizedBox(height: 20),

              _buildThemedTextField(
                controller: _descriptionController,
                label: "Writer's Note (Optional)",
                icon: Icons.history_edu_rounded,
                isLight: isLight,
                maxLines: 3,
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isIncome
                        ? Colors.blueAccent
                        : Colors.green.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                    shadowColor:
                        (_isIncome ? Colors.blueAccent : Colors.green.shade700)
                            .withOpacity(0.5),
                  ),
                  onPressed: _saveEntry,
                  child: const Text(
                    "Save Entry",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UPGRADED: Glassmorphism TextField ---
  Widget _buildThemedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumber = false,
    required bool isLight,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isLight
            ? Colors.white.withOpacity(0.5)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isLight ? Colors.white : Colors.white.withOpacity(0.15),
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: TextStyle(color: isLight ? Colors.black87 : Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isLight ? Colors.black45 : Colors.white54,
          ),
          prefixIcon: Icon(
            icon,
            color: isLight ? Colors.black45 : Colors.white70,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 15,
          ),
        ),
      ),
    );
  }

  // --- UPGRADED: Glassmorphism Dropdown ---
  Widget _buildThemedDropdown(bool isLight) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: isLight
            ? Colors.white.withOpacity(0.5)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isLight ? Colors.white : Colors.white.withOpacity(0.15),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          dropdownColor: isLight ? Colors.white : const Color(0xFF1A1A1A),
          style: TextStyle(
            color: isLight ? Colors.black87 : Colors.white,
            fontSize: 16,
          ),
          icon: Icon(
            Icons.arrow_drop_down_rounded,
            color: isLight ? Colors.black54 : Colors.white70,
          ),
          items:
              (_isIncome
                      ? ['Salary', 'Bonus', 'Gift', 'Other']
                      : ['Food', 'Travel', 'Bills', 'Other'])
                  .map(
                    (String val) =>
                        DropdownMenuItem<String>(value: val, child: Text(val)),
                  )
                  .toList(),
          onChanged: (newValue) => setState(() {
            _selectedCategory = newValue!;
            _isCustomCategory = (_selectedCategory == 'Other');
          }),
        ),
      ),
    );
  }

  void _saveEntry() {
    final name = _titleController.text;
    final money = double.tryParse(_amountController.text) ?? 0.0;
    final note = _descriptionController.text.trim();

    final finalCategory = _isCustomCategory
        ? (_customCategoryController.text.isEmpty
              ? "Other"
              : _customCategoryController.text)
        : _selectedCategory;

    if (name.isNotEmpty && money > 0) {
      final newEntry = Expense(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: name,
        amount: money,
        date: DateTime.now(),
        category: finalCategory,
        isIncome: _isIncome,
        isOnline: _isOnline,
        description: note.isNotEmpty ? note : null,
      );

      Provider.of<ExpenseProvider>(context, listen: false).addExpense(newEntry);
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid name and amount")),
      );
    }
  }
}
