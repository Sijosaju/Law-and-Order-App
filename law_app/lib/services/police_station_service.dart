import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class PoliceStationService {
  static const String baseUrl = 'https://law-and-order-app.onrender.com';
  
  /// Get 25 nearby police stations using current location
  static Future<List<Map<String, dynamic>>> getNearbyPoliceStations() async {
    try {
      // Always get current location
      Position position = await _getCurrentLocation();
      
      final response = await http.post(
        Uri.parse("$baseUrl/api/locations/police-stations-nearby"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "latitude": position.latitude,
          "longitude": position.longitude,
        }),
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception("Failed to load police stations: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching nearby police stations: $e");
      return [];
    }
  }

  /// Get current location with proper error handling
  static Future<Position> _getCurrentLocation() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    // Check location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    // Get current position
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 15),
    );
  }
}
