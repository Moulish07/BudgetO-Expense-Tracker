import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import 'add_expense_screen.dart';
import '../widgets/expense_chart.dart';
import 'notes_screen.dart';
import '../models/expense.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  bool _showIncomeChart = false;
  bool _chartCollapsed = false;
  bool _isSyncing = false;
  String searchQuery = "";
  final darkGreen = const Color(0xFF1B5E20);
  File? _bgImage;
  DateTime _lastSyncTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastSyncTime = DateTime.now();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      Provider.of<ExpenseProvider>(context, listen: false).syncAllToCloud();
      setState(() => _lastSyncTime = DateTime.now());
    }
  }

  Future<void> _handleManualSync(ExpenseProvider provider) async {
    setState(() => _isSyncing = true);
    await provider.syncAllToCloud();
    setState(() {
      _isSyncing = false;
      _lastSyncTime = DateTime.now();
    });
    _showGlassSnack(
      message: "Cloud Backup Successful!",
      icon: Icons.cloud_done_rounded,
      color: Colors.blueAccent,
    );
  }

  Future<void> _pickBackground() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _bgImage = File(image.path);
          Provider.of<ExpenseProvider>(context, listen: false).setTheme(0);
        });
      }
    } catch (e) {
      debugPrint("Wallpaper Error: $e");
    }
  }

  void _showGlassSnack({
    required String message,
    required IconData icon,
    required Color color,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        content: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.4),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(ExpenseProvider provider, Expense item) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AlertDialog(
          backgroundColor: provider.themeMode == 2
              ? Colors.white
              : Colors.white.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
            side: BorderSide(color: Colors.white.withOpacity(0.15)),
          ),
          title: Text(
            "Delete Entry?",
            style: TextStyle(
              color: provider.themeMode == 2 ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "Are you sure you want to remove '${item.title}'?",
            style: TextStyle(
              color: provider.themeMode == 2 ? Colors.black54 : Colors.white70,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withOpacity(0.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(context);
                int targetIndex = provider.expenses.indexOf(item);
                if (targetIndex != -1) {
                  provider.deleteExpense(targetIndex);
                  _showGlassSnack(
                    message: "${item.title} removed.",
                    icon: Icons.delete_sweep,
                    color: Colors.red,
                  );
                }
              },
              child: const Text(
                "DELETE",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToAddExpense(int themeMode) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddExpenseScreen(themeMode: themeMode, bgImage: _bgImage),
      ),
    );
    if (result == true) {
      _showGlassSnack(
        message: "Transaction Saved!",
        icon: Icons.check_circle,
        color: Colors.green,
      );
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.fastfood_outlined;
      case 'transport':
        return Icons.directions_car_outlined;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'entertainment':
        return Icons.movie_outlined;
      case 'bills':
        return Icons.receipt_long_outlined;
      case 'health':
        return Icons.medical_services_outlined;
      case 'education':
        return Icons.school_outlined;
      case 'income':
        return Icons.account_balance_wallet_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    final themeMode = provider.themeMode;
    final currency = provider.currencySymbol;

    return Scaffold(
      extendBody: true,
      drawer: _buildSidebar(provider),
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: themeMode == 2 ? Colors.black87 : Colors.white,
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_open_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          "BudgetO",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: themeMode == 2 ? Colors.black87 : Colors.white,
          ),
        ),
        backgroundColor: themeMode == 2
            ? Colors.white.withOpacity(0.9)
            : _getThemeColor(themeMode).withOpacity(0.5),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HistoryScreen(
                  themeMode: themeMode,
                  bgImage: _bgImage,
                  currencySymbol: currency,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: _getBackgroundDecoration(themeMode),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildSearchFilterBar(themeMode),
              _buildBalanceCard(provider),
              _buildAnimatedChart(provider, themeMode),
              Expanded(
                child: Consumer<ExpenseProvider>(
                  builder: (context, p, child) {
                    final filtered = _getFilteredExpenses(p);
                    final grouped = _getGroupedExpenses(filtered);
                    final sortedKeys = _getSortedKeys(grouped);

                    return sortedKeys.isEmpty
                        ? Center(
                            child: Text(
                              "No items found.",
                              style: TextStyle(
                                color: themeMode == 2
                                    ? Colors.black38
                                    : Colors.white54,
                              ),
                            ),
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(0, 10, 0, 180),
                            itemCount: sortedKeys.length,
                            itemBuilder: (context, index) {
                              final category = sortedKeys[index];
                              final items = grouped[category]!;
                              final total = items.fold(
                                0.0,
                                (sum, e) => e.isIncome
                                    ? sum + e.amount
                                    : sum - e.amount,
                              );
                              return _buildGlassTransactionCard(
                                category,
                                items,
                                total,
                                p,
                                themeMode,
                                currency,
                              );
                            },
                          );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 110),
                child: _buildSummaryBar(provider, themeMode, currency),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildGlassBottomNav(themeMode),
    );
  }

  Widget _buildGlassTransactionCard(
    String cat,
    List<Expense> items,
    double total,
    ExpenseProvider p,
    int mode,
    String currency,
  ) {
    bool isLight = mode == 2;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
      child: _buildGlassBox(
        mode: mode,
        child: ExpansionTile(
          iconColor: isLight ? Colors.black87 : Colors.white,
          collapsedIconColor: isLight ? Colors.black38 : Colors.white70,
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: total >= 0
                ? Colors.blue.withOpacity(0.2)
                : Colors.red.withOpacity(0.2),
            child: Icon(
              _getCategoryIcon(cat),
              color: total >= 0 ? Colors.blue : Colors.redAccent,
              size: 14,
            ),
          ),
          title: Text(
            cat,
            style: TextStyle(
              color: isLight ? Colors.black87 : Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          trailing: Text(
            "$currency${total.abs().toStringAsFixed(0)}",
            style: TextStyle(
              color: total >= 0 ? Colors.blueAccent : Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          children: items
              .map(
                (e) => ListTile(
                  dense: true,
                  title: Text(
                    e.title,
                    style: TextStyle(
                      color: isLight ? Colors.black87 : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${e.date.day}/${e.date.month}",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                      ),
                      if (e.description != null && e.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            e.description!,
                            style: TextStyle(
                              color: isLight ? Colors.black45 : Colors.white38,
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        e.isOnline
                            ? Icons.phonelink_ring_rounded
                            : Icons.payments_outlined,
                        size: 12,
                        color: isLight ? Colors.black38 : Colors.white38,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${e.isIncome ? '+' : '-'}$currency${e.amount.toInt()}",
                        style: TextStyle(
                          color: e.isIncome
                              ? Colors.blueAccent
                              : Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Colors.redAccent,
                        ),
                        onPressed: () => _confirmDelete(p, e),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildSidebar(ExpenseProvider provider) {
    final mode = provider.themeMode;
    return Drawer(
      backgroundColor: Colors.transparent,
      child: _buildGlassBox(
        mode: mode,
        sigma: 25,
        opacity: mode == 2 ? 0.95 : 0.2,
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: darkGreen.withOpacity(0.4)),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white24,
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "BudgetO Archive",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: _buildMonthlyComparison(provider, mode),
                  ),
                  const Divider(color: Colors.white10),
                  _sidebarStatusTile(provider),
                  ListTile(
                    leading: Icon(
                      Icons.auto_awesome,
                      color: provider.isHistoricalMode
                          ? Colors.amberAccent
                          : Colors.white70,
                    ),
                    title: const Text(
                      "2005 Bengal Mode",
                      style: TextStyle(color: Colors.white),
                    ),
                    trailing: Switch(
                      value: provider.isHistoricalMode,
                      activeColor: Colors.amberAccent,
                      onChanged: (v) => provider.toggleHistoricalMode(),
                    ),
                  ),
                  _sidebarTile(
                    Icons.archive_outlined,
                    "Monthly Archive",
                    mode,
                    () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HistoryScreen(
                            themeMode: mode,
                            bgImage: _bgImage,
                            currencySymbol: provider.currencySymbol,
                          ),
                        ),
                      );
                    },
                  ),
                  _sidebarTile(
                    Icons.palette_outlined,
                    "Visual Theme",
                    mode,
                    _showThemePicker,
                  ),
                  _sidebarTile(
                    Icons.image_outlined,
                    "Custom Wallpaper",
                    mode,
                    () {
                      Navigator.pop(context);
                      _pickBackground();
                    },
                  ),
                  _sidebarTile(
                    Icons.settings_suggest_outlined,
                    "App Settings",
                    mode,
                    () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SettingsScreen(
                            themeMode: mode,
                            bgImage: _bgImage,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  // --- NEW ABOUT ME SECTION ---
                  _buildAboutMeSection(mode),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- NEW: Glassmorphism About Me Widget ---
  Widget _buildAboutMeSection(int mode) {
    bool isLight = mode == 2;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isLight
            ? Colors.white.withOpacity(0.5)
            : Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isLight ? Colors.white : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: isLight ? Colors.black54 : Colors.white70,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                "ABOUT ME",
                style: TextStyle(
                  color: isLight ? Colors.black45 : Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Hii, I am Moulish, the Creator of BudgetO. I am anECE student and aspiring app developer. This app is made inspiring from my one teacher, it is a labor of love, built to help you take control of your finances with ease and style. I hope BudgetO brings you clarity and confidence in managing your money. Feel free to reach out with feedback or just to say hi! ",
            style: TextStyle(
              color: isLight ? Colors.black87 : Colors.white70,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarStatusTile(ExpenseProvider provider) {
    return InkWell(
      onTap: _isSyncing ? null : () => _handleManualSync(provider),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            _isSyncing
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.lightBlueAccent,
                    ),
                  )
                : const Icon(
                    Icons.cloud_sync_rounded,
                    color: Colors.lightBlueAccent,
                    size: 22,
                  ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Cloud Sync",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _isSyncing
                      ? "Syncing..."
                      : "Last: ${DateFormat('hh:mm a').format(_lastSyncTime)}",
                  style: const TextStyle(color: Colors.white38, fontSize: 9),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(ExpenseProvider provider) {
    final mode = provider.themeMode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: _buildGlassBox(
        mode: mode,
        color: provider.isHistoricalMode
            ? Colors.amberAccent
            : Colors.greenAccent,
        opacity: mode == 2 ? 1.0 : 0.22,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Text(
                provider.isHistoricalMode ? "VALUE IN 2005" : "CURRENT BALANCE",
                style: TextStyle(
                  color: mode == 2 ? Colors.black45 : Colors.white70,
                  fontSize: 10,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "${provider.currencySymbol}${provider.totalBalance.toStringAsFixed(2)}",
                style: TextStyle(
                  color: mode == 2 ? Colors.black : Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _getBackgroundDecoration(int mode) {
    if (mode == 1) return const BoxDecoration(color: Color(0xFF0F0F0F));
    if (mode == 2) return const BoxDecoration(color: Color(0xFFF8F9FA));
    return BoxDecoration(
      image: _bgImage != null
          ? DecorationImage(image: FileImage(_bgImage!), fit: BoxFit.cover)
          : null,
      gradient: _bgImage == null
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [darkGreen, const Color(0xFF001A00), Colors.black],
            )
          : null,
    );
  }

  Color _getThemeColor(int mode) => mode == 2 ? Colors.white : darkGreen;

  Widget _buildGlassBox({
    required Widget child,
    required int mode,
    Color? color,
    double sigma = 10.0,
    double opacity = 0.08,
  }) {
    double effectiveSigma = (mode == 0) ? sigma : 0.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: effectiveSigma,
          sigmaY: effectiveSigma,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: mode == 2
                ? Colors.white
                : (color ?? Colors.white).withOpacity(
                    mode == 1 ? 0.05 : opacity,
                  ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: mode == 2
                  ? Colors.black12
                  : Colors.white.withOpacity(0.12),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildAnimatedChart(ExpenseProvider provider, int mode) {
    if (provider.expenses.isEmpty) return const SizedBox.shrink();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _chartCollapsed ? 45 : 380,
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: _buildGlassBox(
        mode: mode,
        child: Column(
          children: [
            GestureDetector(
              onTap: () => setState(() => _chartCollapsed = !_chartCollapsed),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 12,
                ),
                color: Colors.transparent,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _showIncomeChart ? "Income Analysis" : "Expense Analysis",
                      style: TextStyle(
                        color: mode == 2 ? Colors.black87 : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      _chartCollapsed
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_up,
                      color: mode == 2 ? Colors.black54 : Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            if (!_chartCollapsed) ...[
              const Divider(color: Colors.white10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _chartTabButton("Expenses", !_showIncomeChart),
                  _chartTabButton("Income", _showIncomeChart),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: ExpenseChart(
                    expenses: provider.expenses,
                    showIncome: _showIncomeChart,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chartTabButton(String label, bool isActive) {
    return GestureDetector(
      onTap: () => setState(() => _showIncomeChart = label == "Income"),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.greenAccent.withOpacity(0.2)
              : Colors.black12,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.greenAccent : Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryBar(ExpenseProvider provider, int mode, String currency) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: _buildGlassBox(
        mode: mode,
        sigma: 15,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _sumCol(
                "INCOME",
                provider.totalIncome,
                Colors.blueAccent,
                mode,
                currency,
              ),
              const SizedBox(
                height: 25,
                child: VerticalDivider(color: Colors.white24),
              ),
              _sumCol(
                "EXPENSE",
                provider.totalExpenseOnly,
                Colors.redAccent,
                mode,
                currency,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sumCol(String l, double a, Color c, int mode, String currency) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l,
          style: TextStyle(
            color: mode == 2 ? Colors.black45 : Colors.white54,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          "$currency${a.toStringAsFixed(0)}",
          style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildGlassBottomNav(int mode) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 0, 25, 30),
      child: _buildGlassBox(
        mode: mode,
        sigma: 20,
        opacity: mode == 2 ? 1.0 : 0.1,
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _AnimatedNavButton(
                icon: Icons.note_alt_outlined,
                label: "Notes",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        NotesScreen(themeMode: mode, bgImage: _bgImage),
                  ),
                ),
                themeMode: mode,
              ),
              _AnimatedNavButton(
                isAvatar: true,
                icon: Icons.person_outline,
                label: "Profile",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProfileScreen(themeMode: mode, bgImage: _bgImage),
                  ),
                ),
                themeMode: mode,
              ),
              _AnimatedNavButton(
                icon: Icons.add_circle_outline,
                label: "Add",
                onTap: () => _navigateToAddExpense(mode),
                themeMode: mode,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _AnimatedNavButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required int themeMode,
    bool isAvatar = false,
  }) {
    bool isLight = themeMode == 2;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isLight ? Colors.black87 : Colors.white,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isLight ? Colors.black54 : Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemePicker() {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildGlassBox(
        mode: Provider.of<ExpenseProvider>(context, listen: false).themeMode,
        sigma: 20,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(15),
              child: Text(
                "Visual Theme",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _themeOption(0, "Glass Blue", Colors.lightBlueAccent),
            _themeOption(1, "Dark Purple", Colors.deepPurpleAccent),
            _themeOption(2, "Ivory Light", Colors.orangeAccent),
          ],
        ),
      ),
    );
  }

  Widget _themeOption(int mode, String label, Color color) {
    return ListTile(
      leading: Icon(Icons.palette, color: color),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: () {
        Provider.of<ExpenseProvider>(context, listen: false).setTheme(mode);
        Navigator.pop(context);
      },
    );
  }

  List<Expense> _getFilteredExpenses(ExpenseProvider provider) {
    return provider.expenses.where((e) {
      return e.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          e.category.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }

  Map<String, List<Expense>> _getGroupedExpenses(List<Expense> list) {
    Map<String, List<Expense>> map = {};
    for (var e in list) {
      map.putIfAbsent(e.category, () => []).add(e);
    }
    return map;
  }

  List<String> _getSortedKeys(Map<String, List<Expense>> map) {
    var keys = map.keys.toList();
    keys.sort((a, b) => a.compareTo(b));
    return keys;
  }

  Widget _buildSearchFilterBar(int mode) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: _buildGlassBox(
        mode: mode,
        sigma: 5,
        child: TextField(
          onChanged: (v) => setState(() => searchQuery = v),
          style: TextStyle(color: mode == 2 ? Colors.black87 : Colors.white),
          decoration: InputDecoration(
            hintText: "Quick Search...",
            prefixIcon: Icon(
              Icons.search,
              color: mode == 2 ? Colors.black45 : Colors.white70,
            ),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _sidebarTile(IconData i, String t, int mode, VoidCallback o) =>
      ListTile(
        leading: Icon(
          i,
          color: mode == 2 ? Colors.black54 : Colors.white70,
          size: 22,
        ),
        title: Text(
          t,
          style: TextStyle(
            color: mode == 2 ? Colors.black87 : Colors.white,
            fontSize: 14,
          ),
        ),
        onTap: o,
      );

  Widget _buildMonthlyComparison(ExpenseProvider p, int mode) {
    double maxVal = (p.totalIncome > p.totalExpenseOnly
        ? p.totalIncome
        : p.totalExpenseOnly);
    if (maxVal == 0) maxVal = 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "SNAPSHOT",
          style: TextStyle(
            color: mode == 2 ? Colors.black45 : Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        _comparisonBar(
          "Income",
          p.totalIncome,
          Colors.blueAccent,
          p.totalIncome / maxVal,
          mode,
          p.currencySymbol,
        ),
        const SizedBox(height: 12),
        _comparisonBar(
          "Expense",
          p.totalExpenseOnly,
          Colors.redAccent,
          p.totalExpenseOnly / maxVal,
          mode,
          p.currencySymbol,
        ),
      ],
    );
  }

  Widget _comparisonBar(
    String l,
    double v,
    Color c,
    double f,
    int mode,
    String currency,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l,
            style: TextStyle(
              color: mode == 2 ? Colors.black87 : Colors.white,
              fontSize: 11,
            ),
          ),
          Text(
            "$currency${v.toStringAsFixed(0)}",
            style: TextStyle(
              color: c,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      LinearProgressIndicator(
        value: f,
        backgroundColor: Colors.white10,
        color: c,
        minHeight: 6,
        borderRadius: BorderRadius.circular(10),
      ),
    ],
  );
}
