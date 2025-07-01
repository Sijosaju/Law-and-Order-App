import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart';
import 'chat_screen.dart';
import 'library_screen.dart';
import 'emergency_screen.dart';
import 'profile_screen.dart';
import '/widgets/modern_sos_button.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _fabController;

  final List<Widget> _screens = [
    HomeScreen(),
    ChatScreen(),
    LibraryScreen(),
    EmergencyScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Color(0xFF1A1D3A), // Your color
        selectedItemColor: Color(0xFF00D4FF),
        unselectedItemColor: Colors.white38,
        elevation: 0,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: (index) {
          setState(() => _currentIndex = index);
          HapticFeedback.lightImpact();
        },
        items: [
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.home, 0),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.chat_bubble, 1),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.library_books, 2),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.emergency, 3),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.person, 4),
            label: '',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0 ? ModernSOSButton() : null,
    );
  }

  Widget _buildNavIcon(IconData icon, int index) {
    bool isSelected = _currentIndex == index;
    return Icon(
      icon,
      size: 30, // Make icons larger for a bolder look
      color: isSelected ? Color(0xFF00D4FF) : Colors.white38,
    );
  }
}

