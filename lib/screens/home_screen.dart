import 'package:flutter/material.dart';
import 'package:halalapp/services/auth_service.dart';
import 'package:halalapp/screens/scan_screen.dart';
import 'package:halalapp/screens/search_screen.dart';
import 'package:halalapp/screens/chatbot_screen.dart';
import 'package:halalapp/screens/profile_screen.dart';
import 'package:halalapp/screens/prayer_time_screen.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('HalalApp'),
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
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.mosque),
            label: 'Prayer',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat),
            label: 'Ask',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
