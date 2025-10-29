import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/geocoding_service.dart';
import 'booking_confirmation_screen.dart';
import '../models/ride.dart';
import '../models/school_contract.dart' show Location;

class RouteSearchScreen extends StatefulWidget {
  const RouteSearchScreen({super.key});

  @override
  State<RouteSearchScreen> createState() => _RouteSearchScreenState();
}

class _RouteSearchScreenState extends State<RouteSearchScreen> {
  final _originCtrl = TextEditingController();
  final _destCtrl = TextEditingController();
  final _geo = GeocodingService();
  List<Map<String, dynamic>> _originSuggestions = [];
  List<Map<String, dynamic>> _destSuggestions = [];
  Map<String, double>? _origin;
  Map<String, double>? _dest;
  List<dynamic> _nearbyDrivers = [];
  bool _loadingDrivers = false;

  Future<void> _onOriginChanged(String q) async {
    final results = await _geo.autocomplete(q);
    if (mounted) setState(() => _originSuggestions = results);
  }

  Future<void> _onDestChanged(String q) async {
    final results = await _geo.autocomplete(q);
    if (mounted) setState(() => _destSuggestions = results);
  }

  Future<void> _searchDrivers() async {
    if (_origin == null || _dest == null) return;
    setState(() => _loadingDrivers = true);
    try {
      final api = ApiService();
      final res = await api.get('/rides/search/nearby?lat=${_origin!['lat']}&lng=${_origin!['lng']}&radiusKm=5');
      setState(() => _nearbyDrivers = (res['drivers'] as List?) ?? []);
    } finally {
      if (mounted) setState(() => _loadingDrivers = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Route'), backgroundColor: Colors.blue, foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _originCtrl,
              decoration: const InputDecoration(labelText: 'Origin', prefixIcon: Icon(Icons.my_location)),
              onChanged: _onOriginChanged,
            ),
            if (_originSuggestions.isNotEmpty)
              _buildSuggestionList(_originSuggestions, (s) {
                _originCtrl.text = s['displayName'];
                _origin = {'lat': s['lat'], 'lng': s['lng']};
                setState(() => _originSuggestions = []);
              }),
            const SizedBox(height: 12),
            TextField(
              controller: _destCtrl,
              decoration: const InputDecoration(labelText: 'Destination', prefixIcon: Icon(Icons.place)),
              onChanged: _onDestChanged,
            ),
            if (_destSuggestions.isNotEmpty)
              _buildSuggestionList(_destSuggestions, (s) {
                _destCtrl.text = s['displayName'];
                _dest = {'lat': s['lat'], 'lng': s['lng']};
                setState(() => _destSuggestions = []);
              }),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: (_origin != null && _dest != null) ? _searchDrivers : null,
              icon: const Icon(Icons.search),
              label: const Text('Find Nearby Drivers'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: (_origin != null && _dest != null)
                  ? () async {
                      // Create Location objects from the coordinates
                      final originLocation = Location(
                        lat: _origin!['lat']?.toDouble() ?? 0.0,
                        lng: _origin!['lng']?.toDouble() ?? 0.0,
                        address: _originCtrl.text,
                      );
                      
                      final destLocation = Location(
                        lat: _dest!['lat']?.toDouble() ?? 0.0,
                        lng: _dest!['lng']?.toDouble() ?? 0.0,
                        address: _destCtrl.text,
                      );
                      
                      // Create a new Ride object with the selected locations
                      final ride = Ride(
                        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
                        type: 'standard',
                        riderId: '',
                        driverId: '',
                        origin: originLocation,
                        destination: destLocation,
                        status: 'requested',
                        vehicleType: 'standard',
                        route: null,
                        createdAt: DateTime.now(),
                      );
                      
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookingConfirmationScreen(
                            ride: ride,
                            origin: originLocation,
                            destination: destLocation,
                          ),
                        ),
                      );
                      if (result != null && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ride requested successfully'), backgroundColor: Colors.green),
                        );
                      }
                    }
                  : null,
              icon: const Icon(Icons.directions_car),
              label: const Text('Request Ride'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            ),
            const SizedBox(height: 12),
            if (_loadingDrivers) const LinearProgressIndicator(),
            Expanded(
              child: ListView.builder(
                itemCount: _nearbyDrivers.length,
                itemBuilder: (_, i) {
                  final d = _nearbyDrivers[i];
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(d['name'] ?? 'Driver'),
                    subtitle: Text('Vehicle: ${d['vehicleInfo']?['vehicleType'] ?? '-'}  •  ${d['distanceKm'] ?? '?'} km away'),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionList(List<Map<String, dynamic>> suggestions, void Function(Map<String, dynamic>) onTap) {
    return Card(
      child: ListView(
        shrinkWrap: true,
        children: suggestions.take(5).map((s) => ListTile(
          title: Text(s['displayName']),
          onTap: () => onTap(s),
        )).toList(),
      ),
    );
  }
}


