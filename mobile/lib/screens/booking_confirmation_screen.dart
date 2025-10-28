import 'package:flutter/material.dart';
import '../services/api_service.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final Map<String, double> origin;
  final Map<String, double> destination;
  final String originLabel;
  final String destLabel;
  const BookingConfirmationScreen({super.key, required this.origin, required this.destination, required this.originLabel, required this.destLabel});

  @override
  State<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  bool _submitting = false;
  String _vehicleType = 'taxi';

  Future<void> _confirmBooking() async {
    setState(() => _submitting = true);
    try {
      final api = ApiService();
      final body = {
        'type': 'public',
        'vehicleType': _vehicleType,
        'origin': {
          'lat': widget.origin['lat'],
          'lng': widget.origin['lng'],
          'address': widget.originLabel,
          'coordinates': { 'type': 'Point', 'coordinates': [widget.origin['lng'], widget.origin['lat']] }
        },
        'destination': {
          'lat': widget.destination['lat'],
          'lng': widget.destination['lng'],
          'address': widget.destLabel,
          'coordinates': { 'type': 'Point', 'coordinates': [widget.destination['lng'], widget.destination['lat']] }
        }
      };
      final res = await api.post('/rides', body: body);
      if (!mounted) return;
      Navigator.pop(context, res);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Booking'), backgroundColor: Colors.blue, foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.my_location),
              title: Text(widget.originLabel),
            ),
            ListTile(
              leading: const Icon(Icons.place),
              title: Text(widget.destLabel),
            ),
            const SizedBox(height: 12),
            const Text('Vehicle Type'),
            Wrap(
              spacing: 8,
              children: ['bus','minibus','taxi','private_car'].map((v) => ChoiceChip(
                label: Text(v),
                selected: _vehicleType == v,
                onSelected: (_) => setState(() => _vehicleType = v),
              )).toList(),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _submitting ? null : _confirmBooking,
              icon: _submitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check),
              label: const Text('Confirm & Request Ride'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            )
          ],
        ),
      ),
    );
  }
}


