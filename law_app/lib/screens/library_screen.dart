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

// Replace your fetchData() method with this improved version
// Replace your fetchData() method with this improved version
Future<void> fetchData() async {
  const String baseUrl = "https://law-and-order-app.onrender.com";
  
  print("🚀 Starting data fetch from: $baseUrl");

  try {
    // First, test if the server is reachable
    print("📡 Testing server connectivity...");
    
    final healthResponse = await http.get(
      Uri.parse("$baseUrl/health"),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw Exception('Server health check timeout - server may be sleeping');
      },
    );
    
    print("✅ Server health status: ${healthResponse.statusCode}");
    
    if (healthResponse.statusCode != 200) {
      throw Exception('Server is not healthy: ${healthResponse.statusCode}');
    }

    // Now fetch the actual data with proper error handling
    print("📚 Fetching acts, articles, and cases...");
    
    final futures = await Future.wait([
      _fetchWithRetry("$baseUrl/acts", "acts"),
      _fetchWithRetry("$baseUrl/articles", "articles"), 
      _fetchWithRetry("$baseUrl/cases", "cases"),
    ]);

    final actsResponse = futures[0];
    final articlesResponse = futures[1]; 
    final casesResponse = futures[2];

    // Parse responses
    List<dynamic> fetchedActs = [];
    List<dynamic> fetchedArticles = [];
    List<dynamic> fetchedCases = [];

    if (actsResponse.statusCode == 200) {
      try {
        final actsData = json.decode(actsResponse.body);
        if (actsData is List) {
          fetchedActs = actsData;
          print("✅ Loaded ${fetchedActs.length} acts");
        } else if (actsData is Map && actsData.containsKey('error')) {
          print("❌ Acts API error: ${actsData['error']}");
        }
      } catch (e) {
        print("❌ Error parsing acts JSON: $e");
        print("Raw acts response: ${actsResponse.body}");
      }
    } else {
      print("❌ Acts request failed: ${actsResponse.statusCode}");
      print("Acts error body: ${actsResponse.body}");
    }

    if (articlesResponse.statusCode == 200) {
      try {
        final articlesData = json.decode(articlesResponse.body);
        if (articlesData is List) {
          fetchedArticles = articlesData;
          print("✅ Loaded ${fetchedArticles.length} articles");
        } else if (articlesData is Map && articlesData.containsKey('error')) {
          print("❌ Articles API error: ${articlesData['error']}");
        }
      } catch (e) {
        print("❌ Error parsing articles JSON: $e");
        print("Raw articles response: ${articlesResponse.body}");
      }
    } else {
      print("❌ Articles request failed: ${articlesResponse.statusCode}");
      print("Articles error body: ${articlesResponse.body}");
    }

    if (casesResponse.statusCode == 200) {
      try {
        final casesData = json.decode(casesResponse.body);
        if (casesData is List) {
          fetchedCases = casesData;
          print("✅ Loaded ${fetchedCases.length} cases");  
        } else if (casesData is Map && casesData.containsKey('error')) {
          print("❌ Cases API error: ${casesData['error']}");
        }
      } catch (e) {
        print("❌ Error parsing cases JSON: $e");
        print("Raw cases response: ${casesResponse.body}");
      }
    } else {
      print("❌ Cases request failed: ${casesResponse.statusCode}");
      print("Cases error body: ${casesResponse.body}");
    }

    // Update state
    setState(() {
      acts = fetchedActs;
      articles = fetchedArticles;
      cases = fetchedCases;
      isLoading = false;
    });

    print("🎉 Data fetch completed successfully!");
    print("Final counts - Acts: ${acts.length}, Articles: ${articles.length}, Cases: ${cases.length}");

  } catch (e) {
    print("💥 Critical error in fetchData: $e");
    
    setState(() {
      isLoading = false;
    });

    // Show user-friendly error message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('timeout') 
              ? "Server is starting up, please wait and try again..."
              : "Failed to load data: ${e.toString()}",
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () {
              setState(() => isLoading = true);
              fetchData();
            },
          ),
        ),
      );
    }
  }
}

// Helper method to fetch with retry logic
Future<http.Response> _fetchWithRetry(String url, String dataType) async {
  int maxRetries = 3;
  int retryDelay = 2; // seconds

  for (int attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      print("🔄 Fetching $dataType (attempt $attempt/$maxRetries)...");
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'LawApp/1.0',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout for $dataType');
        },
      );

      print("📊 $dataType response: ${response.statusCode}");
      return response;

    } catch (e) {
      print("⚠️ $dataType attempt $attempt failed: $e");
      
      if (attempt == maxRetries) {
        rethrow; // Last attempt, throw the error
      }
      
      // Wait before retrying
      await Future.delayed(Duration(seconds: retryDelay));
      retryDelay *= 2; // Exponential backoff
    }
  }
  
  throw Exception('All retry attempts failed for $dataType');
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



