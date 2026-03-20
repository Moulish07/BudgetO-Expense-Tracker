import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text("My Financial Notes")),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          return ListView.builder(
            itemCount: provider.notes.length,
            itemBuilder: (context, index) {
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(provider.notes[index].content),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => provider.deleteNote(index),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add_comment),
        onPressed: () {
          // Show a popup to type a note
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Add Note"),
              content: TextField(controller: controller, decoration: const InputDecoration(hintText: "Enter your note...")),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                TextButton(
                  onPressed: () {
                    if (controller.text.isNotEmpty) {
                      Provider.of<ExpenseProvider>(context, listen: false).addNote(controller.text);
                      controller.clear();
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Save"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}