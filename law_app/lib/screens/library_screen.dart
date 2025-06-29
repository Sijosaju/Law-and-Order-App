import 'package:flutter/material.dart';

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
    loadMockData(); // Use mock data instead of HTTP call
  }

  void loadMockData() async {
    await Future.delayed(const Duration(seconds: 1)); // simulate loading
    setState(() {
      acts = [
        {
          'act_id': '1',
          'act_name': 'Consumer Protection Act',
          'description': 'An Act to protect the interests of consumers.',
          'sections': [
            {
              'section_number': '1',
              'title': 'Preliminary',
              'content': 'This section explains the basics of the Act.'
            },
            {
              'section_number': '2',
              'title': 'Definitions',
              'content': 'This section provides definitions for terms used in the Act.'
            },
          ]
        },
      ];
      articles = [
        {
          'article_number': '21',
          'title': 'Right to Education',
          'content': 'The State shall provide free and compulsory education to children.'
        },
      ];
      cases = [
        {
          'title': 'Kesavananda Bharati v. State of Kerala',
          'year': '1973',
          'summary': 'Introduced the Basic Structure doctrine in the Indian Constitution.'
        },
      ];
      isLoading = false;
    });
  }

  void showSections(String actId) {
    final act = acts.firstWhere((a) => a['act_id'] == actId);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(act['act_name']),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: act['sections'].length,
            itemBuilder: (context, index) {
              final section = act['sections'][index];
              return ListTile(
                title: Text("Sec ${section['section_number']} - ${section['title']}"),
                subtitle: Text(section['content']),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Legal Library"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Acts"),
            Tab(text: "Articles"),
            Tab(text: "Cases"),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Acts tab
                ListView.builder(
                  itemCount: acts.length,
                  itemBuilder: (context, index) {
                    final act = acts[index];
                    return ListTile(
                      title: Text(act['act_name']),
                      subtitle: Text(act['description']),
                      onTap: () => showSections(act['act_id']),
                    );
                  },
                ),
                // Articles tab
                ListView.builder(
                  itemCount: articles.length,
                  itemBuilder: (context, index) {
                    final article = articles[index];
                    return ListTile(
                      title: Text("Article ${article['article_number']} - ${article['title']}"),
                      subtitle: Text(article['content']),
                    );
                  },
                ),
                // Cases tab
                ListView.builder(
                  itemCount: cases.length,
                  itemBuilder: (context, index) {
                    final caseItem = cases[index];
                    return ListTile(
                      title: Text(caseItem['title']),
                      subtitle: Text("${caseItem['year']} - ${caseItem['summary']}"),
                    );
                  },
                ),
              ],
            ),
    );
  }
}

