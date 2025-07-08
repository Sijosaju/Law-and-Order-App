import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

class FindLawyerScreen extends StatefulWidget {
  const FindLawyerScreen({super.key});

  @override
  _FindLawyerScreenState createState() => _FindLawyerScreenState();
}

class _FindLawyerScreenState extends State<FindLawyerScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _showMap = false;
  String _selectedExpertise = 'All';
  String _selectedCity = 'All';
  double _minRating = 0.0;
  bool _verifiedOnly = false;
  Position? _currentPosition;

  List<Map<String, dynamic>> _lawyers = [];
  List<Map<String, dynamic>> _filteredLawyers = [];

  final List<String> _expertiseAreas = [
    'All',
    'Constitutional Law',
    'Criminal Law',
    'Civil Law',
    'Corporate Law',
    'Family Law',
    'Property Law',
    'Labor Law',
    'Tax Law',
    'Environmental Law',
    'Intellectual Property',
    'Banking Law',
    'Insurance Law',
    'Consumer Law'
  ];

  final List<String> _cities = [
    'All',
    'New Delhi',
    'Delhi', 
    'Mumbai',
    'Bangalore',
    'Chennai',
    'Kolkata',
    'Hyderabad',
    'Pune',
    'Ahmedabad',
    'Noida',
    'Gurgaon',
    'Ghaziabad',
    'Faridabad',
    'Jaipur',
    'Lucknow',
    'Bhopal',
    'Chandigarh',
    'Kochi',
    'Thiruvananthapuram',
    'Bhubaneswar',
    'Patna',
    'Ranchi',
    'Dehradun',
    'Indore',
    'Nagpur',
    'Nashik',
    'Coimbatore',
    'Madurai',
    'Visakhapatnam',
    'Vijayawada'
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
    _loadLawyers();
    _getCurrentLocation();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Helper function to extract clean lawyer name
  String _extractLawyerName(String fullText) {
    List<String> patterns = [
      'Address:',
      'Office:',
      'Chamber:',
      'Residence:',
      '\n',
      '  ', // Double space
    ];
    
    String cleanName = fullText;
    for (String pattern in patterns) {
      if (cleanName.contains(pattern)) {
        cleanName = cleanName.split(pattern)[0];
        break;
      }
    }
    
    cleanName = cleanName.trim();
    cleanName = cleanName.replaceAll(RegExp(r'\s+'), ' ');
    
    return cleanName;
  }

  // Helper function to extract address
  String _extractAddress(String fullText) {
    List<String> patterns = ['Address:', 'Office:', 'Chamber:', 'Residence:'];
    
    for (String pattern in patterns) {
      if (fullText.contains(pattern)) {
        String address = fullText.split(pattern)[1];
        return address.trim();
      }
    }
    
    List<String> lines = fullText.split('\n');
    if (lines.length > 1) {
      return lines.sublist(1).join(' ').trim();
    }
    
    return 'Address not available';
  }

  // Phone call functionality
  Future<void> _makePhoneCall(String phoneNumber) async {
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: cleanNumber,
    );
    
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch phone app'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error making call: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _loadLawyers() async {
    setState(() {
      _isSearching = true;
    });

    try {
      final response = await http.get(Uri.parse('https://law-and-order-app.onrender.com/lawyers'));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _lawyers = data.cast<Map<String, dynamic>>();
          _filteredLawyers = List.from(_lawyers);
        });
        print('✅ Loaded ${_lawyers.length} lawyers from backend');
      } else {
        print('❌ Failed to load lawyers: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load lawyers. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Error loading lawyers: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error. Please check your connection.'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isSearching = false;
    });
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _applyFilters() {
    setState(() {
      _filteredLawyers = _lawyers.where((lawyer) {
        String searchText = _searchController.text.toLowerCase();
        String lawyerName = _extractLawyerName(lawyer['name'] ?? '').toLowerCase();
        
        bool matchesSearch = searchText.isEmpty ||
            lawyerName.contains(searchText) ||
            (lawyer['expertise']?.toLowerCase()?.contains(searchText) ?? false) ||
            (lawyer['city']?.toLowerCase()?.contains(searchText) ?? false);

        bool matchesExpertise = _selectedExpertise == 'All' ||
            lawyer['expertise'] == _selectedExpertise;

        bool matchesCity = _selectedCity == 'All' ||
            lawyer['city'] == _selectedCity;

        bool matchesRating = (lawyer['rating'] ?? 0.0) >= _minRating;

        bool matchesVerified = !_verifiedOnly || (lawyer['verified'] == true);

        return matchesSearch && matchesExpertise && matchesCity && 
               matchesRating && matchesVerified;
      }).toList();
    });
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _buildFilterChip('Expertise', _selectedExpertise, _expertiseAreas, (value) {
            setState(() {
              _selectedExpertise = value;
            });
            _applyFilters();
          }),
          const SizedBox(width: 12),
          _buildFilterChip('City', _selectedCity, _cities, (value) {
            setState(() {
              _selectedCity = value;
            });
            _applyFilters();
          }),
          const SizedBox(width: 12),
          _buildRatingFilter(),
          const SizedBox(width: 12),
          _buildVerifiedFilter(),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String selected, List<String> options, Function(String) onSelected) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: const Color(0xFF1A1D3A),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          isScrollControlled: true,
          builder: (context) => Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select $label',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      String option = options[index];
                      return ListTile(
                        title: Text(
                          option,
                          style: const TextStyle(color: Colors.white),
                        ),
                        leading: Radio<String>(
                          value: option,
                          groupValue: selected,
                          onChanged: (value) {
                            onSelected(value!);
                            Navigator.pop(context);
                          },
                          activeColor: const Color(0xFF00D4FF),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF00D4FF).withOpacity(0.2), const Color(0xFF5B73FF).withOpacity(0.2)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF00D4FF).withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: $selected',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingFilter() {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1D3A),
            title: const Text('Minimum Rating', style: TextStyle(color: Colors.white)),
            content: StatefulBuilder(
              builder: (context, setDialogState) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Slider(
                    value: _minRating,
                    min: 0.0,
                    max: 5.0,
                    divisions: 10,
                    activeColor: const Color(0xFF00D4FF),
                    onChanged: (value) {
                      setDialogState(() {
                        _minRating = value;
                      });
                    },
                  ),
                  Text(
                    '${_minRating.toStringAsFixed(1)} stars and above',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _applyFilters();
                },
                child: const Text('Apply', style: TextStyle(color: Color(0xFF00D4FF))),
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF00D4FF).withOpacity(0.2), const Color(0xFF5B73FF).withOpacity(0.2)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF00D4FF).withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 16),
            const SizedBox(width: 4),
            Text(
              '${_minRating.toStringAsFixed(1)}+',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifiedFilter() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _verifiedOnly = !_verifiedOnly;
        });
        _applyFilters();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _verifiedOnly 
              ? [const Color(0xFF4ECDC4), const Color(0xFF44A08D)]
              : [const Color(0xFF00D4FF).withOpacity(0.2), const Color(0xFF5B73FF).withOpacity(0.2)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF00D4FF).withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.verified,
              color: _verifiedOnly ? Colors.white : const Color(0xFF00D4FF),
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              'Verified',
              style: TextStyle(
                color: _verifiedOnly ? Colors.white : const Color(0xFF00D4FF),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLawyerCard(Map<String, dynamic> lawyer) {
    String fullNameText = lawyer['name'] ?? 'Unknown Lawyer';
    String cleanName = _extractLawyerName(fullNameText);
    String address = _extractAddress(fullNameText);
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      lawyer['photoUrl'] ?? 'https://via.placeholder.com/150',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.white.withOpacity(0.2),
                        child: const Icon(Icons.person, color: Colors.white, size: 30),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              cleanName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (lawyer['verified'] == true)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified, color: Colors.white, size: 12),
                                  SizedBox(width: 4),
                                  Text(
                                    'Verified',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (lawyer['senior_advocate'] == true)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Senior',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lawyer['expertise'] ?? 'General Practice',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${lawyer['experience'] ?? 0} years experience',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              lawyer['description'] ?? 'Experienced legal practitioner',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.white.withOpacity(0.7), size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    lawyer['city'] ?? 'Unknown',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${lawyer['rating'] ?? 0.0} (${lawyer['reviews'] ?? 0} reviews)',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  lawyer['fee'] ?? '₹1000/hr',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Map<String, dynamic> lawyerWithCleanData = Map.from(lawyer);
                      lawyerWithCleanData['clean_name'] = cleanName;
                      lawyerWithCleanData['address'] = address;
                      _showLawyerProfile(lawyerWithCleanData);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF44A08D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('View Profile'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _bookConsultation(lawyer);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D4FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Book Now'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showLawyerProfile(Map<String, dynamic> lawyer) {
    String cleanName = lawyer['clean_name'] ?? _extractLawyerName(lawyer['name'] ?? '');
    String address = lawyer['address'] ?? _extractAddress(lawyer['name'] ?? '');
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1D3A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white30,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Profile header
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF00D4FF), width: 3),
                      ),
                      child: ClipOval(
                        child: Image.network(
                          lawyer['photoUrl'] ?? 'https://via.placeholder.com/150',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.white.withOpacity(0.2),
                            child: const Icon(Icons.person, color: Colors.white, size: 40),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  cleanName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (lawyer['verified'] == true)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.verified, color: Colors.white, size: 14),
                                      SizedBox(width: 4),
                                      Text(
                                        'Verified',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          if (lawyer['senior_advocate'] == true)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Senior Advocate',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            lawyer['expertise'] ?? 'General Practice',
                            style: const TextStyle(
                              color: Color(0xFF00D4FF),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '${lawyer['rating'] ?? 0.0} (${lawyer['reviews'] ?? 0} reviews)',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Profile sections
                _buildProfileSection('About', lawyer['description'] ?? 'Experienced legal practitioner'),
                const SizedBox(height: 16),
                _buildProfileSection('Experience', '${lawyer['experience'] ?? 0} years of legal practice'),
                const SizedBox(height: 16),
                _buildProfileSection('Court', lawyer['court'] ?? 'Supreme Court of India'),
                const SizedBox(height: 16),
                _buildProfileSection('Address', address),
                const SizedBox(height: 16),
                _buildProfileSection('Enrollment Number', lawyer['enrollment_number'] ?? 'Not available'),
                const SizedBox(height: 16),
                if (lawyer['registration_date'] != null)
                  _buildProfileSection('Registration Date', lawyer['registration_date']),
                const SizedBox(height: 16),
                _buildProfileSection('Consultation Fee', lawyer['fee'] ?? '₹1000/hr'),
                
                // Specializations
                if (lawyer['specializations'] != null && lawyer['specializations'].isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      const Text(
                        'Specializations',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (lawyer['specializations'] as List).map((spec) => 
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00D4FF).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF00D4FF).withOpacity(0.3)),
                            ),
                            child: Text(
                              spec.toString(),
                              style: const TextStyle(
                                color: Color(0xFF00D4FF),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ).toList(),
                      ),
                    ],
                  ),
                
                const SizedBox(height: 24),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          String phoneNumber = lawyer['phone'] ?? '';
                          if (phoneNumber.isNotEmpty) {
                            _makePhoneCall(phoneNumber);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Phone number not available'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.phone),
                        label: const Text('Call'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4ECDC4),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _bookConsultation(lawyer);
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: const Text('Book'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00D4FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  void _bookConsultation(Map<String, dynamic> lawyer) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Booking consultation with ${_extractLawyerName(lawyer['name'] ?? '')}...'),
        backgroundColor: const Color(0xFF4ECDC4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildMapView() {
    if (_currentPosition == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF00D4FF)),
            SizedBox(height: 16),
            Text(
              'Getting your location...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    return FlutterMap(
      options: MapOptions(
        center: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        zoom: 12.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.law_app',
        ),
        MarkerLayer(
          markers: [
            // Current location marker
            Marker(
              point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              width: 30,
              height: 30,
              child: const Icon(
                Icons.my_location,
                color: Colors.blue,
                size: 30,
              ),
            ),
            // Lawyer markers
            ..._filteredLawyers.map((lawyer) => Marker(
              point: LatLng(
                lawyer['latitude']?.toDouble() ?? 28.6139, 
                lawyer['longitude']?.toDouble() ?? 77.2090
              ),
              width: 50,
              height: 50,
              child: GestureDetector(
                onTap: () {
                  String cleanName = _extractLawyerName(lawyer['name'] ?? '');
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF1A1D3A),
                      title: Text(cleanName, style: const TextStyle(color: Colors.white)),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(lawyer['expertise'] ?? 'General Practice', style: const TextStyle(color: Colors.white70)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              Text(' ${lawyer['rating'] ?? 0.0}', style: const TextStyle(color: Colors.white70)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(lawyer['fee'] ?? '₹1000/hr', style: const TextStyle(color: Color(0xFF00D4FF))),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close', style: TextStyle(color: Color(0xFF00D4FF))),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Map<String, dynamic> lawyerWithCleanData = Map.from(lawyer);
                            lawyerWithCleanData['clean_name'] = cleanName;
                            lawyerWithCleanData['address'] = _extractAddress(lawyer['name'] ?? '');
                            _showLawyerProfile(lawyerWithCleanData);
                          },
                          child: const Text('View Profile', style: TextStyle(color: Color(0xFF4ECDC4))),
                        ),
                      ],
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ECDC4),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            )),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D3A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D3A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Find Lawyer',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showMap ? Icons.list : Icons.map,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showMap = !_showMap;
              });
            },
          ),
          if (_currentPosition != null)
            IconButton(
              icon: const Icon(Icons.my_location, color: Color(0xFF00D4FF)),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Finding lawyers near you...'),
                    backgroundColor: Color(0xFF4ECDC4),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              // Search Bar
              Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search lawyers by name, expertise, or city...',
                    hintStyle: const TextStyle(color: Colors.white60),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF00D4FF)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white60),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                  ),
                ),
              ),

              // Filter Chips
              _buildFilterChips(),
              const SizedBox(height: 16),

              // Results Count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      '${_filteredLawyers.length} lawyers found',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    if (_isSearching)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D4FF)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Content Area
              Expanded(
                child: _showMap
                    ? _buildMapView()
                    : _filteredLawyers.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  color: Colors.white30,
                                  size: 64,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No lawyers found',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Try adjusting your filters or search terms',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredLawyers.length,
                            itemBuilder: (context, index) {
                              return _buildLawyerCard(_filteredLawyers[index]);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



