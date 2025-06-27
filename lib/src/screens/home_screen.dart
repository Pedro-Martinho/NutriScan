import 'package:flutter/material.dart';
import '../screens/scan_screen.dart';
import '../screens/history_screen.dart';
import '../screens/education_screen.dart';
import '../screens/overview_screen.dart';
import '../screens/comparison_screen.dart';
import '../localization/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static final GlobalKey<_HomeScreenState> homeKey = GlobalKey<_HomeScreenState>();

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 2;

  void setSelectedIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _screens = [
    const HistoryScreen(),
    const EducationScreen(),
    const ScanScreen(),
    const OverviewScreen(),
    const ComparisonScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.history),
            label: l10n.translate('bottom_nav_history'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.school),
            label: l10n.translate('bottom_nav_education'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.qr_code_scanner),
            label: l10n.translate('bottom_nav_scan'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            label: l10n.translate('bottom_nav_overview'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.compare_arrows),
            label: l10n.translate('bottom_nav_compare'),
          ),
        ],
      ),
    );
  }
} 