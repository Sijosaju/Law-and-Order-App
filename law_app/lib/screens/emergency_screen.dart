import 'package:flutter/material.dart';
import 'package:law_app/widgets/emergency_card.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyScreen extends StatelessWidget {
  
  // Function to make phone calls
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        throw 'Could not launch phone app';
      }
    } catch (e) {
      print('Error making call: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A1D3A),
      appBar: AppBar(
        backgroundColor: Color(0xFF1A1D3A),
        elevation: 0,
        title: Text(
          'Emergency Contacts',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
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
              onCall: () => _makePhoneCall('100'),
            ),
            EmergencyCard(
              title: 'Women Helpline',
              number: '1091',
              icon: Icons.woman,
              color: Color(0xFFFF6B6B),
              onCall: () => _makePhoneCall('1091'),
            ),
            EmergencyCard(
              title: 'Legal Aid',
              number: '15100',
              icon: Icons.gavel,
              color: Color(0xFF4ECDC4),
              onCall: () => _makePhoneCall('15100'),
            ),
            EmergencyCard(
              title: 'Child Helpline',
              number: '1098',
              icon: Icons.child_care,
              color: Color(0xFF667eea),
              onCall: () => _makePhoneCall('1098'),
            ),
            EmergencyCard(
              title: 'Senior Citizen Helpline',
              number: '14567',
              icon: Icons.elderly,
              color: Color(0xFFFF8E53),
              onCall: () => _makePhoneCall('14567'),
            ),
          ],
        ),
      ),
    );
  }
}
