import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class PoliceStationService {
  // ────────────────────────────────────────────────
  // 1. 10 nearest RAILWAY stations around user
  // ────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getRailwayStationsNearUser({
    required double lat,
    required double lng,
    int radiusMetres = 10000,   // 10 km
  }) async {
    final query = '''
      [out:json][timeout:25];
      (
        node["railway"="station"](around:$radiusMetres,$lat,$lng);
        way ["railway"="station"](around:$radiusMetres,$lat,$lng);
        rel ["railway"="station"](around:$radiusMetres,$lat,$lng);
      );
      out center 15;
    ''';

    return _runOverpassQuery(query, limit: 10);
  }

  // ────────────────────────────────────────────────
  // 2. 15 police stations around a district centre
  // ────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getPoliceStationsForDistrict({
    required double lat,
    required double lng,
    int radiusMetres = 15000,   // 15 km
  }) async {
    final query = '''
      [out:json][timeout:25];
      (
        node["amenity"="police"](around:$radiusMetres,$lat,$lng);
        way ["amenity"="police"](around:$radiusMetres,$lat,$lng);
        rel ["amenity"="police"](around:$radiusMetres,$lat,$lng);
      );
      out center 20;
    ''';

    return _runOverpassQuery(query, limit: 15);
  }

  // ────────────────────────────────────────────────
  // shared helper
  // ────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> _runOverpassQuery(
    String query, {int limit = 15}) async {
    const String overpassUrl = 'https://overpass-api.de/api/interpreter';
    final resp = await http.post(Uri.parse(overpassUrl),
        headers: {'Content-Type': 'text/plain'}, body: query);

    if (resp.statusCode != 200) return [];

    final List elements = json.decode(resp.body)['elements'] ?? [];
    return elements.take(limit).map<Map<String, dynamic>>((e) {
      final tags = e['tags'] ?? {};
      final lat = e['lat'] ?? e['center']?['lat'];
      final lon = e['lon'] ?? e['center']?['lon'];
      return {
        'code' : 'PS_${e['id']}',
        'name' : tags['name'] ?? 'Unnamed station',
        'latitude' : lat,
        'longitude': lon,
        'address' : '${tags['addr:street'] ?? ''} ${tags['addr:city'] ?? ''}'.trim()
      };
    }).toList();
  }
}
