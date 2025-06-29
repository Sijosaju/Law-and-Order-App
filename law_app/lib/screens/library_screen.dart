import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:law_app/screens/act_sections_page.dart';
import 'package:law_app/screens/article_detail_page.dart';
import 'package:law_app/screens/case_detail_page.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  List<dynamic> acts = [];
  List<dynamic> articles = [];
  List<dynamic> cases = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchData();
  }

  Future<void> fetchData() async {
    const String baseUrl = "https://law-and-order-app.onrender.com";

    try {
      final actResponse = await http.get(Uri.parse("$baseUrl/acts"));
      final articleResponse = await http.get(Uri.parse("$baseUrl/articles"));
      final caseResponse = await http.get(Uri.parse("$baseUrl/cases"));

      setState(() {
        acts = json.decode(actResponse.body);
        articles = json.decode(articleResponse.body);
        cases = json.decode(caseResponse.body);
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Fetch error: $e");
      setState(() => isLoading = false);
    }
  }

  void showSections(Map<String, dynamic> act) {
    final List sections = act['sections'] ?? [];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1D1E33),
        title: Text(
          act['act_name'],
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: sections.length,
            separatorBuilder: (_, __) => const Divider(color: Colors.grey),
            itemBuilder: (context, index) {
              final section = sections[index];
              return ListTile(
                title: Text(
                  "Sec ${section['section_number']} - ${section['title']}",
                  style: const TextStyle(color: Colors.lightBlueAccent),
                ),
                subtitle: Text(
                  section['content'],
                  style: const TextStyle(color: Colors.white),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget buildCard(String title, String subtitle, {VoidCallback? onTap}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: const Color(0xFF1D1E33),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        title: Text(
          title,
          style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E21),
        title: const Text("Legal Library", style: TextStyle(color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.cyanAccent,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.cyanAccent,
          tabs: const [
            Tab(text: "Acts"),
            Tab(text: "Articles"),
            Tab(text: "Cases"),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          : TabBarView(
              controller: _tabController,
              children: [
                // Acts
                ListView.builder(
                  itemCount: acts.length,
                  itemBuilder: (context, index) {
                    final act = acts[index];
                    return buildCard(
                      act['act_name'],
                      act['description'],
                      onTap: () {
  Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => ActSectionsPage(
      actName: act['act_name'],
      sections: act['sections'],
      description: act['description'], // ✅ Pass the value here
    ),
  ),
);

},
                    );
                  },
                ),

                // Articles
                ListView.builder(
                  itemCount: articles.length,
                  itemBuilder: (context, index) {
                    final article = articles[index];
                    return buildCard(
                      "Article ${article['article_number']} - ${article['title']}",
                      article['content'],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ArticleDetailPage(
                              title: "Article ${article['article_number']} - ${article['title']}",
                              content: article['content'],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),

                // Cases
                ListView.builder(
                  itemCount: cases.length,
                  itemBuilder: (context, index) {
                    final caseItem = cases[index];
                    return buildCard(
                      caseItem['title'],
                      "${caseItem['year']} - ${caseItem['summary']}",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CaseDetailPage(
                              title: caseItem['title'],
                              year: caseItem['year'],
                              summary: caseItem['summary'],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
    );
  }
}



