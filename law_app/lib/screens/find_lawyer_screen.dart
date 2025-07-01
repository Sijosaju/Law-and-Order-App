import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FindLawyerScreen extends StatefulWidget {
  const FindLawyerScreen({Key? key}) : super(key: key);

  @override
  _FindLawyerScreenState createState() => _FindLawyerScreenState();
}

class _FindLawyerScreenState extends State<FindLawyerScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  TextEditingController _searchController = TextEditingController();
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
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
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
      // Replace with your actual backend URL
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
          SnackBar(
            content: Text('Failed to load lawyers. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Error loading lawyers: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
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
        bool matchesSearch = _searchController.text.isEmpty ||
            (lawyer['name']?.toLowerCase()?.contains(_searchController.text.toLowerCase()) ?? false) ||
            (lawyer['expertise']?.toLowerCase()?.contains(_searchController.text.toLowerCase()) ?? false) ||
            (lawyer['city']?.toLowerCase()?.contains(_searchController.text.toLowerCase()) ?? false);

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
    return Container(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20),
        children: [
          _buildFilterChip('Expertise', _selectedExpertise, _expertiseAreas, (value) {
            setState(() {
              _selectedExpertise = value;
            });
            _applyFilters();
          }),
          SizedBox(width: 12),
          _buildFilterChip('City', _selectedCity, _cities, (value) {
            setState(() {
              _selectedCity = value;
            });
            _applyFilters();
          }),
          SizedBox(width: 12),
          _buildRatingFilter(),
          SizedBox(width: 12),
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
          backgroundColor: Color(0xFF1A1D3A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select $label',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 16),
                ...options.map((option) => ListTile(
                  title: Text(
                    option,
                    style: TextStyle(color: Colors.white),
                  ),
                  leading: Radio<String>(
                    value: option,
                    groupValue: selected,
                    onChanged: (value) {
                      onSelected(value!);
                      Navigator.pop(context);
                    },
                    activeColor: Color(0xFF00D4FF),
                  ),
                )).toList(),
              ],
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00D4FF).withOpacity(0.2), Color(0xFF5B73FF).withOpacity(0.2)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Color(0xFF00D4FF).withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: $selected',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
            SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
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
            backgroundColor: Color(0xFF1A1D3A),
            title: Text('Minimum Rating', style: TextStyle(color: Colors.white)),
            content: StatefulBuilder(
              builder: (context, setDialogState) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Slider(
                    value: _minRating,
                    min: 0.0,
                    max: 5.0,
                    divisions: 10,
                    activeColor: Color(0xFF00D4FF),
                    onChanged: (value) {
                      setDialogState(() {
                        _minRating = value;
                      });
                    },
                  ),
                  Text(
                    '${_minRating.toStringAsFixed(1)} stars and above',
                    style: TextStyle(color: Colors.white),
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
                child: Text('Apply', style: TextStyle(color: Color(0xFF00D4FF))),
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00D4FF).withOpacity(0.2), Color(0xFF5B73FF).withOpacity(0.2)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Color(0xFF00D4FF).withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, color: Colors.amber, size: 16),
            SizedBox(width: 4),
            Text(
              '${_minRating.toStringAsFixed(1)}+',
              style: TextStyle(color: Colors.white, fontSize: 12),
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
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _verifiedOnly 
              ? [Color(0xFF4ECDC4), Color(0xFF44A08D)]
              : [Color(0xFF00D4FF).withOpacity(0.2), Color(0xFF5B73FF).withOpacity(0.2)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Color(0xFF00D4FF).withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.verified,
              color: _verifiedOnly ? Colors.white : Color(0xFF00D4FF),
              size: 16,
            ),
            SizedBox(width: 4),
            Text(
              'Verified',
              style: TextStyle(
                color: _verifiedOnly ? Colors.white : Color(0xFF00D4FF),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLawyerCard(Map<String, dynamic> lawyer) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
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
                        child: Icon(Icons.person, color: Colors.white, size: 30),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lawyer['name'] ?? 'Unknown Lawyer',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Show verified badge
                          if (lawyer['verified'] == true)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
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
                          // Show senior advocate badge
                          if (lawyer['senior_advocate'] == true)
                            Container(
                              margin: EdgeInsets.only(left: 8),
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
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
                      SizedBox(height: 4),
                      Text(
                        lawyer['expertise'] ?? 'General Practice',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${lawyer['experience'] ?? 0} years experience • ${lawyer['court'] ?? 'Supreme Court of India'}',
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
            SizedBox(height: 12),
            Text(
              lawyer['description'] ?? 'Experienced legal practitioner',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.white.withOpacity(0.7), size: 16),
                SizedBox(width: 4),
                Text(
                  lawyer['city'] ?? 'Unknown',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                SizedBox(width: 16),
                Icon(Icons.star, color: Colors.amber, size: 16),
                SizedBox(width: 4),
                Text(
                  '${lawyer['rating'] ?? 0.0} (${lawyer['reviews'] ?? 0} reviews)',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                Spacer(),
                Text(
                  lawyer['fee'] ?? '₹1000/hr',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _showLawyerProfile(lawyer);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Color(0xFF44A08D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('View Profile'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _bookConsultation(lawyer);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF00D4FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Book Now'),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF1A1D3A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: EdgeInsets.all(20),
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
                SizedBox(height: 20),
                // Profile header with photo and basic info
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Color(0xFF00D4FF), width: 3),
                      ),
                      child: ClipOval(
                        child: Image.network(
                          lawyer['photoUrl'] ?? 'https://via.placeholder.com/150',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.white.withOpacity(0.2),
                            child: Icon(Icons.person, color: Colors.white, size: 40),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  lawyer['name'] ?? 'Unknown Lawyer',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (lawyer['verified'] == true)
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
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
                              margin: EdgeInsets.only(top: 4),
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Senior Advocate',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          SizedBox(height: 8),
                          Text(
                            lawyer['expertise'] ?? 'General Practice',
                            style: TextStyle(
                              color: Color(0xFF00D4FF),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 18),
                              SizedBox(width: 4),
                              Text(
                                '${lawyer['rating'] ?? 0.0} (${lawyer['reviews'] ?? 0} reviews)',
                                style: TextStyle(
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
                SizedBox(height: 24),
                
                // Profile sections
                _buildProfileSection('About', lawyer['description'] ?? 'Experienced legal practitioner'),
                SizedBox(height: 16),
                _buildProfileSection('Experience', '${lawyer['experience'] ?? 0} years of legal practice'),
                SizedBox(height: 16),
                _buildProfileSection('Court', lawyer['court'] ?? 'Supreme Court of India'),
                SizedBox(height: 16),
                _buildProfileSection('Location', '${lawyer['city'] ?? 'Unknown'}, ${lawyer['state'] ?? 'India'}'),
                SizedBox(height: 16),
                _buildProfileSection('Enrollment Number', lawyer['enrollment_number'] ?? 'Not available'),
                SizedBox(height: 16),
                if (lawyer['registration_date'] != null)
                  _buildProfileSection('Registration Date', lawyer['registration_date']),
                SizedBox(height: 16),
                _buildProfileSection('Consultation Fee', lawyer['fee'] ?? '₹1000/hr'),
                
                // Specializations
                if (lawyer['specializations'] != null && lawyer['specializations'].isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 16),
                      Text(
                        'Specializations',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (lawyer['specializations'] as List).map((spec) => 
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Color(0xFF00D4FF).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Color(0xFF00D4FF).withOpacity(0.3)),
                            ),
                            child: Text(
                              spec.toString(),
                              style: TextStyle(
                                color: Color(0xFF00D4FF),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ).toList(),
                      ),
                    ],
                  ),
                
                SizedBox(height: 24),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Call functionality
                        },
                        icon: Icon(Icons.phone),
                        label: Text('Call'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF4ECDC4),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _bookConsultation(lawyer);
                        },
                        icon: Icon(Icons.calendar_today),
                        label: Text('Book'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF00D4FF),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
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
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
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
        content: Text('Booking consultation with ${lawyer['name']}...'),
        backgroundColor: Color(0xFF4ECDC4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildMapView() {
    if (_currentPosition == null) {
      return Center(
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
              child: Icon(
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
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: Color(0xFF1A1D3A),
                      title: Text(lawyer['name'] ?? 'Unknown Lawyer', style: TextStyle(color: Colors.white)),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(lawyer['expertise'] ?? 'General Practice', style: TextStyle(color: Colors.white70)),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 16),
                              Text(' ${lawyer['rating'] ?? 0.0}', style: TextStyle(color: Colors.white70)),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(lawyer['fee'] ?? '₹1000/hr', style: TextStyle(color: Color(0xFF00D4FF))),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Close', style: TextStyle(color: Color(0xFF00D4FF))),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showLawyerProfile(lawyer);
                          },
                          child: Text('View Profile', style: TextStyle(color: Color(0xFF4ECDC4))),
                        ),
                      ],
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF4ECDC4),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            )).toList(),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A1D3A),
      appBar: AppBar(
        backgroundColor: Color(0xFF1A1D3A),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
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
              icon: Icon(Icons.my_location, color: Color(0xFF00D4FF)),
              onPressed: () {
                // Find nearby lawyers
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
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
                margin: EdgeInsets.all(20),
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
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search lawyers by name, expertise, or city...',
                    hintStyle: TextStyle(color: Colors.white60),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    prefixIcon: Icon(Icons.search, color: Color(0xFF00D4FF)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.white60),
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
              SizedBox(height: 16),

              // Results Count
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      '${_filteredLawyers.length} lawyers found',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Spacer(),
                    if (_isSearching)
                      SizedBox(
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
              SizedBox(height: 16),

              // Content Area
              Expanded(
                child: _showMap
                    ? _buildMapView()
                    : _filteredLawyers.isEmpty
                        ? Center(
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


