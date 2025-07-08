import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class FileFirScreen extends StatefulWidget {
  @override
  _FileFirScreenState createState() => _FileFirScreenState();
}

class _FileFirScreenState extends State<FileFirScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Backend URL - Update with your actual Render deployment URL
  final String backendUrl = 'https://law-and-order-app.onrender.com';
  
  // Personal Details Controllers
  final _nameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _occupationController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  
  // Incident Details Controllers
  final _incidentLocationController = TextEditingController();
  final _incidentDescriptionController = TextEditingController();
  final _propertyDetailsController = TextEditingController();
  final _accusedDetailsController = TextEditingController();
  
  // Dynamic lists for location data
  List<Map<String, dynamic>> _states = [];
  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _policeStations = [];
  
  String? _selectedState;
  String? _selectedDistrict;
  String? _selectedPoliceStation;
  String _selectedCategory = 'Theft';
  
  bool _loadingDistricts = false;
  bool _loadingStations = false;
  bool _useCurrentLocation = false;
  bool _loadingLocation = false;
  
  DateTime _incidentDate = DateTime.now();
  TimeOfDay _incidentTime = TimeOfDay.now();
  
  final List<String> _categories = [
    'Theft', 'Fraud', 'Assault', 'Cybercrime', 'Domestic Violence', 
    'Chain Snatching', 'Mobile Theft', 'Vehicle Theft', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadStates();
  }

  Future<void> _loadStates() async {
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/api/locations/states'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _states = data.cast<Map<String, dynamic>>();
        });
      } else {
        throw Exception('Failed to load states: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading states: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load states. Please check your internet connection.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadDistricts(String stateCode) async {
    setState(() {
      _loadingDistricts = true;
      _districts.clear();
      _policeStations.clear();
      _selectedDistrict = null;
      _selectedPoliceStation = null;
    });

    try {
      final response = await http.get(
        Uri.parse('$backendUrl/api/locations/districts/$stateCode'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _districts = data.cast<Map<String, dynamic>>();
          _loadingDistricts = false;
        });
      } else {
        throw Exception('Failed to load districts: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _loadingDistricts = false);
      print('Error loading districts: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load districts'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadPoliceStationsForDistrict(String districtCode) async {
    setState(() {
      _loadingStations = true;
      _policeStations.clear();
      _selectedPoliceStation = null;
    });

    try {
      final response = await http.get(
        Uri.parse('$backendUrl/api/locations/police-stations/$districtCode'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _policeStations = data.cast<Map<String, dynamic>>();
          _loadingStations = false;
        });
      } else {
        throw Exception('Failed to load police stations: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _loadingStations = false);
      print('Error loading police stations: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load police stations'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadNearbyPoliceStations() async {
    setState(() {
      _loadingLocation = true;
      _loadingStations = true;
      _policeStations.clear();
      _selectedPoliceStation = null;
    });

    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      setState(() {
        _loadingLocation = false;
      });

      // Call backend API for nearby stations
      final response = await http.post(
        Uri.parse('$backendUrl/api/locations/police-stations-nearby'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'radius': 20
        }),
      ).timeout(Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _policeStations = data.cast<Map<String, dynamic>>();
          _loadingStations = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Found ${_policeStations.length} nearby police stations'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to load nearby stations: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _loadingLocation = false;
        _loadingStations = false;
        _useCurrentLocation = false;
      });

      String errorMessage = 'Could not get nearby police stations';
      if (e.toString().contains('permission')) {
        errorMessage = 'Location permission is required to find nearby police stations';
      } else if (e.toString().contains('LocationServiceDisabledException')) {
        errorMessage = 'Please enable location services and try again';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('File FIR - Official Format'),
        backgroundColor: Color(0xFF1A1D3A),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.2,
            colors: [Color(0xFF1A1D3A), Color(0xFF0A0E27)],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'First Information Report',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Under Section 154 Cr.P.C.',
                  style: TextStyle(color: Colors.white60, fontSize: 14),
                ),
                SizedBox(height: 30),
                
                // Location Details Section
                _buildSectionHeader('Location Details'),
                _buildStateDropdown(),
                SizedBox(height: 15),
                _buildDistrictDropdown(),
                SizedBox(height: 15),
                
                // Current Location Toggle - Placed after district selection
                if (_selectedDistrict != null) ...[
                  _buildCurrentLocationToggle(),
                  SizedBox(height: 15),
                ],
                
                _buildPoliceStationDropdown(),
                SizedBox(height: 25),
                
                // Personal Details Section
                _buildSectionHeader('Complainant Details'),
                _buildInputField('Full Name', _nameController, Icons.person),
                SizedBox(height: 15),
                _buildInputField('Father\'s/Husband\'s Name', _fatherNameController, Icons.person_outline),
                SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(child: _buildInputField('Age', _ageController, Icons.calendar_today)),
                    SizedBox(width: 15),
                    Expanded(child: _buildInputField('Occupation', _occupationController, Icons.work)),
                  ],
                ),
                SizedBox(height: 15),
                _buildInputField('Address', _addressController, Icons.location_on, maxLines: 3),
                SizedBox(height: 15),
                _buildInputField('Phone Number', _phoneController, Icons.phone),
                SizedBox(height: 25),
                
                // Incident Details Section
                _buildSectionHeader('Incident Details'),
                _buildDropdownField('Category of Offence', _selectedCategory, _categories, (value) {
                  setState(() => _selectedCategory = value!);
                }),
                SizedBox(height: 15),
                _buildDateTimeFields(),
                SizedBox(height: 15),
                _buildInputField('Place of Occurrence', _incidentLocationController, Icons.place),
                SizedBox(height: 15),
                _buildInputField('Brief Description of Incident', _incidentDescriptionController, Icons.description, maxLines: 5),
                SizedBox(height: 15),
                _buildInputField('Property Involved (if any)', _propertyDetailsController, Icons.inventory, maxLines: 2),
                SizedBox(height: 15),
                _buildInputField('Accused Person Details (if known)', _accusedDetailsController, Icons.person_search, maxLines: 3),
                SizedBox(height: 30),
                
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 15),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF00D4FF),
        ),
      ),
    );
  }

  Widget _buildStateDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('State', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedState,
            dropdownColor: Color(0xFF1A1D3A),
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.location_city, color: Color(0xFF00D4FF)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            hint: Text('Select State', style: TextStyle(color: Colors.white60)),
            items: _states.map((state) {
              return DropdownMenuItem<String>(
                value: state['code'],
                child: Text(state['name']),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedState = value;
                _useCurrentLocation = false;
                _policeStations.clear();
                _selectedPoliceStation = null;
              });
              if (value != null) {
                _loadDistricts(value);
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a state';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDistrictDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('District', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _loadingDistricts
              ? Container(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D4FF)),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Loading districts...', style: TextStyle(color: Colors.white60)),
                    ],
                  ),
                )
              : DropdownButtonFormField<String>(
                  value: _selectedDistrict,
                  dropdownColor: Color(0xFF1A1D3A),
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.location_on, color: Color(0xFF00D4FF)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  hint: Text('Select District', style: TextStyle(color: Colors.white60)),
                  items: _districts.map((district) {
                    return DropdownMenuItem<String>(
                      value: district['code'],
                      child: Text(district['name']),
                    );
                  }).toList(),
                  onChanged: _selectedState == null ? null : (value) {
                    setState(() {
                      _selectedDistrict = value;
                      _useCurrentLocation = false;
                      _policeStations.clear();
                      _selectedPoliceStation = null;
                    });
                    if (value != null && !_useCurrentLocation) {
                      _loadPoliceStationsForDistrict(value);
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a district';
                    }
                    return null;
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCurrentLocationToggle() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _useCurrentLocation ? Color(0xFF4ECDC4) : Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.my_location,
            color: _useCurrentLocation ? Color(0xFF4ECDC4) : Colors.white60,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Use Current Location',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _useCurrentLocation 
                    ? 'Finding police stations near your location'
                    : 'Find police stations near your current location',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _useCurrentLocation,
            onChanged: (value) {
              setState(() {
                _useCurrentLocation = value;
                _policeStations.clear();
                _selectedPoliceStation = null;
              });
              
              if (value) {
                _loadNearbyPoliceStations();
              } else if (_selectedDistrict != null) {
                _loadPoliceStationsForDistrict(_selectedDistrict!);
              }
            },
            activeColor: Color(0xFF4ECDC4),
          ),
        ],
      ),
    );
  }

  Widget _buildPoliceStationDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Police Station', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
            if (_policeStations.isNotEmpty)
              Container(
                margin: EdgeInsets.only(left: 8),
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Color(0xFF4ECDC4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_policeStations.length} ${_useCurrentLocation ? "nearby" : "in district"}',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            Spacer(),
            if (_policeStations.isNotEmpty)
              ElevatedButton.icon(
                onPressed: _policeStations.isEmpty ? null : _showPoliceStationMap,
                icon: Icon(Icons.map, size: 16),
                label: Text('View Map'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4ECDC4),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: (_loadingStations || _loadingLocation)
              ? Container(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D4FF)),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        _loadingLocation 
                          ? 'Getting your location...' 
                          : 'Loading police stations...',
                        style: TextStyle(color: Colors.white60),
                      ),
                    ],
                  ),
                )
              : DropdownButtonFormField<String>(
                  value: _selectedPoliceStation,
                  dropdownColor: Color(0xFF1A1D3A),
                  style: TextStyle(color: Colors.white),
                  isExpanded: true, // Fix overflow issue
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.local_police, color: Color(0xFF00D4FF)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  hint: Text(
                    _useCurrentLocation 
                      ? 'Select nearby police station' 
                      : 'Select Police Station',
                    style: TextStyle(color: Colors.white60),
                  ),
                  items: _policeStations.map((station) {
                    return DropdownMenuItem<String>(
                      value: station['code'],
                      child: Container(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              station['name'],
                              style: TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            if (station['distance_km'] != null)
                              Text(
                                '${station['distance_km']} km away',
                                style: TextStyle(fontSize: 12, color: Color(0xFF4ECDC4)),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            if (station['address'] != null && station['address'].toString().isNotEmpty)
                              Text(
                                station['address'].toString(),
                                style: TextStyle(fontSize: 11, color: Colors.white60),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (_selectedDistrict == null && !_useCurrentLocation) ? null : (value) {
                    setState(() => _selectedPoliceStation = value);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a police station';
                    }
                    return null;
                  },
                ),
        ),
      ],
    );
  }
  /// Mini-map showing all loaded police stations
Widget _buildStationMap() {
  if (_policeStations.isEmpty) return const SizedBox.shrink();

  final first = _policeStations.first;

  // 1️⃣  use `child:` instead of `builder:`
  final markers = _policeStations.map((s) => Marker(
        point: LatLng(s['latitude'], s['longitude']),
        width: 40,
        height: 40,
        child: const Icon(Icons.local_police,      // ← here
            size: 30, color: Color(0xFF4ECDC4)),
      )).toList();

  // 2️⃣  centre/zoom fields were renamed in v6
  return FlutterMap(
    options: MapOptions(
      initialCenter: LatLng(first['latitude'], first['longitude']),
      initialZoom: 11,
    ),
    children: [
       TileLayer(
        urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
        subdomains: ['a', 'b', 'c'],
        userAgentPackageName: 'com.example.law_app',
      ),
      MarkerLayer(markers: markers),   // 3️⃣  markers already a List<Marker>
    ],
  );
}



void _showPoliceStationMap() {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1A1D3A),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      builder: (context, scrollController) => SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text(
                    'Police Stations',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (_useCurrentLocation)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4ECDC4).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.my_location,
                              size: 14, color: Color(0xFF4ECDC4)),
                          SizedBox(width: 4),
                          Text('Near You',
                              style: TextStyle(
                                  color: Color(0xFF4ECDC4), fontSize: 12)),
                        ],
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // ── Mini-map ─────────────────────────────────────────
            SizedBox(height: 200, child: _buildStationMap()),
            const SizedBox(height: 8),
            // ── Scrollable list ─────────────────────────────────
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _policeStations.length,
                itemBuilder: (context, index) {
                  final station = _policeStations[index];
                  return Card(
                    color: Colors.white.withOpacity(0.1),
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: const Icon(Icons.local_police,
                          color: Color(0xFF4ECDC4)),
                      title: Text(
                        station['name'],
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (station['distance_km'] != null)
                            Text('${station['distance_km']} km away',
                                style: const TextStyle(
                                    color: Color(0xFF00D4FF),
                                    fontWeight: FontWeight.w500)),
                          if (station['address'] != null &&
                              station['address'].toString().isNotEmpty)
                            Text(station['address'],
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white60)),
                          if (station['district'] != null)
                            Text('District: ${station['district']}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.white60)),
                        ],
                      ),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4ECDC4),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() => _selectedPoliceStation =
                              station['code']);
                        },
                        child: const Text('Select'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}


  Widget _buildInputField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Color(0xFF00D4FF)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF00D4FF)),
            ),
            hintText: 'Enter $label',
            hintStyle: TextStyle(color: Colors.white60),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter $label';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            dropdownColor: Color(0xFF1A1D3A),
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.category, color: Color(0xFF00D4FF)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: items.map((item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeFields() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _incidentDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) setState(() => _incidentDate = date);
            },
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Color(0xFF00D4FF)),
                  SizedBox(width: 12),
                  Text(
                    'Date: ${_incidentDate.day}/${_incidentDate.month}/${_incidentDate.year}',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 15),
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _incidentTime,
              );
              if (time != null) setState(() => _incidentTime = time);
            },
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, color: Color(0xFF00D4FF)),
                  SizedBox(width: 12),
                  Text(
                    'Time: ${_incidentTime.format(context)}',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00D4FF), Color(0xFF5B73FF)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        onPressed: _generateOfficialFIR,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Generate Official FIR',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _generateOfficialFIR() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Validation checks
        if (!_useCurrentLocation && (_selectedState == null || _selectedDistrict == null || _selectedPoliceStation == null)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please select all location fields')),
          );
          return;
        }

        if (_useCurrentLocation && _selectedPoliceStation == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please select a nearby police station')),
          );
          return;
        }

        // Find selected names with null safety
        String stateName, districtName, stationName;
        
        if (_useCurrentLocation) {
          // For location-based selection
          final selectedStation = _policeStations.firstWhere(
            (p) => p['code'] == _selectedPoliceStation,
            orElse: () => {'name': 'Unknown Police Station', 'district': 'Unknown', 'state': 'Unknown'}
          );
          stateName = selectedStation['state'] ?? 'Unknown State';
          districtName = selectedStation['district'] ?? 'Unknown District';
          stationName = selectedStation['name'];
        } else {
          // For district-based selection
          stateName = _states.firstWhere(
            (s) => s['code'] == _selectedState,
            orElse: () => {'name': 'Unknown State'}
          )['name'];
          
          districtName = _districts.firstWhere(
            (d) => d['code'] == _selectedDistrict,
            orElse: () => {'name': 'Unknown District'}
          )['name'];
          
          stationName = _policeStations.firstWhere(
            (p) => p['code'] == _selectedPoliceStation,
            orElse: () => {'name': 'Unknown Police Station'}
          )['name'];
        }
        
        // Generate unique FIR ID
        String firId = 'FIR${DateTime.now().millisecondsSinceEpoch}';
        
        print('Generated FIR ID: $firId'); // Debug log
        
        // Create FIR data
        Map<String, dynamic> firData = {
          'fir_id': firId,
          'state_code': _selectedState ?? 'LOCATION_BASED',
          'state_name': stateName,
          'district_code': _selectedDistrict ?? 'LOCATION_BASED',
          'district_name': districtName,
          'police_station_code': _selectedPoliceStation,
          'police_station_name': stationName,
          'location_based': _useCurrentLocation,
          'complainant_name': _nameController.text,
          'father_name': _fatherNameController.text,
          'age': _ageController.text,
          'occupation': _occupationController.text,
          'address': _addressController.text,
          'phone': _phoneController.text,
          'category': _selectedCategory,
          'incident_date': _incidentDate.toIso8601String(),
          'incident_time': _incidentTime.format(context),
          'incident_location': _incidentLocationController.text,
          'description': _incidentDescriptionController.text,
          'property_details': _propertyDetailsController.text,
          'accused_details': _accusedDetailsController.text,
          'created_at': DateTime.now().toIso8601String(),
          'status': 'PDF Generated',
        };
        
        print('FIR Data: ${json.encode(firData)}'); // Debug log
        
        // Save to backend FIRST
        await _saveFIRToBackend(firData);
        
        // Generate PDF
        await _generatePDF(firData);
        
        // Show success dialog
        _showSuccessDialog(firId);
        
      } catch (e) {
        print('Error in FIR generation: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating FIR: $e')),
        );
      }
    }
  }

  Future<void> _saveFIRToBackend(Map<String, dynamic> firData) async {
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/fir'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(firData),
      ).timeout(Duration(seconds: 30));
      
      print('Save response status: ${response.statusCode}');
      print('Save response body: ${response.body}');
      
      if (response.statusCode == 200) {
        print('FIR saved to backend successfully');
      } else {
        print('Failed to save FIR: ${response.statusCode}');
      }
    } catch (e) {
      print('Error saving FIR: $e');
    }
  }

  Future<void> _generatePDF(Map<String, dynamic> firData) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Header
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'FIRST INFORMATION REPORT',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '(Under Section 154 Cr.P.C.)',
                    style: pw.TextStyle(fontSize: 12),
                  ),
                  pw.SizedBox(height: 20),
                ],
              ),
            ),
            
            // FIR Details Table
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                _buildPdfRow('State', firData['state_name']),
                _buildPdfRow('District', firData['district_name']),
                _buildPdfRow('Police Station', firData['police_station_name']),
                _buildPdfRow('FIR No.', '_____________ (To be filled by Police)'),
                _buildPdfRow('Date', DateTime.parse(firData['created_at']).toString().split(' ')[0]),
                _buildPdfRow('Time', firData['incident_time']),
              ],
            ),
            
            pw.SizedBox(height: 20),
            
            // Complainant Details
            pw.Text(
              'COMPLAINANT DETAILS',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                _buildPdfRow('Name', firData['complainant_name']),
                _buildPdfRow('Father\'s/Husband\'s Name', firData['father_name']),
                _buildPdfRow('Age', firData['age']),
                _buildPdfRow('Occupation', firData['occupation']),
                _buildPdfRow('Address', firData['address']),
                _buildPdfRow('Phone Number', firData['phone']),
              ],
            ),
            
            pw.SizedBox(height: 20),
            
            // Incident Details
            pw.Text(
              'INCIDENT DETAILS',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                _buildPdfRow('Category of Offence', firData['category']),
                _buildPdfRow('Date of Occurrence', DateTime.parse(firData['incident_date']).toString().split(' ')[0]),
                _buildPdfRow('Time of Occurrence', firData['incident_time']),
                _buildPdfRow('Place of Occurrence', firData['incident_location']),
              ],
            ),
            
            pw.SizedBox(height: 15),
            
            // Description
            pw.Container(
              width: double.infinity,
              padding: pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(border: pw.Border.all()),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Brief Description of Incident:', 
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 5),
                  pw.Text(firData['description']),
                ],
              ),
            ),
            
            pw.SizedBox(height: 15),
            
            // Property Details
            if (firData['property_details'].toString().isNotEmpty)
              pw.Container(
                width: double.infinity,
                padding: pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(border: pw.Border.all()),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Property Involved:', 
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    pw.Text(firData['property_details']),
                  ],
                ),
              ),
            
            pw.SizedBox(height: 15),
            
            // Accused Details
            if (firData['accused_details'].toString().isNotEmpty)
              pw.Container(
                width: double.infinity,
                padding: pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(border: pw.Border.all()),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Details of Accused Person(s):', 
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    pw.Text(firData['accused_details']),
                  ],
                ),
              ),
            
            pw.SizedBox(height: 30),
            
            // Signature Section
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Signature of Complainant'),
                    pw.SizedBox(height: 30),
                    pw.Text('_____________________'),
                    pw.Text('Date: _______________'),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Signature of Officer'),
                    pw.SizedBox(height: 30),
                    pw.Text('_____________________'),
                    pw.Text('Rank: _______________'),
                  ],
                ),
              ],
            ),
            
            pw.SizedBox(height: 20),
            
            // Footer
            pw.Center(
              child: pw.Text(
                'Generated by ${firData['fir_id']} - Law App',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
            ),
          ];
        },
      ),
    );
    
    // Save and share PDF
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'FIR_${firData['fir_id']}.pdf',
    );
  }

  pw.TableRow _buildPdfRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: pw.EdgeInsets.all(8),
          child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ),
        pw.Container(
          padding: pw.EdgeInsets.all(8),
          child: pw.Text(value),
        ),
      ],
    );
  }

  void _showSuccessDialog(String firId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1D3A),
        title: Text('FIR Generated Successfully', style: TextStyle(color: Colors.white)),
        content: Text(
          'Your FIR has been generated successfully.\n\nFIR ID: $firId\n\nPlease download the PDF and submit it to the police station.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Only close the dialog - fixes white screen issue
            },
            child: Text('OK', style: TextStyle(color: Color(0xFF00D4FF))),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fatherNameController.dispose();
    _ageController.dispose();
    _occupationController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _incidentLocationController.dispose();
    _incidentDescriptionController.dispose();
    _propertyDetailsController.dispose();
    _accusedDetailsController.dispose();
    super.dispose();
  }
}


