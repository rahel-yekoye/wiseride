import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/socket_service.dart';
import 'available_rides_screen.dart';
import 'driver_earnings_screen.dart';
import 'driver_profile_screen.dart';
import 'promo_code_screen.dart';
import 'ride_history_screen.dart';
import 'emergency_contacts_screen.dart';
import 'route_search_screen.dart';
import '../widgets/sos_button.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  bool _isOnline = false;
  bool _hasEmergencyContacts = true;
  final _socketService = SocketService();

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _initializeSocket();
  }

  @override
  void dispose() {
    _socketService.disconnect();
    super.dispose();
  }

  void _initializeSocket() {
    // Connect to Socket.io
    _socketService.connect();

    // Listen for new ride requests
    _socketService.onNewRideRequest = (data) {
      if (mounted) {
        _showRideRequestNotification(data);
      }
    };

    // Listen for ride cancellations
    _socketService.onRideCancelled = (data) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ride cancelled: ${data['reason'] ?? 'Unknown reason'}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    };
  }

  void _showRideRequestNotification(Map<String, dynamic> rideData) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (context) => AlertDialog(
        title: const Text('🚗 New Ride Request!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('From: ${rideData['origin']['address']}'),
            const SizedBox(height: 8),
            Text('To: ${rideData['destination']['address']}'),
            const SizedBox(height: 8),
            Text('Type: ${rideData['vehicleType']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Dismiss'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AvailableRidesScreen(),
                ),
              );
            },
            child: const Text('View Rides'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadDashboardData() async {
    try {
      final apiService = ApiService();
      final data = await apiService.get('/driver/dashboard');
      final me = await apiService.get('/users/me');
      setState(() {
        _dashboardData = data;
        _isOnline = data['driver']['isOnline'] ?? false;
        _hasEmergencyContacts = (me['emergencyContacts'] as List?)?.isNotEmpty == true;
        _isLoading = false;
      });
      // Start/stop location tracking based on status
      final location = LocationService();
      if (_isOnline) {
        await location.startTracking();
      } else {
        await location.stopTracking();
      }
    } catch (e) {
      // Fallback to mock data if backend is not available
      setState(() {
        _dashboardData = {
          'driver': {
            'name': 'John Driver',
            'rating': {'average': 4.8, 'count': 150},
            'isOnline': false,
            'earnings': {'total': 2500, 'today': 120, 'thisWeek': 800, 'thisMonth': 2500}
          },
          'todayRides': 5,
          'todayEarnings': 120,
          'recentRides': []
        };
        _isOnline = false;
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Using offline mode: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _toggleOnlineStatus() async {
    try {
      final apiService = ApiService();
      final response = await apiService.put('/driver/toggle-online');
      final newStatus = response['isOnline'] == true;
      setState(() {
        _isOnline = newStatus;
      });

      final location = LocationService();
      if (newStatus) {
        await location.startTracking();
        // Emit online status to server
        _socketService.emitDriverStatusUpdate(true);
      } else {
        await location.stopTracking();
        // Emit offline status to server
        _socketService.emitDriverStatusUpdate(false);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isOnline ? 'You are now online ✅' : 'You are now offline'),
            backgroundColor: _isOnline ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      // Fallback to local toggle if API fails
      final newStatus = !_isOnline;
      setState(() {
        _isOnline = newStatus;
      });

      final location = LocationService();
      if (newStatus) {
        await location.startTracking();
      } else {
        await location.stopTracking();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Offline mode: ${_isOnline ? 'Online' : 'Offline'}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DriverProfileScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authService = Provider.of<AuthService>(context, listen: false);
              await authService.logout();
            },
          ),
        ],
      ),
      floatingActionButton: const SOSButton(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Online Status Card
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Welcome, ${_dashboardData?['driver']['name'] ?? 'Driver'}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _isOnline ? 'Online - Ready for rides' : 'Offline',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _isOnline ? Colors.green : Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                Switch(
                                  value: _isOnline,
                                  onChanged: (value) => _toggleOnlineStatus(),
                                  activeColor: Colors.green,
                                ),
                              ],
                            ),
                            if (_dashboardData?['driver']['rating'] != null) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 20),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_dashboardData!['driver']['rating']['average']?.toStringAsFixed(1) ?? '0.0'} (${_dashboardData!['driver']['rating']['count'] ?? 0} reviews)',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (!_hasEmergencyContacts) ...[
                      Card(
                        color: Colors.red.shade50,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.red.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.contact_phone, color: Colors.red),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Add emergency contacts', style: TextStyle(fontWeight: FontWeight.bold)),
                                    SizedBox(height: 4),
                                    Text('We will notify them when you trigger SOS.', style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const EmergencyContactsScreen()),
                                  );
                                  if (result == true) {
                                    await _loadDashboardData();
                                  }
                                },
                                child: const Text('Add'),
                              )
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Today's Summary
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Today's Summary",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    'Rides',
                                    '${_dashboardData?['todayRides'] ?? 0}',
                                    Icons.directions_car,
                                    Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildStatCard(
                                    'Earnings',
                                    'ETB ${_dashboardData?['todayEarnings']?.toStringAsFixed(0) ?? '0'}',
                                    Icons.account_balance_wallet,
                                    Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quick Actions
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Row 1: Available Rides & Earnings
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            context,
                            icon: Icons.map,
                            title: 'Search Route',
                            subtitle: 'Find nearby drivers',
                            color: Colors.blue,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RouteSearchScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionCard(
                            context,
                            icon: Icons.account_balance_wallet,
                            title: 'Earnings',
                            subtitle: 'View your earnings',
                            color: Colors.green,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const DriverEarningsScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Row 2: Promo Codes & Ride History (NEW)
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            context,
                            icon: Icons.local_offer,
                            title: 'Promo Codes',
                            subtitle: 'View & share codes',
                            color: Colors.purple,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PromoCodeScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionCard(
                            context,
                            icon: Icons.contact_phone,
                            title: 'Emergency Contacts',
                            subtitle: 'Add up to 3 contacts',
                            color: Colors.red,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const EmergencyContactsScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Row 3: Ride History
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            context,
                            icon: Icons.history,
                            title: 'Ride History',
                            subtitle: 'View past rides',
                            color: Colors.orange,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RideHistoryScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(child: SizedBox.shrink()),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Recent Rides
                    if (_dashboardData?['recentRides'] != null && 
                        (_dashboardData!['recentRides'] as List).isNotEmpty) ...[
                      const Text(
                        'Recent Rides',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...((_dashboardData!['recentRides'] as List).take(3).map((ride) => 
                        Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            title: Text(ride['riderId']['name'] ?? 'Unknown'),
                            subtitle: Text('${ride['origin']['address']} → ${ride['destination']['address']}'),
                            trailing: Chip(
                              label: Text(ride['status']),
                              backgroundColor: _getStatusColor(ride['status']),
                            ),
                          ),
                        ),
                      ).toList()),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'accepted':
        return Colors.orange;
      case 'requested':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
