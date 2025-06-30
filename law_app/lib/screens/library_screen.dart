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
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> acts = [];
  List<dynamic> articles = [];
  List<dynamic> cases = [];

  // Filtered lists for search
  List<dynamic> filteredActs = [];
  List<dynamic> filteredArticles = [];
  List<dynamic> filteredCases = [];

  bool isLoading = true;
  bool isSearching = false;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchData();
    
    // Listen to search controller changes
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      searchQuery = _searchController.text.toLowerCase();
      isSearching = searchQuery.isNotEmpty;
      _performSearch();
    });
  }

  void _performSearch() {
    if (searchQuery.isEmpty) {
      filteredActs = acts;
      filteredArticles = articles;
      filteredCases = cases;
      return;
    }

    // Search in Acts
    filteredActs = acts.where((act) {
      final actName = (act['act_name'] ?? '').toString().toLowerCase();
      final description = (act['description'] ?? '').toString().toLowerCase();
      
      // Search in act name and description
      bool matchesAct = actName.contains(searchQuery) || description.contains(searchQuery);
      
      // Search in sections
      bool matchesSection = false;
      if (act['sections'] != null) {
        final sections = act['sections'] as List;
        matchesSection = sections.any((section) {
          final sectionTitle = (section['title'] ?? '').toString().toLowerCase();
          final sectionContent = (section['content'] ?? '').toString().toLowerCase();
          final sectionNumber = (section['section_number'] ?? '').toString().toLowerCase();
          
          return sectionTitle.contains(searchQuery) || 
                 sectionContent.contains(searchQuery) ||
                 sectionNumber.contains(searchQuery);
        });
      }
      
      return matchesAct || matchesSection;
    }).toList();

    // Search in Articles
    filteredArticles = articles.where((article) {
      final title = (article['title'] ?? '').toString().toLowerCase();
      final content = (article['content'] ?? '').toString().toLowerCase();
      final articleNumber = (article['article_number'] ?? '').toString().toLowerCase();
      
      return title.contains(searchQuery) || 
             content.contains(searchQuery) ||
             articleNumber.contains(searchQuery);
    }).toList();

    // Search in Cases
    filteredCases = cases.where((caseItem) {
      final title = (caseItem['title'] ?? '').toString().toLowerCase();
      final summary = (caseItem['summary'] ?? '').toString().toLowerCase();
      final year = (caseItem['year'] ?? '').toString().toLowerCase();
      
      return title.contains(searchQuery) || 
             summary.contains(searchQuery) ||
             year.contains(searchQuery);
    }).toList();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      searchQuery = '';
      isSearching = false;
      filteredActs = acts;
      filteredArticles = articles;
      filteredCases = cases;
    });
  }

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
      // Initialize filtered lists
      filteredActs = fetchedActs;
      filteredArticles = fetchedArticles;
      filteredCases = fetchedCases;
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

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search acts, articles, cases, sections...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: const Icon(Icons.search, color: Colors.cyanAccent),
          suffixIcon: isSearching
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.cyanAccent),
                  onPressed: _clearSearch,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final totalResults = filteredActs.length + filteredArticles.length + filteredCases.length;
    
    if (totalResults == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'No results found for "$searchQuery"',
              style: TextStyle(color: Colors.grey[400], fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Try different keywords or check spelling',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView(
      children: [
        if (filteredActs.isNotEmpty) ...[
          _buildSectionHeader('Acts (${filteredActs.length})'),
          ...filteredActs.map((act) => buildCard(
            act['act_name'],
            act['description'],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ActSectionsPage(
                    actName: act['act_name'],
                    sections: act['sections'],
                    description: act['description'],
                  ),
                ),
              );
            },
          )),
        ],
        
        if (filteredArticles.isNotEmpty) ...[
          _buildSectionHeader('Articles (${filteredArticles.length})'),
          ...filteredArticles.map((article) => buildCard(
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
          )),
        ],
        
        if (filteredCases.isNotEmpty) ...[
          _buildSectionHeader('Cases (${filteredCases.length})'),
          ...filteredCases.map((caseItem) => buildCard(
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
          )),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.cyanAccent,
          fontSize: 18,
          fontWeight: FontWeight.bold,
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
        bottom: isSearching ? null : TabBar(
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
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                : isSearching
                    ? _buildSearchResults()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          // Acts
                          ListView.builder(
                            itemCount: filteredActs.length,
                            itemBuilder: (context, index) {
                              final act = filteredActs[index];
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
                                        description: act['description'],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),

                          // Articles
                          ListView.builder(
                            itemCount: filteredArticles.length,
                            itemBuilder: (context, index) {
                              final article = filteredArticles[index];
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
                            itemCount: filteredCases.length,
                            itemBuilder: (context, index) {
                              final caseItem = filteredCases[index];
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
          ),
        ],
      ),
    );
  }
}



