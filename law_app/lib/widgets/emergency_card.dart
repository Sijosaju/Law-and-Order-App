import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added import for HapticFeedback

class EmergencyCard extends StatelessWidget {
  final String title;
  final String number;
  final IconData icon;
  final Color color;

  const EmergencyCard({
    Key? key,
    required this.title,
    required this.number,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(20),
        leading: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        subtitle: Text(
          'Dial $number',
          style: TextStyle(
            color: Colors.white60,
            fontSize: 16,
          ),
        ),
        trailing: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(Icons.phone, color: Colors.white),
            onPressed: () {
              HapticFeedback.mediumImpact();
            },
          ),
        ),
      ),
    );
  }
}