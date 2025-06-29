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
      extendBody: true,
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        margin: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1A1D3A).withOpacity(0.9),
              Color(0xFF2A2D5A).withOpacity(0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            selectedItemColor: Color(0xFF00D4FF),
            unselectedItemColor: Colors.white38,
            elevation: 0,
            onTap: (index) {
              setState(() => _currentIndex = index);
              HapticFeedback.lightImpact();
            },
            items: [
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.home, 0),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.chat_bubble, 1),
                label: 'AI Chat',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.library_books, 2),
                label: 'Library',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.emergency, 3),
                label: 'Emergency',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.person, 4),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _currentIndex == 0 ? ModernSOSButton() : null,
    );
  }

  Widget _buildNavIcon(IconData icon, int index) {
    bool isSelected = _currentIndex == index;
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                colors: [Color(0xFF00D4FF), Color(0xFF5B73FF)],
              )
            : null,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Color(0xFF00D4FF).withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Icon(icon, size: 24),
    );
  }
}