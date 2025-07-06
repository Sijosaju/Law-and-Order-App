import 'package:flutter/material.dart';
import 'package:law_app/widgets/profile_option.dart';
import 'package:law_app/screens/login_screen.dart';
import 'package:law_app/services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await AuthService().signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              Color(0xFF1A1D3A),
              Color(0xFF0A0E27),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 90),
          child: Column(
            children: [
              SizedBox(height: 20),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF00D4FF), Color(0xFF5B73FF)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF00D4FF).withOpacity(0.3),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Icon(Icons.person, size: 60, color: Colors.white),
              ),
              SizedBox(height: 24),
              FutureBuilder<Map<String, String>>(
                future: AuthService().getUserData(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Column(
                      children: [
                        Text(
                          snapshot.data!['name'] ?? 'Legal Help User',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          snapshot.data!['email'] ?? 'user@legalhelpindia.com',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      Text(
                        'Loading...',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Loading...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: 40),
              ProfileOption(
                icon: Icons.history,
                title: 'Chat History',
                subtitle: 'View previous conversations',
                onTap: () {},
              ),
              ProfileOption(
                icon: Icons.bookmark,
                title: 'Saved Articles',
                subtitle: 'Your bookmarked content',
                onTap: () {},
              ),
              ProfileOption(
                icon: Icons.notifications,
                title: 'Notifications',
                subtitle: 'Manage your alerts',
                onTap: () {},
              ),
              ProfileOption(
                icon: Icons.privacy_tip,
                title: 'Privacy Policy',
                subtitle: 'Read our privacy terms',
                onTap: () {},
              ),
              ProfileOption(
                icon: Icons.help,
                title: 'Help & Support',
                subtitle: 'Get assistance and FAQ',
                onTap: () {},
              ),
              ProfileOption(
                icon: Icons.info,
                title: 'About',
                subtitle: 'App version and information',
                onTap: () {},
              ),
              ProfileOption(
                icon: Icons.logout,
                title: 'Logout',
                subtitle: 'Sign out of your account',
                onTap: () => _logout(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

