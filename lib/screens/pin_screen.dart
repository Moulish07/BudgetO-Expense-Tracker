import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Needed to check and save the PIN
import '../main.dart';
import 'dashboard_screen.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _isSetupMode = false;

  @override
  void initState() {
    super.initState();
    // Check if a PIN already exists in the local database
    final box = Hive.box('userBox');
    _isSetupMode = box.get('userPin') == null;
  }

  void _verifyPin() async {
    final box = Hive.box('userBox');
    final enteredPin = _pinController.text;

    if (_isSetupMode) {
      // --- SETUP MODE: Save the new PIN ---
      await box.put('userPin', enteredPin);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("PIN Set Successfully!", textAlign: TextAlign.center),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;
      Provider.of<ExpenseProvider>(context, listen: false).unlockApp();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } else {
      // --- VERIFY MODE: Check against the saved PIN ---
      final savedPin = box.get('userPin');

      if (enteredPin == savedPin) {
        await Future.delayed(const Duration(milliseconds: 200));

        if (!mounted) return;
        Provider.of<ExpenseProvider>(context, listen: false).unlockApp();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      } else {
        // Feedback for wrong PIN
        _pinController.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Incorrect PIN", textAlign: TextAlign.center),
              backgroundColor: Colors.redAccent,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B5E20), Colors.black],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Blur Layer
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withOpacity(0.1)),
          ),
          // Input Content
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isSetupMode
                        ? Icons.lock_open_rounded
                        : Icons.lock_outline_rounded,
                    size: 64,
                    color: Colors.white70,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _isSetupMode ? "Welcome to BudgetO" : "Security Check",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isSetupMode
                        ? "Create a 4-digit PIN"
                        : "Enter your 4-digit PIN",
                    style: const TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 220,
                    child: TextField(
                      controller: _pinController,
                      obscureText: true,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 4,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        letterSpacing: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        counterText: "",
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.white24,
                            width: 2,
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.greenAccent,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.length == 4) {
                          _verifyPin();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
