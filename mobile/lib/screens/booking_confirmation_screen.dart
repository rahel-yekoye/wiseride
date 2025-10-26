import 'package:flutter/material.dart';
import '../models/ride.dart';
import '../models/school_contract.dart' as models;
import '../services/ride_service.dart';
import '../services/location_service.dart';
import 'rider_ride_tracking_screen.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final Ride ride;
  final models.Location origin;
  final models.Location destination;

  const BookingConfirmationScreen({
    super.key,
    required this.ride,
    required this.origin,
    required this.destination,
  });

  @override
  State<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  final RideService _rideService = RideService();
  bool _isBooking = false;
  bool _isCalculating = true;
  double _calculatedFare = 0.0;
  double _calculatedDistance = 0.0;
  int _estimatedDuration = 0;
  String? _selectedPaymentMethod;

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'telebirr',
      'name': 'Telebirr',
      'icon': '📱',
      'color': Colors.orange,
    },
    {
      'id': 'm_pesa',
      'name': 'M-Pesa',
      'icon': '💳',
      'color': Colors.green,
    },
    {
      'id': 'cbe_birr',
      'name': 'CBE Birr',
      'icon': '🏦',
      'color': Colors.blue,
    },
    {
      'id': 'amole',
      'name': 'Amole',
      'icon': '💰',
      'color': Colors.purple,
    },
    {
      'id': 'hello_cash',
      'name': 'HelloCash',
      'icon': '💸',
      'color': Colors.teal,
    },
    {
      'id': 'cash',
      'name': 'Cash',
      'icon': '💵',
      'color': Colors.green.shade700,
    },
  ];

  @override
  void initState() {
    super.initState();
    _calculateRealTimeFare();
  }

  Future<void> _calculateRealTimeFare() async {
    try {
      setState(() {
        _isCalculating = true;
      });

      // Calculate real-time distance and fare
      final distanceData = await LocationService.calculateDrivingDistance(
        widget.origin,
        widget.destination,
      );

      final dynamicFare = await LocationService.calculateDynamicFare(
        widget.origin,
        widget.destination,
        widget.ride.vehicleType ?? 'bus',
      );

      setState(() {
        _calculatedDistance = distanceData['distance'] as double;
        _estimatedDuration = (distanceData['duration'] as double).round();
        _calculatedFare = dynamicFare;
        _isCalculating = false;
      });
    } catch (e) {
      setState(() {
        _isCalculating = false;
        _calculatedDistance = _calculateDistance();
        _calculatedFare = widget.ride.fare ?? 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue[600]!,
              Colors.blue[400]!,
              Colors.blue[300]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Confirm Booking',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _getVehicleTypeLabel(widget.ride.vehicleType),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Main content
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Route summary
                        _buildRouteSummary(),
                        const SizedBox(height: 24),
                        // Fare breakdown
                        _buildFareBreakdown(),
                        const SizedBox(height: 24),
                        // Payment method selection
                        _buildPaymentMethodSelection(),
                        const SizedBox(height: 24),
                        // Terms and conditions
                        _buildTermsAndConditions(),
                        const SizedBox(height: 32),
                        // Book button
                        _buildBookButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteSummary() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getVehicleIcon(widget.ride.vehicleType),
                    color: Colors.blue[600],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getVehicleTypeLabel(widget.ride.vehicleType),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        _getVehicleDescription(widget.ride.vehicleType),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.location_on, size: 20, color: Colors.green[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.origin.address,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.only(left: 10),
              width: 2,
              height: 30,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.flag, size: 20, color: Colors.red[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.destination.address,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFareBreakdown() {
    final distance = _isCalculating ? _calculateDistance() : _calculatedDistance;
    final baseFare = _getBaseFare(widget.ride.vehicleType);
    final perKmRate = _getPerKmRate(widget.ride.vehicleType);
    final distanceFare = distance * perKmRate;
    final totalFare = _isCalculating ? (baseFare + distanceFare) : _calculatedFare;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.blue, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Fare Breakdown',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (_isCalculating) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            
            if (_isCalculating)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Calculating real-time fare...'),
                ),
              )
            else ...[
              _buildFareRow(Icons.flag, 'Base fare', baseFare),
              _buildFareRow(Icons.straighten, 'Distance (${distance.toStringAsFixed(1)} km)', distanceFare),
              const Divider(height: 24),
              _buildFareRow(Icons.payments, 'Total', totalFare, isTotal: true),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFareRow(IconData icon, String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: isTotal ? Colors.green : Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                fontSize: isTotal ? 16 : 14,
                color: isTotal ? Colors.grey[800] : Colors.grey[700],
              ),
            ),
          ),
          Text(
            'ETB ${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              fontSize: isTotal ? 18 : 14,
              color: isTotal ? Colors.green[600] : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.payment, color: Colors.blue, size: 24),
            SizedBox(width: 12),
            Text(
              'Select Payment Method',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _paymentMethods.map((method) {
              final isSelected = _selectedPaymentMethod == method['id'];
              return GestureDetector(
                onTap: () => setState(() => _selectedPaymentMethod = method['id']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue[600] : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        method['icon'],
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        method['name'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.grey[800],
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.check_circle, color: Colors.white, size: 18),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTermsAndConditions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: Colors.grey),
              SizedBox(width: 8),
              Text(
                'Terms & Conditions',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '• Payment will be processed after ride completion\n'
            '• Cancellation is free up to 5 minutes before pickup\n'
            '• Driver details will be provided after booking\n'
            '• Please be ready at the pickup location',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildBookButton() {
    final canBook = _selectedPaymentMethod != null && !_isCalculating;
    
    return Column(
      children: [
        if (_selectedPaymentMethod == null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Please select a payment method',
                    style: TextStyle(color: Colors.orange[800], fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        if (_selectedPaymentMethod == null) const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _isBooking || !canBook ? null : _bookRide,
            icon: _isBooking
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.check_circle),
            label: Text(
              _isBooking ? 'Booking...' : 'Book This Ride',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: canBook ? Colors.blue[600] : Colors.grey[400],
              foregroundColor: Colors.white,
              elevation: canBook ? 4 : 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _bookRide() async {
    // First check if payment method is selected
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show payment confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You will be charged using ${_getSelectedPaymentMethodName()}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payments, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Text(
                    'ETB ${(_calculatedFare > 0 ? _calculatedFare : widget.ride.fare ?? 0).toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Payment will be processed after ride completion',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => _isBooking = true);

      // Create a new ride booking with calculated fare
      final newRide = Ride(
        type: 'public',
        origin: widget.origin,
        destination: widget.destination,
        vehicleType: widget.ride.vehicleType,
        fare: _calculatedFare > 0 ? _calculatedFare : widget.ride.fare,
      );

      final bookedRide = await _rideService.createRide(newRide);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ride booked successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Navigate to tracking screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RiderRideTrackingScreen(ride: bookedRide),
          ),
        );
      }
    } catch (e) {
      setState(() => _isBooking = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to book ride: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getSelectedPaymentMethodName() {
    final method = _paymentMethods.firstWhere(
      (m) => m['id'] == _selectedPaymentMethod,
      orElse: () => {'name': 'Unknown'},
    );
    return method['name'] as String;
  }

  double _calculateDistance() {
    return LocationService.calculateDistance(widget.origin, widget.destination);
  }

  int _calculateEstimatedTime() {
    final distance = _calculateDistance();
    return (distance * 2).round(); // Rough estimate: 2 minutes per km
  }

  IconData _getVehicleIcon(String? vehicleType) {
    switch (vehicleType) {
      case 'bus':
        return Icons.directions_bus;
      case 'taxi':
        return Icons.local_taxi;
      case 'minibus':
        return Icons.airport_shuttle;
      case 'private_car':
        return Icons.directions_car;
      default:
        return Icons.directions_bus;
    }
  }

  String _getVehicleTypeLabel(String? vehicleType) {
    switch (vehicleType) {
      case 'bus':
        return 'Bus';
      case 'taxi':
        return 'Taxi';
      case 'minibus':
        return 'Minibus';
      case 'private_car':
        return 'Private Car';
      default:
        return 'Vehicle';
    }
  }

  String _getVehicleDescription(String? vehicleType) {
    switch (vehicleType) {
      case 'bus':
        return 'Public bus service';
      case 'taxi':
        return 'Taxi service';
      case 'minibus':
        return 'Minibus service';
      case 'private_car':
        return 'Private car service';
      default:
        return 'Transportation service';
    }
  }

  double _getBaseFare(String? vehicleType) {
    switch (vehicleType) {
      case 'bus':
        return 2.50;
      case 'taxi':
        return 5.00;
      case 'minibus':
        return 4.00;
      case 'private_car':
        return 6.00;
      default:
        return 5.00;
    }
  }

  double _getPerKmRate(String? vehicleType) {
    switch (vehicleType) {
      case 'bus':
        return 0.50;
      case 'taxi':
        return 1.20;
      case 'minibus':
        return 0.80;
      case 'private_car':
        return 1.50;
      default:
        return 1.00;
    }
  }
}
