import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../models/expense.dart';
import '../models/note.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // 1. Function to Update the PIN
  void _showUpdatePinDialog(BuildContext context, Box userBox) {
    final pinController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update Login PIN"),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          decoration: const InputDecoration(labelText: "Enter New 4-Digit PIN"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (pinController.text.length == 4) {
                userBox.put('password', pinController.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("PIN updated successfully!")),
                );
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  // 2. Function to Wipe All Data
  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Wipe All Data?", style: TextStyle(color: Colors.red)),
        content: const Text("This will permanently delete all your expenses and notes. This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              // Clear the Hive boxes
              await Hive.box<Expense>('expenses').clear();
              await Hive.box<Note>('notes').clear();
              
              // Tell the app to refresh
              if (context.mounted) {
                Provider.of<ExpenseProvider>(context, listen: false).loadExpenses();
                Provider.of<ExpenseProvider>(context, listen: false).loadNotes();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("All data has been cleared.")),
                );
              }
            },
            child: const Text("Delete Everything", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userBox = Hive.box('userBox');
    final String name = userBox.get('username') ?? "User";
    final provider = Provider.of<ExpenseProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("My Profile"), backgroundColor: const Color(0xFF1B5E20)),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFF1B5E20),
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Divider(height: 40),
            
            // Stats Card
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem("Entries", "${provider.expenses.length}"),
                  _statItem("Balance", "₹${provider.totalBalance.toInt()}"),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text("Update PIN"),
              onTap: () => _showUpdatePinDialog(context, userBox),
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
              title: const Text("Wipe All Data", style: TextStyle(color: Colors.redAccent)),
              onTap: () => _showDeleteDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
      ],
    );
  }
}