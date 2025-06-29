import 'package:flutter/material.dart';

class SectionDetailPage extends StatelessWidget {
  final String actName;
  final Map<String, dynamic> section;

  const SectionDetailPage({
    super.key,
    required this.actName,
    required this.section,
  });


@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFF0A0E21),
    appBar: AppBar(
      backgroundColor: const Color(0xFF0A0E21),
      title: Text(
        "$actName - Sec ${section['section_number']}",
        style: const TextStyle(color: Colors.white),
      ),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        color: const Color(0xFF1D1E33),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Sec ${section['section_number']} - ${section['title']}",
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                section['content'],
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

}


