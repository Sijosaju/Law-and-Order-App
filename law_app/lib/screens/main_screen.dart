import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart';
import 'chat_screen.dart';
import 'library_screen.dart';
import 'emergency_screen.dart';
import 'profile_screen.dart';
import 'find_lawyer_screen.dart';
import '/widgets/modern_sos_button.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _fabController;
  String _currentRoute = '/'; // Track current route for SOS button visibility
  
  // Create GlobalKeys for each tab's navigator
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  // Handle back button for nested navigation
  Future<bool> _onWillPop() async {
    final isFirstRouteInCurrentTab =
        !await _navigatorKeys[_currentIndex].currentState!.maybePop();
    
    if (isFirstRouteInCurrentTab) {
      // If we're on the first route of the current tab
      if (_currentIndex != 0) {
        // If not on home tab, go to home tab
        setState(() => _currentIndex = 0);
        return false;
      }
    }
    
    // If we're on the first route of home tab, allow app to close
    return isFirstRouteInCurrentTab;
  }

  // Check if we're on the actual home screen (not sub-screens)
  bool _isOnHomeScreen() {
    return _currentIndex == 0 && _currentRoute == '/';
  }

  // Get the appropriate screen for each tab and route
  Widget _getScreenForIndex(int index, RouteSettings routeSettings) {
    // Update current route when on home tab
    if (index == 0) {
      setState(() {
        _currentRoute = routeSettings.name ?? '/';
      });
    }
    
    switch (index) {
      case 0: // Home Tab
        switch (routeSettings.name) {
          case '/find-lawyer':
            return const FindLawyerScreen();
          case '/':
          default:
            return HomeScreen();
        }
      case 1: // Chat Tab
        return ChatScreen();
      case 2: // Library Tab
        return const LibraryScreen();
      case 3: // Emergency Tab
        return EmergencyScreen();
      case 4: // Profile Tab
        return const ProfileScreen();
      default:
        return HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Stack(
          children: List.generate(5, (index) {
            return Offstage(
              offstage: _currentIndex != index,
              child: Navigator(
                key: _navigatorKeys[index],
                onGenerateRoute: (routeSettings) {
                  return MaterialPageRoute(
                    builder: (context) => _getScreenForIndex(index, routeSettings),
                    settings: routeSettings,
                  );
                },
              ),
            );
          }),
        ),
        bottomNavigationBar: Theme(
          data: Theme.of(context).copyWith(
            // Remove the splash effect completely
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            // Customize the bottom navigation bar theme
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Color(0xFF1A1D3A),
              selectedItemColor: Color(0xFF00D4FF),
              unselectedItemColor: Colors.white38,
              elevation: 0,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              type: BottomNavigationBarType.fixed,
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            type: BottomNavigationBarType.fixed,
            backgroundColor: const Color(0xFF1A1D3A),
            selectedItemColor: const Color(0xFF00D4FF),
            unselectedItemColor: Colors.white38,
            elevation: 0,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            // Enable material state to control individual item effects
            enableFeedback: true,
            onTap: (index) {
              print('Bottom nav tapped: $index'); // Debug print
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
        ),
        // UPDATED: Show SOS button only on HomeScreen (not on sub-screens)
        floatingActionButton: _isOnHomeScreen() ? ModernSOSButton() : null,
      ),
    );
  }

  // FIXED: Removed the problematic InkWell that was intercepting taps
  Widget _buildNavIcon(IconData icon, int index) {
    bool isSelected = _currentIndex == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF00D4FF).withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(25),
        border: isSelected
            ? Border.all(color: const Color(0xFF00D4FF).withOpacity(0.3), width: 1)
            : null,
      ),
      child: Icon(
        icon,
        size: 28,
        color: isSelected ? const Color(0xFF00D4FF) : Colors.white38,
      ),
    );
  }
}

// Extension to provide easy navigation methods
extension MainScreenNavigation on BuildContext {
  void navigateToFindLawyer() {
    Navigator.of(this).pushNamed('/find-lawyer');
  }

  void navigateToHome() {
    Navigator.of(this).pushNamedAndRemoveUntil('/', (route) => false);
  }
}

