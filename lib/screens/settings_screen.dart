import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../main.dart';
import '../models/expense.dart';
import '../services/firebase_service.dart';

class SettingsScreen extends StatefulWidget {
  final int themeMode;
  final File? bgImage;

  const SettingsScreen({super.key, required this.themeMode, this.bgImage});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDownloading = false;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    bool isLight = widget.themeMode == 2;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "Settings",
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
        width: double.infinity,
        height: double.infinity,
        decoration: _getBackgroundDecoration(),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildSectionTitle("Cloud Usage", isLight),
              _buildGlassTile(
                icon: Icons.cloud_done_outlined,
                title: "Firestore Storage",
                subtitle:
                    "${(provider.expenses.length * 0.5).toStringAsFixed(1)} KB of 1 GB used",
                trailing: const Text(
                  "FREE",
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
                isLight: isLight,
              ),
              const SizedBox(height: 20),

              _buildSectionTitle("Data Management", isLight),
              _buildGlassTile(
                icon: Icons.cloud_download_outlined,
                title: "Sync from Cloud",
                subtitle: _isDownloading
                    ? "Downloading..."
                    : "Restore data to this device",
                onTap: _isDownloading
                    ? null
                    : () => _handleCloudDownload(provider),
                isLight: isLight,
                trailing: _isDownloading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
              _buildGlassTile(
                icon: Icons.delete_sweep_outlined,
                title: "Clear Local Cache",
                subtitle: "Deletes local data only. Cloud is safe.",
                onTap: () => _confirmClearCache(
                  context,
                  isLight,
                  provider,
                ), // Passed provider here
                isLight: isLight,
                color: Colors.orangeAccent,
              ),
              const SizedBox(height: 20),

              _buildSectionTitle("Personalization", isLight),
              _buildGlassTile(
                icon: Icons.currency_exchange,
                title: "Currency Symbol",
                subtitle: "Currently set to ${provider.currencySymbol}",
                onTap: () => _showCurrencyPicker(context, provider, isLight),
                isLight: isLight,
              ),
              _buildGlassTile(
                icon: Icons.info_outline,
                title: "App Version",
                subtitle: "v2.2.0 (Stable)",
                isLight: isLight,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- CURRENCY PICKER LOGIC ---
  void _showCurrencyPicker(
    BuildContext context,
    ExpenseProvider provider,
    bool isLight,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isLight ? Colors.white : Colors.black.withOpacity(0.8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Select Currency",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isLight ? Colors.black : Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              _currencyOption(context, provider, "Rupee (₹)", "₹", isLight),
              _currencyOption(context, provider, "Dollar (\$)", "\$", isLight),
              _currencyOption(context, provider, "Euro (€)", "€", isLight),
              _currencyOption(context, provider, "Pound (£)", "£", isLight),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _currencyOption(
    BuildContext context,
    ExpenseProvider provider,
    String name,
    String symbol,
    bool isLight,
  ) {
    bool isSelected = provider.currencySymbol == symbol;
    return ListTile(
      title: Text(
        name,
        style: TextStyle(color: isLight ? Colors.black : Colors.white),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Colors.green)
          : null,
      onTap: () {
        provider.setCurrency(symbol);
        Navigator.pop(context);
      },
    );
  }

  // --- DATA MANAGEMENT LOGIC ---
  Future<void> _handleCloudDownload(ExpenseProvider provider) async {
    setState(() => _isDownloading = true);
    try {
      final cloudExpenses = await FirebaseService().streamExpenses().first;
      var box = Hive.box<Expense>('expenses');
      await box.clear();
      await box.addAll(cloudExpenses);

      if (!mounted) return; // UI Safety Check

      provider.loadExpenses();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Data restored from Cloud!")),
      );
    } catch (e) {
      debugPrint("Download error: $e");
    } finally {
      if (mounted) {
        // UI Safety Check
        setState(() => _isDownloading = false);
      }
    }
  }

  void _confirmClearCache(
    BuildContext context,
    bool isLight,
    ExpenseProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: isLight ? Colors.white : Colors.grey.shade900,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          title: Text(
            "Clear Cache?",
            style: TextStyle(color: isLight ? Colors.black : Colors.white),
          ),
          content: Text(
            "This will remove all expenses from this device. You can download them again from the cloud later.",
            style: TextStyle(color: isLight ? Colors.black54 : Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL"),
            ),
            TextButton(
              onPressed: () async {
                await Hive.box<Expense>('expenses').clear();

                if (!mounted) return; // UI Safety Check

                provider
                    .loadExpenses(); // Updates UI smoothly instead of closing app
                Navigator.pop(context);
              },
              child: const Text(
                "CLEAR",
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI HELPERS ---
  Widget _buildSectionTitle(String title, bool isLight) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: isLight ? Colors.black45 : Colors.white54,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildGlassTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    required bool isLight,
    Color? color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: widget.themeMode == 0 ? 15 : 0,
            sigmaY: widget.themeMode == 0 ? 15 : 0,
          ),
          child: ListTile(
            onTap: onTap,
            tileColor: isLight
                ? Colors.white
                : Colors.white.withOpacity(widget.themeMode == 1 ? 0.05 : 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isLight ? Colors.black12 : Colors.white.withOpacity(0.1),
              ),
            ),
            leading: Icon(
              icon,
              color: color ?? (isLight ? Colors.black87 : Colors.white70),
            ),
            title: Text(
              title,
              style: TextStyle(
                color: isLight ? Colors.black87 : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            trailing: trailing,
          ),
        ),
      ),
    );
  }

  BoxDecoration _getBackgroundDecoration() {
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
          ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1B5E20), Colors.black],
            )
          : null,
    );
  }
}
