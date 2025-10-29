import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/ride.dart';
import '../models/school_contract.dart';
import '../services/location_service.dart';

class RiderMapScreen extends StatefulWidget {
  final Ride ride;
  
  const RiderMapScreen({super.key, required this.ride});

  @override
  State<RiderMapScreen> createState() => _RiderMapScreenState();
}

class _RiderMapScreenState extends State<RiderMapScreen> {
  bool _isLoading = true;
  double _distance = 0.0;
  double _duration = 0.0;
  List<Location> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _loadRouteData();
  }

  Future<void> _loadRouteData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Calculate driving distance and duration
      final distanceData = await LocationService.calculateDrivingDistance(
        widget.ride.origin,
        widget.ride.destination,
      );

      // Get route directions
      final routePoints = await LocationService.getDirections(
        widget.ride.origin,
        widget.ride.destination,
      );

      setState(() {
        _distance = distanceData['distance'] as double;
        _duration = distanceData['duration'] as double;
        _routePoints = routePoints;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading route: $e')),
        );
      }
    }
  }

  Future<void> _openInMaps() async {
    try {
      // Create a Google Maps URL with the route
      final originLat = widget.ride.origin.lat;
      final originLng = widget.ride.origin.lng;
      final destLat = widget.ride.destination.lat;
      final destLng = widget.ride.destination.lng;
      
      // Try to open in Google Maps
      final googleMapsUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&origin=$originLat,$originLng&destination=$destLat,$destLng&travelmode=driving',
      );
      
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch maps');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open maps: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Route'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Route summary card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.green[600]),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'From',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      widget.ride.origin.address,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.red[600]),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'To',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      widget.ride.destination.address,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Route details
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildRouteDetail(
                            Icons.straighten,
                            'Distance',
                            '${_distance.toStringAsFixed(1)} km',
                          ),
                          const Divider(),
                          _buildRouteDetail(
                            Icons.access_time,
                            'Duration',
                            '${_duration.toStringAsFixed(0)} minutes',
                          ),
                          if (widget.ride.fare != null) ...[
                            const Divider(),
                            _buildRouteDetail(
                              Icons.attach_money,
                              'Fare',
                              'ETB ${widget.ride.fare!.toStringAsFixed(2)}',
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Open in maps button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _openInMaps,
                      icon: const Icon(Icons.map),
                      label: const Text(
                        'Open in Maps',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildRouteDetail(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue[600]),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(fontSize: 16),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}