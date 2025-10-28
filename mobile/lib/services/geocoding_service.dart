import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingService {
  static const String _nominatimBase = 'https://nominatim.openstreetmap.org';

  Future<List<Map<String, dynamic>>> autocomplete(String query, {int limit = 5}) async {
    if (query.trim().isEmpty) return [];
    final uri = Uri.parse('$_nominatimBase/search').replace(queryParameters: {
      'q': query,
      'format': 'json',
      'addressdetails': '1',
      'limit': '$limit',
    });
    final res = await http.get(uri, headers: { 'User-Agent': 'WiseRide/1.0 (autocomplete)' });
    if (res.statusCode != 200) return [];
    final List data = json.decode(res.body);
    return data.map<Map<String, dynamic>>((e) => {
      'displayName': e['display_name'],
      'lat': double.tryParse(e['lat']?.toString() ?? ''),
      'lng': double.tryParse(e['lon']?.toString() ?? ''),
    }).where((m) => m['lat'] != null && m['lng'] != null).toList();
  }
}


