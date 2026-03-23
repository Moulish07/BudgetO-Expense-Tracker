import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Needed for PIN reset
import '../main.dart';
import 'pin_screen.dart'; // Needed to route back to setup mode

class ProfileScreen extends StatelessWidget {
  final int themeMode;
  final File? bgImage;

  const ProfileScreen({super.key, required this.themeMode, this.bgImage});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    final user = provider.user;
    bool isLight = themeMode == 2;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "User Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isLight ? Colors.black87 : Colors.white,
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: _getBackgroundDecoration(),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),

                // GLASS PROFILE CARD
                _buildGlassProfileCard(user, isLight),

                const SizedBox(height: 40),

                // RESET PIN BUTTON
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent.withOpacity(0.8),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => _confirmResetPin(context, isLight),
                    icon: const Icon(Icons.pin_outlined),
                    label: const Text(
                      "Reset Security PIN",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // LOGOUT BUTTON
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withOpacity(0.8),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      provider.logout();
                      Navigator.pop(
                        context,
                      ); // Goes back to AuthScreen due to Provider listener
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text(
                      "Logout & Lock",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- NEW: PIN Reset Dialog Logic ---
  void _confirmResetPin(BuildContext context, bool isLight) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: isLight ? Colors.white : Colors.grey.shade900,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
            side: BorderSide(
              color: isLight ? Colors.black12 : Colors.white.withOpacity(0.1),
            ),
          ),
          title: Text(
            "Reset Security PIN?",
            style: TextStyle(
              color: isLight ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "This will remove your current PIN. You will be asked to create a new one immediately to keep your archive secure.",
            style: TextStyle(color: isLight ? Colors.black54 : Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                // 1. Delete the saved PIN from local storage
                await Hive.box('userBox').delete('userPin');

                if (!context.mounted) return;

                // 2. Close the dialog
                Navigator.pop(context);

                // 3. Navigate straight to PinScreen (it will open in Setup Mode)
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const PinScreen()),
                );
              },
              child: const Text(
                "RESET",
                style: TextStyle(
                  color: Colors.orangeAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassProfileCard(dynamic user, bool isLight) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: isLight
            ? Colors.white.withOpacity(0.8)
            : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // GOOGLE PROFILE PHOTO
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white24,
            backgroundImage: (user?.photoURL != null)
                ? NetworkImage(user!.photoURL!)
                : null,
            child: (user?.photoURL == null)
                ? Icon(
                    Icons.person,
                    size: 50,
                    color: isLight ? Colors.black45 : Colors.white70,
                  )
                : null,
          ),
          const SizedBox(height: 15),
          Text(
            user?.displayName ?? "Researcher",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isLight ? Colors.black87 : Colors.white,
            ),
          ),
          Text(
            user?.email ?? "Cloud Sync Active",
            style: TextStyle(
              fontSize: 14,
              color: isLight ? Colors.black54 : Colors.white54,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white10),
          _profileStatTile(
            "Status",
            "Authenticated",
            Icons.verified_user,
            Colors.blueAccent,
            isLight,
          ),
        ],
      ),
    );
  }

  Widget _profileStatTile(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isLight,
  ) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(
          color: isLight ? Colors.black45 : Colors.grey,
          fontSize: 12,
        ),
      ),
      trailing: Text(
        value,
        style: TextStyle(
          color: isLight ? Colors.black87 : Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  BoxDecoration _getBackgroundDecoration() {
    if (themeMode == 1) return const BoxDecoration(color: Color(0xFF0F0F0F));
    if (themeMode == 2) return const BoxDecoration(color: Color(0xFFF8F9FA));
    return BoxDecoration(
      image: bgImage != null
          ? DecorationImage(image: FileImage(bgImage!), fit: BoxFit.cover)
          : null,
      gradient: bgImage == null
          ? const LinearGradient(
              colors: [Color(0xFF1B5E20), Colors.black],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : null,
    );
  }
}
