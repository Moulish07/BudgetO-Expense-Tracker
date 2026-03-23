import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import 'auth_screen.dart';
import 'pin_screen.dart';
import 'dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // 3-second delay for that smooth visual entry
    await Future.delayed(const Duration(seconds: 3));

    // Safety check after the async gap
    if (!mounted) return;

    final provider = Provider.of<ExpenseProvider>(context, listen: false);

    Widget nextScreen;

    // LAYER 1: Cloud Authentication
    if (provider.user == null) {
      nextScreen = const AuthScreen();
    }
    // LAYER 2: Local PIN Security
    else if (!provider.isUnlocked) {
      nextScreen = const PinScreen();
    }
    // LAYER 3: Access Granted
    else {
      nextScreen = const DashboardScreen();
    }

    // Replace the splash screen so the user can't swipe back to it
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B5E20), // Signature Dark Green
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.account_balance_wallet,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            const Text(
              "BudgetO",
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(
              color: Colors.white70,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
