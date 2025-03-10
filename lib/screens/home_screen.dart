import 'package:flutter/material.dart';
import 'package:halalapp/services/auth_service.dart';
import 'package:halalapp/screens/scan_screen.dart';
import 'package:halalapp/screens/search_screen.dart';
import 'package:halalapp/screens/chatbot_screen.dart';
import 'package:halalapp/screens/profile_screen.dart';
import 'package:halalapp/screens/prayer_time_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  final int initialTab;

  const HomeScreen({
    super.key,
    this.initialTab = 0,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;
  final AuthService _authService = AuthService();

  final List<Widget> _screens = [
    const PrayerTimeScreen(),
    const ScanScreen(),
    const SearchScreen(),
    const ChatbotScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
            },
          ),
        ],
      ),
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
            icon: const Icon(Icons.mosque),
            label: l10n.prayerTimes,
          ),
          NavigationDestination(
            icon: const Icon(Icons.qr_code_scanner),
            label: l10n.scan,
          ),
          NavigationDestination(
            icon: const Icon(Icons.search),
            label: l10n.search,
          ),
          NavigationDestination(
            icon: const Icon(Icons.chat),
            label: l10n.chatbot,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person),
            label: l10n.profile,
          ),
        ],
      ),
    );
  }
}
