import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'dashboard_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _passController = TextEditingController();
  final _nameController = TextEditingController();
  final _userBox = Hive.box('userBox');
  bool _isFirstTime = true;

  @override
  void initState() {
    super.initState();
    // Check if a username already exists in the box
    _isFirstTime = _userBox.get('username') == null;
  }

  void _handleAuth() {
    if (_isFirstTime) {
      // REGISTRATION LOGIC
      if (_nameController.text.isNotEmpty && _passController.text.length >= 4) {
        _userBox.put('username', _nameController.text);
        _userBox.put('password', _passController.text);
        _navigateToDashboard();
      } else {
        _showError("Please enter a name and a 4-digit PIN");
      }
    } else {
      // LOGIN LOGIC
      if (_passController.text == _userBox.get('password')) {
        _navigateToDashboard();
      } else {
        _showError("Incorrect PIN!");
        _passController.clear();
      }
    }
  }

  void _navigateToDashboard() {
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (context) => const DashboardScreen())
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            colors: [Color(0xFF1B5E20), Color(0xFF121212)]
          )
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_wallet, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            Text(
              _isFirstTime ? "Welcome to BudgetO" : "Welcome Back, ${_userBox.get('username')}",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              _isFirstTime ? "Setup your profile to start tracking" : "Enter your PIN to unlock",
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 40),
            if (_isFirstTime) ...[
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Your Name",
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white30), borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white), borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
            ],
            TextField(
              controller: _passController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 20),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: "4-Digit PIN",
                counterText: "",
                labelStyle: const TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 0),
                enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white30), borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white), borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _handleAuth,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1B5E20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(_isFirstTime ? "GET STARTED" : "UNLOCK", style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}