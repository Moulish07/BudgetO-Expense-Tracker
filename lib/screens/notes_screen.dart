import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../models/note.dart'; // Ensure this is imported

class NotesScreen extends StatefulWidget {
  final int themeMode;
  final File? bgImage;

  const NotesScreen({super.key, required this.themeMode, this.bgImage});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  // 1. Move the controller to the State level
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    // 2. Initialize it exactly once
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    // 3. Dispose of it when the screen is closed to prevent memory leaks
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final darkGreen = const Color(0xFF1B5E20);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "Financial Notes",
          style: TextStyle(
            color: widget.themeMode == 2 ? Colors.black87 : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: widget.themeMode == 2 ? Colors.black87 : Colors.white,
        ),
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: _getBackgroundDecoration(darkGreen),
        child: SafeArea(
          child: Consumer<ExpenseProvider>(
            builder: (context, provider, child) {
              return provider.notes.isEmpty
                  ? Center(
                      child: Text(
                        "No notes yet.",
                        style: TextStyle(
                          color: widget.themeMode == 2
                              ? Colors.black38
                              : Colors.white54,
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(15),
                      itemCount: provider.notes.length,
                      itemBuilder: (context, index) {
                        final noteItem = provider.notes[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildGlassNoteCard(
                            context,
                            noteItem.content,
                            () {
                              provider.deleteNote(index);
                            },
                          ),
                        );
                      },
                    );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: widget.themeMode == 2
            ? Colors.orangeAccent
            : Colors.greenAccent.shade700,
        child: const Icon(Icons.add_comment, color: Colors.white),
        onPressed: () => _showAddNoteDialog(context),
      ),
    );
  }

  // --- UI BUILDERS ---

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
              colors: [darkGreen, const Color(0xFF001A00), Colors.black],
            )
          : null,
    );
  }

  Widget _buildGlassNoteCard(
    BuildContext context,
    String content,
    VoidCallback onDelete,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: widget.themeMode == 0 ? 10 : 0,
          sigmaY: widget.themeMode == 0 ? 10 : 0,
        ),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: widget.themeMode == 2
                ? Colors.white
                : Colors.white.withOpacity(widget.themeMode == 1 ? 0.05 : 0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: widget.themeMode == 2
                  ? Colors.black12
                  : Colors.white.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  content,
                  style: TextStyle(
                    color: widget.themeMode == 2
                        ? Colors.black87
                        : Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                  size: 20,
                ),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: widget.themeMode == 2
              ? Colors.white
              : Colors.grey.shade900,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Add Note",
            style: TextStyle(
              color: widget.themeMode == 2 ? Colors.black : Colors.white,
            ),
          ),
          content: TextField(
            controller: _noteController,
            autofocus: true,
            style: TextStyle(
              color: widget.themeMode == 2 ? Colors.black : Colors.white,
            ),
            decoration: InputDecoration(
              hintText: "Enter your financial note...",
              hintStyle: TextStyle(
                color: widget.themeMode == 2 ? Colors.black38 : Colors.white38,
              ),
              border: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: widget.themeMode == 2
                      ? Colors.black26
                      : Colors.white24,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _noteController.clear();
                Navigator.pop(context);
              },
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                if (_noteController.text.trim().isNotEmpty) {
                  Provider.of<ExpenseProvider>(
                    context,
                    listen: false,
                  ).addNote(_noteController.text.trim());
                  _noteController.clear();
                  Navigator.pop(context);
                }
              },
              child: const Text("Save", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
