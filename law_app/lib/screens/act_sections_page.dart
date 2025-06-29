import 'package:flutter/material.dart';
import 'section_detail_page.dart';

class ActSectionsPage extends StatelessWidget {
  final String actName;
  final List sections;
  final String? description; // ✅ Add this line

  const ActSectionsPage({super.key, required this.actName, required this.sections,this.description,});

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFF0A0E21),
    appBar: AppBar(
      backgroundColor: const Color(0xFF0A0E21),
      title: Text(actName, style: const TextStyle(color: Colors.white)),
    ),
    body: sections.isEmpty
        ? Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              color: const Color(0xFF1D1E33),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  description ?? "No details available for this Act.",
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
            ),
          )
        : ListView.builder(
            itemCount: sections.length,
            itemBuilder: (context, index) {
              final section = sections[index];
              return Card(
                color: const Color(0xFF1D1E33),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(
                    "Sec ${section['section_number']} - ${section['title']}",
                    style: const TextStyle(
                        color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    section['content'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SectionDetailPage(
                          actName: actName,
                          section: section,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
  );
}

}

