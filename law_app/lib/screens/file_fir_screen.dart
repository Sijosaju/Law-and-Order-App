import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FileFirScreen extends StatefulWidget {
  @override
  _FileFirScreenState createState() => _FileFirScreenState();
}

class _FileFirScreenState extends State<FileFirScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Backend URL - Update with your actual Render deployment URL
  final String backendUrl = 'https://your-render-app-name.onrender.com';
  
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

  Future<void> _loadPoliceStations(String districtCode) async {
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
              setState(() => _selectedState = value);
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
                    setState(() => _selectedDistrict = value);
                    if (value != null) {
                      _loadPoliceStations(value);
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
                  '${_policeStations.length} nearby',
                  style: TextStyle(color: Colors.white, fontSize: 10),
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
          child: _loadingStations
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
                      Text('Finding nearby police stations...', style: TextStyle(color: Colors.white60)),
                    ],
                  ),
                )
              : DropdownButtonFormField<String>(
                  value: _selectedPoliceStation,
                  dropdownColor: Color(0xFF1A1D3A),
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.local_police, color: Color(0xFF00D4FF)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  hint: Text('Select Police Station', style: TextStyle(color: Colors.white60)),
                  items: _policeStations.map((station) {
                    return DropdownMenuItem<String>(
                      value: station['code'],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            station['name'],
                            style: TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (station['distance_km'] != null)
                            Text(
                              '${station['distance_km']} km away',
                              style: TextStyle(fontSize: 12, color: Colors.white60),
                            ),
                          if (station['address'] != null && station['address'].toString().isNotEmpty)
                            Text(
                              station['address'].toString(),
                              style: TextStyle(fontSize: 11, color: Colors.white60),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: _selectedDistrict == null ? null : (value) {
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
        
        // Add map view button if stations are loaded
        if (_policeStations.isNotEmpty)
          Container(
            margin: EdgeInsets.only(top: 12),
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showPoliceStationMap(),
              icon: Icon(Icons.map, size: 16),
              label: Text('View on Map'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4ECDC4),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showPoliceStationMap() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF1A1D3A),
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Nearby Police Stations',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _policeStations.length,
                itemBuilder: (context, index) {
                  final station = _policeStations[index];
                  return Card(
                    color: Colors.white.withOpacity(0.1),
                    margin: EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(Icons.local_police, color: Color(0xFF4ECDC4)),
                      title: Text(
                        station['name'],
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (station['distance_km'] != null)
                            Text(
                              '${station['distance_km']} km away',
                              style: TextStyle(color: Color(0xFF00D4FF)),
                            ),
                          if (station['address'] != null && station['address'].toString().isNotEmpty)
                            Text(
                              station['address'].toString(),
                              style: TextStyle(color: Colors.white60),
                            ),
                        ],
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            _selectedPoliceStation = station['code'];
                          });
                        },
                        child: Text('Select'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF4ECDC4),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
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
        // Add null checks
        if (_selectedState == null || _selectedDistrict == null || _selectedPoliceStation == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please select all location fields')),
          );
          return;
        }

        // Find selected names with null safety
        String stateName = _states.firstWhere(
          (s) => s['code'] == _selectedState,
          orElse: () => {'name': 'Unknown State'}
        )['name'];
        
        String districtName = _districts.firstWhere(
          (d) => d['code'] == _selectedDistrict,
          orElse: () => {'name': 'Unknown District'}
        )['name'];
        
        String stationName = _policeStations.firstWhere(
          (p) => p['code'] == _selectedPoliceStation,
          orElse: () => {'name': 'Unknown Police Station'}
        )['name'];
        
        // Generate unique FIR ID
        String firId = 'FIR${DateTime.now().millisecondsSinceEpoch}';
        
        print('Generated FIR ID: $firId'); // Debug log
        
        // Create FIR data
        Map<String, dynamic> firData = {
          'fir_id': firId,
          'state_code': _selectedState,
          'state_name': stateName,
          'district_code': _selectedDistrict,
          'district_name': districtName,
          'police_station_code': _selectedPoliceStation,
          'police_station_name': stationName,
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

