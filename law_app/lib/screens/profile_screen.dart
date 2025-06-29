import 'package:flutter/material.dart';
import 'package:law_app/widgets/profile_option.dart';

class ProfileScreen extends StatelessWidget {
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
          padding: EdgeInsets.fromLTRB(16, 16, 16, 90), // Added bottom padding of 90 to clear navigation bar
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
              Text(
                'Legal Help User',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                'user@legalhelpindia.com',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white60,
                ),
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
            ],
          ),
        ),
      ),
    );
  }
}