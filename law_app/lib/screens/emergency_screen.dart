import 'package:flutter/material.dart';
import 'package:law_app/widgets/emergency_card.dart';

class EmergencyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Emergency Contacts'),
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
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            EmergencyCard(
              title: 'Police',
              number: '100',
              icon: Icons.local_police,
              color: Color(0xFF00D4FF),
            ),
            EmergencyCard(
              title: 'Women Helpline',
              number: '1091',
              icon: Icons.woman,
              color: Color(0xFFFF6B6B),
            ),
            EmergencyCard(
              title: 'Legal Aid',
              number: '15100',
              icon: Icons.gavel,
              color: Color(0xFF4ECDC4),
            ),
            EmergencyCard(
              title: 'Child Helpline',
              number: '1098',
              icon: Icons.child_care,
              color: Color(0xFF667eea),
            ),
            EmergencyCard(
              title: 'Senior Citizen Helpline',
              number: '14567',
              icon: Icons.elderly,
              color: Color(0xFFFF8E53),
            ),
          ],
        ),
      ),
    );
  }
}