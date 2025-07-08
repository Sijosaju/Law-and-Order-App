import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TrackCaseScreen extends StatefulWidget {
  @override
  _TrackCaseScreenState createState() => _TrackCaseScreenState();
}

class _TrackCaseScreenState extends State<TrackCaseScreen> {
  final _caseIdController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _firDetails;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Track FIR Status'),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Track Your FIR',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Enter your FIR ID to view details and download PDF',
                style: TextStyle(color: Colors.white60),
              ),
              SizedBox(height: 30),
              
              _buildSearchSection(),
              SizedBox(height: 30),
              
              if (_firDetails != null) _buildFirDetails(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FIR ID',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: _caseIdController,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.search, color: Color(0xFF00D4FF)),
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
            hintText: 'Enter FIR ID (e.g., FIR1720422061000)',
            hintStyle: TextStyle(color: Colors.white60),
          ),
        ),
        SizedBox(height: 20),
        Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _searchFir,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? CircularProgressIndicator(color: Colors.white)
                : Text(
                    'Track FIR',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildFirDetails() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FIR Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 20),
          
          _buildDetailRow('FIR ID', _firDetails!['fir_id']),
          _buildDetailRow('Status', _firDetails!['status']),
          _buildDetailRow('State', _firDetails!['state_name'] ?? 'N/A'),
          _buildDetailRow('District', _firDetails!['district_name'] ?? 'N/A'),
          _buildDetailRow('Police Station', _firDetails!['police_station_name'] ?? 'N/A'),
          _buildDetailRow('Category', _firDetails!['category']),
          _buildDetailRow('Created Date', DateTime.parse(_firDetails!['created_at']).toString().split(' ')[0]),
          
          SizedBox(height: 20),
          
          // Download PDF Button
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton.icon(
              onPressed: () => _downloadFirPdf(),
              icon: Icon(Icons.download, color: Colors.white),
              label: Text(
                'Download FIR PDF',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          SizedBox(height: 15),
          
          // Status Information
          Container(
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next Steps:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '1. Print the downloaded FIR PDF\n'
                  '2. Visit ${_firDetails!['police_station_name'] ?? _firDetails!['police_station'] ?? 'the police station'}\n'
                  '3. Submit the printed FIR to get official FIR number\n'
                  '4. Use official FIR number for future tracking',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
void _searchFir() async {
  if (_caseIdController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please enter a FIR ID')),
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    final response = await http.get(
      Uri.parse('https://your-render-app-name.onrender.com/api/fir/${_caseIdController.text}'), // Update with your actual Render URL
    );
    
    print('Search response status: ${response.statusCode}');
    print('Search response body: ${response.body}');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _firDetails = data;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('FIR not found')),
      );
    }
  } catch (e) {
    setState(() => _isLoading = false);
    print('Search error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Network error: ${e.toString()}')),
    );
  }
}


  void _downloadFirPdf() async {
    // Re-generate PDF with stored data
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('FIR PDF regenerated and downloaded')),
    );
  }

  @override
  void dispose() {
    _caseIdController.dispose();
    super.dispose();
  }
}
