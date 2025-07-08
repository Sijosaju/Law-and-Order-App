import 'package:flutter/material.dart';
import 'package:law_app/screens/chat_screen.dart';
import 'package:law_app/widgets/modern_action_card.dart';
import 'package:law_app/widgets/legal_tip_card.dart';
import 'package:law_app/screens/library_screen.dart';
import 'package:law_app/screens/find_lawyer_screen.dart';
import 'package:law_app/screens/emergency_screen.dart';
import 'package:law_app/screens/file_fir_screen.dart';
import 'package:law_app/screens/track_case_screen.dart';



class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation _fadeAnimation;
  late Animation _slideAnimation;

  bool _isMenuOpen = false;
  bool _isSearchOpen = false;
  final TextEditingController _searchController = TextEditingController();

  // --- DATA FOR SEARCH ---
  final List<Map<String, dynamic>> _quickActions = [
    {
      'icon': Icons.chat_bubble,
      'title': 'AI Legal Chat',
      'subtitle': 'Get instant answers',
      'gradient': [const Color(0xFF00D4FF), const Color(0xFF5B73FF)],
      'onTap': () {},
    },
    {
      'icon': Icons.description,
      'title': 'File FIR',
      'subtitle': 'File complaint online',
      'gradient': [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)],
      'onTap': () {},
    },
    {
      'icon': Icons.person_search,
      'title': 'Find Lawyer',
      'subtitle': 'Connect with experts',
      'gradient': [const Color(0xFF4ECDC4), const Color(0xFF44A08D)],
      'onTap': () {},
    },
    {
      'icon': Icons.track_changes,
      'title': 'Track Case',
      'subtitle': 'Check case status',
      'gradient': [const Color(0xFF667eea), const Color(0xFF764ba2)],
      'onTap': () {},
    },
  ];

  final List<Map<String, dynamic>> _legalInsights = [
    {
      'title': 'Know Your Rights During Arrest',
      'description': 'Understanding your fundamental rights during police custody is crucial...',
      'icon': Icons.security,
    },
    {
      'title': 'Property Documentation Guide',
      'description': 'Essential documents needed for property transactions and disputes...',
      'icon': Icons.home,
    },
    {
      'title': 'Consumer Protection Laws',
      'description': 'Learn about your rights as a consumer in various situations...',
      'icon': Icons.shopping_cart,
    },
  ];

  // --- FILTERED LISTS ---
  List<Map<String, dynamic>> _filteredQuickActions = [];
  List<Map<String, dynamic>> _filteredLegalInsights = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward();

    // Initially, filtered lists are the same as originals
    _filteredQuickActions = List.from(_quickActions);
    _filteredLegalInsights = List.from(_legalInsights);

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearchOpen = !_isSearchOpen;
      if (!_isSearchOpen) {
        _searchController.clear();
        // Reset filtered lists
        _filteredQuickActions = List.from(_quickActions);
        _filteredLegalInsights = List.from(_legalInsights);
      }
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredQuickActions = List.from(_quickActions);
        _filteredLegalInsights = List.from(_legalInsights);
      } else {
        _filteredQuickActions = _quickActions.where((action) {
          return action['title'].toLowerCase().contains(query) ||
              action['subtitle'].toLowerCase().contains(query);
        }).toList();

        _filteredLegalInsights = _legalInsights.where((tip) {
          return tip['title'].toLowerCase().contains(query) ||
              tip['description'].toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Widget _buildSideMenu() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      left: _isMenuOpen ? 0 : -280,
      top: 0,
      bottom: 0,
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D3A),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(4, 0),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Menu Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF00D4FF), Color(0xFF5B73FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A1D3A), Color(0xFF0A0E27)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.home,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'LexAid',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Menu Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  children: [
                    _buildMenuItem(Icons.dashboard, 'Dashboard', 0, true, () {
                      _toggleMenu(); // already on dashboard
                    }),
                    _buildMenuItem(Icons.chat_bubble_outline, 'AI Legal Assistant', 1, false, () {
                      _toggleMenu();
                       Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ChatScreen()),
                      );
                    }),
                    _buildMenuItem(Icons.description_outlined, 'FIR Assistance', 2, false, () {
                      _toggleMenu();
                    }),
                    _buildMenuItem(Icons.library_books_outlined, 'Legal Library', 3, false, () {
                      _toggleMenu();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LibraryScreen()),
                      );
                    }),
                    _buildMenuItem(Icons.phone_outlined, 'Helplines', 4, false, () {
                      _toggleMenu();
                       Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => EmergencyScreen()),
                      );
                      // TODO: Replace with your actual page
                    }),
                    _buildMenuItem(Icons.article_outlined, 'Legal Templates', 5, false, () {
                      _toggleMenu();
                      // TODO: Replace with your actual page
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, int index, bool isSelected, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF00D4FF).withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: isSelected ? Border.all(color: const Color(0xFF00D4FF).withOpacity(0.5), width: 1) : null,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xFF00D4FF) : Colors.white70,
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? const Color(0xFF00D4FF) : Colors.white70,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 16,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main Content
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: 1.2,
                colors: [
                  Color(0xFF1A1D3A),
                  Color(0xFF0A0E27),
                ],
              ),
            ),
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation as Animation<double>,
                child: SlideTransition(
                  position: _slideAnimation as Animation<Offset>,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      bottom: MediaQuery.of(context).padding.bottom + 80,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            // Menu Toggle Button
                            GestureDetector(
                              onTap: _toggleMenu,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE53E3E),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.dashboard,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Dashboard Title
                            const Expanded(
                              child: Text(
                                'Dashboard',
                                style: TextStyle(
                                  fontSize: 22,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            // Search Button
                            GestureDetector(
                              onTap: _toggleSearch,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE53E3E),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFE53E3E).withOpacity(0.3),
                                      blurRadius: 15,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _isSearchOpen ? Icons.close : Icons.search,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        // Welcome Section
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Welcome to\n',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      foreground: Paint()
                                        ..shader = const LinearGradient(
                                          colors: [Color(0xFF00D4FF), Color(0xFF5B73FF)],
                                        ).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'LexAid',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      foreground: Paint()
                                        ..shader = const LinearGradient(
                                          colors: [Color(0xFF00D4FF), Color(0xFF5B73FF)],
                                        ).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Your AI-powered legal assistant for navigating Indian law.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white60,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        // Search Bar Section (Animated)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: _isSearchOpen ? 60 : 0,
                          child: _isSearchOpen
                              ? Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.1),
                                        Colors.white.withOpacity(0.05),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                      width: 1,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _searchController,
                                    autofocus: true,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(
                                      hintText: 'Search legal help...',
                                      hintStyle: TextStyle(color: Colors.white60),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 16,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.search,
                                        color: Color(0xFF00D4FF),
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        if (_isSearchOpen) const SizedBox(height: 20),
                        // Quick Actions Section
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 360,
                          child: _filteredQuickActions.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No actions found.',
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                )
                              : GridView.count(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 1.1,
                                  physics: const NeverScrollableScrollPhysics(),
                                  children: _filteredQuickActions.map((action) {
VoidCallback? actionTap;
if (action['title'] == 'Find Lawyer') {
  actionTap = () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FindLawyerScreen()),
    );
  };
} else if (action['title'] == 'AI Legal Chat') {
  actionTap = () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatScreen()),
    );
  };
} else if (action['title'] == 'File FIR') {
  actionTap = () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FileFirScreen()),
    );
  };
} else if (action['title'] == 'Track Case') {
  actionTap = () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TrackCaseScreen()),
    );
  };
} else {
  actionTap = () {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${action['title']} coming soon')),
    );
  };
}


  return ModernActionCard(
    icon: action['icon'],
    title: action['title'],
    subtitle: action['subtitle'],
    gradient: action['gradient'],
    onTap: actionTap,
  );
}).toList(),

                                ),
                        ),
                        const SizedBox(height: 40),
                        // Legal Insights Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Legal Insights',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text(
                                'View All',
                                style: TextStyle(
                                  color: Color(0xFF00D4FF),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: _filteredLegalInsights.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No insights found.',
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                )
                              : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _filteredLegalInsights.length,
                                  itemBuilder: (context, index) {
                                    final tip = _filteredLegalInsights[index];
                                    return Container(
                                      width: 280,
                                      margin: const EdgeInsets.only(right: 16),
                                      child: LegalTipCard(
                                        title: tip['title'],
                                        description: tip['description'],
                                        icon: tip['icon'],
                                      ),
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Menu Overlay
          if (_isMenuOpen)
            GestureDetector(
              onTap: _toggleMenu,
              child: Container(
                color: Colors.black26,
              ),
            ),
          // Side Menu
          _buildSideMenu(),
        ],
      ),
    );
  }
}
